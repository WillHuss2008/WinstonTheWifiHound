#!/bin/bash
# Winston The Wifi Hound - Interactive Terminal Interface

# Standard paths
SCRIPTS_DIR="/winston/scripts"
KENEL_DIR="/winston/kenel"
WORDLIST_DIR="$KENEL_DIR/wordlists"
HANDSHAKE_DIR="$KENEL_DIR/handshakes"
LOG_DIR="$KENEL_DIR/logs"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Security settings
MAX_LOGIN_ATTEMPTS=3
SESSION_TIMEOUT=3600  # 1 hour
ENCRYPTION_KEY_FILE="$KENEL_DIR/.encryption_key"
LOG_FILE="$LOG_DIR/winston.log"

# Verbosity levels
VERBOSITY_QUIET=0
VERBOSITY_NORMAL=1
VERBOSITY_VERBOSE=2
VERBOSITY_DEBUG=3
CURRENT_VERBOSITY=$VERBOSITY_NORMAL

# Enable command history with readline
HISTFILE=~/.winston_history
HISTSIZE=1000
HISTFILESIZE=2000
HISTCONTROL=ignoreboth:erasedups
set -o history

# Custom history array and index
declare -a WINSTON_HISTORY
WINSTON_HISTORY_INDEX=0

# Command completion arrays
declare -a WINSTON_COMMANDS=(
    "help" "scan" "interfaces" "monitor" "managed" "capture" "deauth" 
    "handshakes" "crack" "wordlist" "status" "history" "verbose" 
    "clear" "exit" "docs" "stop"
)

# Initialize variables
interface=""
current_network=""
scan_running=false
capture_running=false
deauth_running=false

# Function to create necessary directories
create_directories() {
    local dirs=("$SCRIPTS_DIR" "$KENEL_DIR" "$WORDLIST_DIR" "$HANDSHAKE_DIR" "$LOG_DIR")
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            sudo mkdir -p "$dir" 2>/dev/null || {
                echo -e "${RED}Failed to create directory: $dir${NC}"
                return 1
            }
            sudo chmod 700 "$dir" 2>/dev/null || {
                echo -e "${RED}Failed to set permissions for: $dir${NC}"
                return 1
            }
        fi
    done
    return 0
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    local required_commands=("aircrack-ng" "screen" "iwconfig" "airmon-ng")
    
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Missing required dependencies: ${missing_deps[*]}${NC}"
        return 1
    fi
    return 0
}

# Function to initialize the environment
initialize_environment() {
    # Create directories
    create_directories
    
    # Check dependencies
    if ! check_dependencies; then
        handle_error "Failed to initialize environment"
        return 1
    fi
    
    # Set up history
    if [ ! -f "$HISTFILE" ]; then
        touch "$HISTFILE"
        chmod 600 "$HISTFILE"
    fi
    
    # Set up log file
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
        chmod 600 "$LOG_FILE"
        log_event "INFO" "Log file initialized"
    fi
    
    return 0
}

# Function to get available interfaces
get_interfaces() {
    iwconfig 2>/dev/null | grep -B 1 "Mode:" | awk '{print $1}' | grep -v "^$"
}

# Function to get available networks
get_networks() {
    if [ -f "/winston/kenel/airodump-ng-01.csv" ]; then
        cat "/winston/kenel/airodump-ng-01.csv" | awk -F',' '{print $14}' | grep -v "ESSID" | grep -v "^$"
    fi
}

# Function to get available handshakes
get_handshakes() {
    if [ -f "/winston/kenel/handshakes.txt" ]; then
        cat "/winston/kenel/handshakes.txt" | awk -F'|' '{print $2}'
    fi
}

# Function to get available wordlists
get_wordlists() {
    ls /winston/kenel/wordlists/*.txt 2>/dev/null | xargs -n1 basename
}

# Function to handle command completion
_winston_complete() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    case "${prev}" in
        help|docs)
            COMPREPLY=( $(compgen -W "${WINSTON_COMMANDS[*]}" -- ${cur}) )
            return 0
            ;;
        scan)
            COMPREPLY=( $(compgen -W "all $(get_networks)" -- ${cur}) )
            return 0
            ;;
        monitor|managed)
            COMPREPLY=( $(compgen -W "$(get_interfaces)" -- ${cur}) )
            return 0
            ;;
        capture|deauth)
            COMPREPLY=( $(compgen -W "$(get_networks)" -- ${cur}) )
            return 0
            ;;
        crack)
            COMPREPLY=( $(compgen -W "$(get_handshakes)" -- ${cur}) )
            return 0
            ;;
        wordlist)
            COMPREPLY=( $(compgen -W "$(get_wordlists)" -- ${cur}) )
            return 0
            ;;
        verbose)
            COMPREPLY=( $(compgen -W "0 1 2 3" -- ${cur}) )
            return 0
            ;;
        *)
            COMPREPLY=( $(compgen -W "${WINSTON_COMMANDS[*]}" -- ${cur}) )
            return 0
            ;;
    esac
}

# Function to handle command history navigation
setup_history_navigation() {
    # Check if readline is available
    if [ -t 1 ]; then
        # Enable readline if we're in an interactive shell
        if [ -z "$BASH" ]; then
            # If not in bash, try to use readline
            if command -v rlwrap >/dev/null 2>&1; then
                exec rlwrap -a -c -f ~/.winston_completion "$0" "$@"
            fi
        else
            # In bash, enable readline features
            if [[ $- == *i* ]]; then
                # Only set these if we're in an interactive shell
                bind 'set show-all-if-ambiguous on'
                bind 'set completion-ignore-case on'
                bind 'set history-expand-line off'
                bind 'set colored-completion-prefix on'
                bind 'set colored-stats on'
                bind 'set menu-complete-display-prefix on'
                
                # Enable tab completion
                complete -F _winston_complete winston
                
                # Disable history expansion
                set +H
                
                # Set up the prompt
                PS1="winston> "
                
                # Load history from file
                if [ -f "$HISTFILE" ]; then
                    while IFS= read -r line; do
                        WINSTON_HISTORY+=("$line")
                    done < "$HISTFILE"
                    WINSTON_HISTORY_INDEX=${#WINSTON_HISTORY[@]}
                fi
            fi
        fi
    fi
}

# Function to add command to history
add_to_history() {
    local cmd="$1"
    if [ ! -z "$cmd" ]; then
        WINSTON_HISTORY+=("$cmd")
        WINSTON_HISTORY_INDEX=${#WINSTON_HISTORY[@]}
        # Save to history file
        echo "$cmd" >> "$HISTFILE" 2>/dev/null || {
            echo -e "${RED}Failed to write to history file${NC}"
        }
    fi
}

# Function to handle up arrow
handle_up_arrow() {
    if [ $WINSTON_HISTORY_INDEX -gt 0 ]; then
        WINSTON_HISTORY_INDEX=$((WINSTON_HISTORY_INDEX - 1))
        echo -ne "\r\033[K${BOLD}winston> ${NC}${WINSTON_HISTORY[$WINSTON_HISTORY_INDEX]}"
    fi
}

# Function to handle down arrow
handle_down_arrow() {
    if [ $WINSTON_HISTORY_INDEX -lt ${#WINSTON_HISTORY[@]} ]; then
        WINSTON_HISTORY_INDEX=$((WINSTON_HISTORY_INDEX + 1))
        if [ $WINSTON_HISTORY_INDEX -eq ${#WINSTON_HISTORY[@]} ]; then
            echo -ne "\r\033[K${BOLD}winston> ${NC}"
        else
            echo -ne "\r\033[K${BOLD}winston> ${NC}${WINSTON_HISTORY[$WINSTON_HISTORY_INDEX]}"
        fi
    fi
}

# Function to log events
log_event() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        chmod 700 "$LOG_DIR"
    fi
    
    # Ensure log file exists
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
        chmod 600 "$LOG_FILE"
    fi
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Function to print messages with appropriate verbosity
winston_say() {
    local level=$1
    local message=$2
    local color=$3
    
    if [ $CURRENT_VERBOSITY -ge $level ]; then
        if [ -z "$color" ]; then
            echo -e "WINSTON: $message"
        else
            echo -e "${color}WINSTON: $message${NC}"
        fi
        log_event "INFO" "$message"
    fi
}

# Function to handle errors
handle_error() {
    local error_msg="$1"
    local exit_code="${2:-1}"
    winston_say $VERBOSITY_NORMAL "ERROR: $error_msg" $RED
    log_event "ERROR" "$error_msg"
    return $exit_code
}

# Function to cleanup and exit
cleanup_and_exit() {
    winston_say $VERBOSITY_NORMAL "CLEANING UP..." $YELLOW
    
    # Kill any running aircrack processes
    pid=$(pstree -p 2>/dev/null | grep airodump-ng | grep -v capture | grep -v deauth | grep -oe '[0-9]\+')
    if [ ! -z "$pid" ]; then
        sudo kill -9 $pid &>/dev/null
        winston_say $VERBOSITY_DEBUG "Killed process $pid" $CYAN
    fi
    
    # Kill any screen sessions
    if screen -ls 2>/dev/null | grep -q "capture"; then
        screen -X -S capture quit 2>/dev/null
        winston_say $VERBOSITY_DEBUG "Closed capture screen" $CYAN
    fi
    if screen -ls 2>/dev/null | grep -q "deauth"; then
        screen -X -S deauth quit 2>/dev/null
        winston_say $VERBOSITY_DEBUG "Closed deauth screen" $CYAN
    fi
    
    # Clear sensitive data
    if [ -f "$ENCRYPTION_KEY_FILE" ]; then
        shred -u "$ENCRYPTION_KEY_FILE" 2>/dev/null
    fi
    
    winston_say $VERBOSITY_NORMAL "GOODBYE!" $GREEN
    log_event "INFO" "Session ended"
    exit 0
}

# Function to check if user is authorized
check_authorization() {
    local username="$1"
    local password="$2"
    local attempts=0
    
    while [ $attempts -lt $MAX_LOGIN_ATTEMPTS ]; do
        if ! ls /winston/$username &>/dev/null; then
            winston_say $VERBOSITY_NORMAL "I'M SORRY, THIS USER DOESN'T EXIST ON THIS DEVICE." $RED
            log_event "WARNING" "Failed login attempt for non-existent user: $username"
            return 1
        elif ls /winston/$username &>/dev/null; then
            if [[ $(echo -n "$password" | sha256sum | awk {'print $1'}) = $(cat /winston/$username/user.profile | awk '/password/ {print $2}') ]]; then
                log_event "INFO" "Successful login for user: $username"
                return 0
            fi
        fi
        attempts=$((attempts + 1))
        if [ $attempts -lt $MAX_LOGIN_ATTEMPTS ]; then
            winston_say $VERBOSITY_NORMAL "INVALID CREDENTIALS. ATTEMPTS REMAINING: $((MAX_LOGIN_ATTEMPTS - attempts))" $RED
            log_event "WARNING" "Failed login attempt for user: $username"
        fi
    done
    
    winston_say $VERBOSITY_NORMAL "TOO MANY FAILED ATTEMPTS. PLEASE TRY AGAIN LATER." $RED
    log_event "WARNING" "Account locked for user: $username"
    return 1
}

# Function to check session timeout
check_session_timeout() {
    if [ -f "/tmp/winston_session_start" ]; then
        local session_start=$(cat "/tmp/winston_session_start")
        local current_time=$(date +%s)
        local elapsed=$((current_time - session_start))
        
        if [ $elapsed -gt $SESSION_TIMEOUT ]; then
            winston_say $VERBOSITY_NORMAL "SESSION TIMEOUT. PLEASE LOGIN AGAIN." $YELLOW
            log_event "WARNING" "Session timeout for user: $username"
            cleanup_and_exit
        fi
    fi
}

# Function to handle network scanning
scan_networks() {
    local interface="$1"
    local mode="$2"
    local target_network="$3"
    
    # Check if interface is in monitor mode
    if ! iwconfig "$interface" 2>/dev/null | grep -q "Mode:Monitor"; then
        handle_error "Interface $interface is not in monitor mode. Use 'monitor $interface' first."
        return 1
    fi
    
    # Create output directory if it doesn't exist
    mkdir -p "$KENEL_DIR"
    
    if [ "$mode" = "specific" ]; then
        winston_say $VERBOSITY_NORMAL "SCANNING FOR SPECIFIC NETWORK: $target_network" $BLUE
        log_event "INFO" "Starting scan for specific network: $target_network"
        
        # Start airodump-ng in a screen session for better control
        screen -dmS scan sudo airodump-ng "$interface" --essid "$target_network" -w "$KENEL_DIR/airodump-ng" --write-interval 1 --output-format csv
        
        # Show real-time updates
        echo -e "\n${BOLD}Scanning for $target_network...${NC}"
        echo "Press Ctrl+C to stop scanning"
        echo "------------------------"
        
        # Monitor the output file for updates
        tail -f "$KENEL_DIR/airodump-ng-01.csv" 2>/dev/null | while read -r line; do
            if [[ $line == *"$target_network"* ]]; then
                echo -e "${GREEN}Found network: $line${NC}"
            fi
        done
    else
        winston_say $VERBOSITY_NORMAL "SCANNING ALL NETWORKS IN RANGE" $BLUE
        log_event "INFO" "Starting scan for all networks"
        
        # Start airodump-ng in a screen session
        screen -dmS scan sudo airodump-ng "$interface" -w "$KENEL_DIR/airodump-ng" --write-interval 1 --output-format csv
        
        # Show real-time updates
        echo -e "\n${BOLD}Scanning for networks...${NC}"
        echo "Press Ctrl+C to stop scanning"
        echo "------------------------"
        echo -e "${BOLD}SSID${NC} | ${BOLD}BSSID${NC} | ${BOLD}Channel${NC} | ${BOLD}Signal${NC} | ${BOLD}Encryption${NC}"
        echo "------------------------"
        
        # Monitor the output file for updates
        tail -f "$KENEL_DIR/airodump-ng-01.csv" 2>/dev/null | while read -r line; do
            if [[ $line == *"Station MAC"* ]]; then
                continue
            fi
            if [[ $line == *","* ]]; then
                IFS=',' read -r bssid first_time last_time channel speed privacy cipher authentication power beacons iv lan ip length ssid <<< "$line"
                if [ ! -z "$ssid" ] && [ ! -z "$bssid" ]; then
                    echo -e "${GREEN}$ssid${NC} | $bssid | $channel | $power dBm | $privacy"
                fi
            fi
        done
    fi
}

# Function to stop scanning
stop_scan() {
    if screen -ls | grep -q "scan"; then
        screen -X -S scan quit
        winston_say $VERBOSITY_NORMAL "SCAN STOPPED" $YELLOW
        log_event "INFO" "Scan stopped by user"
    fi
}

# Function to handle password cracking
crack_password() {
    local handshake_file="$1"
    local wordlist="/winston/kenel/wordlist.txt"
    
    if [ -f "$handshake_file" ]; then
        winston_say $VERBOSITY_NORMAL "ATTEMPTING TO CRACK PASSWORD" $MAGENTA
        aircrack-ng -w "$wordlist" "$handshake_file"
    else
        winston_say $VERBOSITY_NORMAL "NO HANDSHAKE FILE FOUND" $RED
    fi
}

# Function to handle interfaces
list_interfaces() {
    winston_say $VERBOSITY_NORMAL "SCANNING FOR WIRELESS INTERFACES..." $BLUE
    echo -e "\n${BOLD}Available Wireless Interfaces${NC}"
    echo "------------------------"
    echo -e "${BOLD}Interface${NC} | ${BOLD}Status${NC} | ${BOLD}Mode${NC}"
    echo "------------------------"
    
    # Get interface information
    iwconfig 2>/dev/null | while IFS= read -r line; do
        if [[ $line =~ ^[a-zA-Z0-9]+ ]]; then
            interface=$(echo "$line" | awk '{print $1}')
            mode=$(echo "$line" | grep -o "Mode:[^ ]*" | cut -d: -f2)
            status="Active"
            if [ -z "$mode" ]; then
                mode="Managed"
                status="Inactive"
            fi
            echo -e "${GREEN}$interface${NC} | $status | $mode"
        fi
    done
    echo "------------------------"
}

# Function to handle monitor mode
set_monitor_mode() {
    local interface="$1"
    if [ -z "$interface" ]; then
        handle_error "PLEASE SPECIFY AN INTERFACE"
        return 1
    fi
    
    winston_say $VERBOSITY_NORMAL "CONFIGURING $interface..." $BLUE
    echo -e "\n${BOLD}Step 1:${NC} Checking interface status"
    
    # Check if interface exists
    if ! iwconfig 2>/dev/null | grep -q "^$interface"; then
        handle_error "Interface $interface not found"
        return 1
    fi
    
    echo -e "${BOLD}Step 2:${NC} Stopping interfering processes"
    sudo airmon-ng check kill &>/dev/null
    
    echo -e "${BOLD}Step 3:${NC} Enabling monitor mode"
    if sudo airmon-ng start "$interface" &>/dev/null; then
        echo -e "${GREEN}Successfully enabled monitor mode on $interface${NC}"
        log_event "INFO" "Enabled monitor mode on $interface"
        return 0
    else
        handle_error "Failed to enable monitor mode on $interface"
        return 1
    fi
}

# Function to handle managed mode
set_managed_mode() {
    local interface="$1"
    if [ -z "$interface" ]; then
        handle_error "PLEASE SPECIFY AN INTERFACE"
        return 1
    fi
    
    winston_say $VERBOSITY_NORMAL "CONFIGURING $interface..." $BLUE
    echo -e "\n${BOLD}Step 1:${NC} Checking interface status"
    
    # Check if interface exists
    if ! iwconfig 2>/dev/null | grep -q "^$interface"; then
        handle_error "Interface $interface not found"
        return 1
    fi
    
    echo -e "${BOLD}Step 2:${NC} Stopping interfering processes"
    sudo airmon-ng check kill &>/dev/null
    
    echo -e "${BOLD}Step 3:${NC} Enabling managed mode"
    if sudo airmon-ng stop "$interface" &>/dev/null; then
        echo -e "${GREEN}Successfully enabled managed mode on $interface${NC}"
        log_event "INFO" "Enabled managed mode on $interface"
        return 0
    else
        handle_error "Failed to enable managed mode on $interface"
        return 1
    fi
}

# Function to start capture screen
start_capture_screen() {
    if screen -ls | grep -q "capture"; then
        screen -X -S capture quit
        winston_say $VERBOSITY_DEBUG "Closed existing capture screen" $CYAN
    fi
    
    winston_say $VERBOSITY_NORMAL "STARTING PACKET CAPTURE..." $BLUE
    echo -e "\n${BOLD}Capture Session${NC}"
    echo "------------------------"
    echo -e "${BOLD}Status:${NC} Starting..."
    
    # Start capture in screen session
    screen -dmS capture /winston/scripts/capture.sh
    
    # Wait a moment and check if screen started
    sleep 2
    if screen -ls | grep -q "capture"; then
        echo -e "${BOLD}Status:${NC} ${GREEN}Running${NC}"
        echo -e "${BOLD}Screen:${NC} capture"
        echo -e "${BOLD}To view:${NC} screen -r capture"
        echo -e "${BOLD}To detach:${NC} Ctrl+A, D"
        echo "------------------------"
        log_event "INFO" "Started packet capture session"
    else
        handle_error "Failed to start capture session"
        return 1
    fi
}

# Function to start deauth screen
start_deauth_screen() {
    if screen -ls | grep -q "deauth"; then
        screen -X -S deauth quit
        winston_say $VERBOSITY_DEBUG "Closed existing deauth screen" $CYAN
    fi
    
    winston_say $VERBOSITY_NORMAL "STARTING DEAUTHENTICATION ATTACK..." $BLUE
    echo -e "\n${BOLD}Deauth Session${NC}"
    echo "------------------------"
    echo -e "${BOLD}Status:${NC} Starting..."
    
    # Start deauth in screen session
    screen -dmS deauth /winston/scripts/deauth.sh
    
    # Wait a moment and check if screen started
    sleep 2
    if screen -ls | grep -q "deauth"; then
        echo -e "${BOLD}Status:${NC} ${GREEN}Running${NC}"
        echo -e "${BOLD}Screen:${NC} deauth"
        echo -e "${BOLD}To view:${NC} screen -r deauth"
        echo -e "${BOLD}To detach:${NC} Ctrl+A, D"
        echo "------------------------"
        log_event "INFO" "Started deauthentication session"
    else
        handle_error "Failed to start deauthentication session"
        return 1
    fi
}

# Function to show help
show_help() {
    local cmd="$1"
    
    if [ -z "$cmd" ]; then
        winston_say $VERBOSITY_NORMAL "AVAILABLE COMMANDS" $MAGENTA
        echo "------------------------"
        echo -e "${BOLD}help [command]          ${NC}- Show help message (optional: specific command)"
        echo -e "${BOLD}scan [all|target]       ${NC}- Scan for networks (all or specific target)"
        echo -e "${BOLD}interfaces              ${NC}- List available wireless interfaces"
        echo -e "${BOLD}monitor <interface>     ${NC}- Put interface in monitor mode"
        echo -e "${BOLD}managed <interface>     ${NC}- Put interface in managed mode"
        echo -e "${BOLD}capture <network>       ${NC}- Start capturing packets for a network"
        echo -e "${BOLD}deauth <network>        ${NC}- Start deauthentication attack"
        echo -e "${BOLD}handshakes              ${NC}- List captured handshakes"
        echo -e "${BOLD}crack <handshake>       ${NC}- Attempt to crack a handshake"
        echo -e "${BOLD}wordlist <file>         ${NC}- Set custom wordlist file"
        echo -e "${BOLD}status                  ${NC}- Show current operation status"
        echo -e "${BOLD}history                 ${NC}- Show command history"
        echo -e "${BOLD}verbose [level]         ${NC}- Set verbosity level (0-3)"
        echo -e "${BOLD}clear                   ${NC}- Clear the screen"
        echo -e "${BOLD}exit                    ${NC}- Exit Winston"
        echo -e "${BOLD}docs <topic>            ${NC}- Show documentation"
        echo "------------------------"
        winston_say $VERBOSITY_NORMAL "TYPE 'help <command>' FOR DETAILED HELP ON A SPECIFIC COMMAND" $YELLOW
    else
        case $cmd in
            "scan")
                winston_say $VERBOSITY_NORMAL "SCAN COMMAND HELP" $MAGENTA
                echo "------------------------"
                echo -e "${BOLD}Usage:${NC} scan [all|target]"
                echo -e "  ${BOLD}all    ${NC}- Scan for all networks in range"
                echo -e "  ${BOLD}target ${NC}- Scan for a specific network (e.g., 'scan MyNetwork')"
                echo -e "${BOLD}Example:${NC} scan all"
                echo -e "         scan MyHomeNetwork"
                ;;
            "interfaces")
                winston_say $VERBOSITY_NORMAL "INTERFACES COMMAND HELP" $MAGENTA
                echo "------------------------"
                echo -e "${BOLD}Usage:${NC} interfaces"
                echo -e "${BOLD}Shows all available wireless interfaces with their current status${NC}"
                echo -e "${BOLD}Example:${NC} interfaces"
                ;;
            "monitor")
                winston_say $VERBOSITY_NORMAL "MONITOR COMMAND HELP" $MAGENTA
                echo "------------------------"
                echo -e "${BOLD}Usage:${NC} monitor <interface>"
                echo -e "${BOLD}Puts the specified interface into monitor mode${NC}"
                echo -e "${BOLD}Example:${NC} monitor wlan0"
                ;;
            "managed")
                winston_say $VERBOSITY_NORMAL "MANAGED COMMAND HELP" $MAGENTA
                echo "------------------------"
                echo -e "${BOLD}Usage:${NC} managed <interface>"
                echo -e "${BOLD}Puts the specified interface into managed mode${NC}"
                echo -e "${BOLD}Example:${NC} managed wlan0"
                ;;
            "capture")
                winston_say $VERBOSITY_NORMAL "CAPTURE COMMAND HELP" $MAGENTA
                echo "------------------------"
                echo -e "${BOLD}Usage:${NC} capture <network>"
                echo -e "${BOLD}Starts capturing packets for the specified network${NC}"
                echo -e "${BOLD}Example:${NC} capture MyNetwork"
                ;;
            "deauth")
                winston_say $VERBOSITY_NORMAL "DEAUTH COMMAND HELP" $MAGENTA
                echo "------------------------"
                echo -e "${BOLD}Usage:${NC} deauth <network>"
                echo -e "${BOLD}Starts deauthentication attack on the specified network${NC}"
                echo -e "${BOLD}Example:${NC} deauth MyNetwork"
                ;;
            "verbose")
                winston_say $VERBOSITY_NORMAL "VERBOSE COMMAND HELP" $MAGENTA
                echo "------------------------"
                echo -e "${BOLD}Usage:${NC} verbose [level]"
                echo -e "  ${BOLD}0${NC} - Quiet mode (minimal output)"
                echo -e "  ${BOLD}1${NC} - Normal mode (default)"
                echo -e "  ${BOLD}2${NC} - Verbose mode (detailed output)"
                echo -e "  ${BOLD}3${NC} - Debug mode (all output)"
                echo -e "${BOLD}Example:${NC} verbose 2"
                ;;
            "docs")
                show_docs $cmd
                ;;
            *)
                winston_say $VERBOSITY_NORMAL "NO DETAILED HELP AVAILABLE FOR '$cmd'" $RED
                ;;
        esac
    fi
}

# Function to handle handshake listing
list_handshakes() {
    winston_say $VERBOSITY_NORMAL "CHECKING CAPTURED HANDSHAKES..." $BLUE
    echo -e "\n${BOLD}Captured Handshakes${NC}"
    echo "------------------------"
    echo -e "${BOLD}Network${NC} | ${BOLD}BSSID${NC} | ${BOLD}Date${NC} | ${BOLD}Status${NC}"
    echo "------------------------"
    
    # Get handshake information
    /winston/scripts/password_manager.sh list | while IFS='|' read -r timestamp network bssid password; do
        if [ ! -z "$network" ]; then
            echo -e "${GREEN}$network${NC} | $bssid | $timestamp | ${GREEN}Captured${NC}"
        fi
    done
    echo "------------------------"
}

# Function to handle wordlist setting
set_wordlist() {
    local wordlist="$1"
    if [ -z "$wordlist" ]; then
        winston_say $VERBOSITY_NORMAL "PLEASE SPECIFY A WORDLIST FILE" $RED
        return 1
    fi
    
    if [ -f "$wordlist" ]; then
        cp "$wordlist" "/winston/kenel/wordlist.txt"
        winston_say $VERBOSITY_NORMAL "WORDLIST UPDATED" $GREEN
    else
        winston_say $VERBOSITY_NORMAL "WORDLIST FILE NOT FOUND" $RED
    fi
}

# Function to show status
show_status() {
    winston_say $VERBOSITY_NORMAL "CHECKING SYSTEM STATUS..." $BLUE
    echo -e "\n${BOLD}System Status${NC}"
    echo "------------------------"
    
    # Check active interfaces
    echo -e "${BOLD}Active Interfaces:${NC}"
    echo "------------------------"
    iwconfig 2>/dev/null | while IFS= read -r line; do
        if [[ $line =~ ^[a-zA-Z0-9]+ ]]; then
            interface=$(echo "$line" | awk '{print $1}')
            mode=$(echo "$line" | grep -o "Mode:[^ ]*" | cut -d: -f2)
            if [ ! -z "$mode" ]; then
                echo -e "${GREEN}$interface${NC} ($mode)"
            fi
        fi
    done
    echo ""
    
    # Check active screens
    echo -e "${BOLD}Active Sessions:${NC}"
    echo "------------------------"
    if screen -ls | grep -q "capture\|deauth\|crack"; then
        screen -ls | grep -E "capture|deauth|crack" | while read -r line; do
            if [[ $line =~ (capture|deauth|crack) ]]; then
                session=$(echo "$line" | awk '{print $1}')
                status=$(echo "$line" | grep -o "Attached\|Detached")
                echo -e "${GREEN}$session${NC} ($status)"
            fi
        done
    else
        echo "No active sessions"
    fi
    echo ""
    
    # Check recent handshakes
    echo -e "${BOLD}Recent Handshakes:${NC}"
    echo "------------------------"
    /winston/scripts/password_manager.sh list | tail -n 5 | while IFS='|' read -r timestamp network bssid password; do
        if [ ! -z "$network" ]; then
            echo -e "${GREEN}$network${NC} ($timestamp)"
        fi
    done
    echo "------------------------"
}

# Function to show command history
show_history() {
    winston_say $VERBOSITY_NORMAL "SHOWING COMMAND HISTORY..." $BLUE
    echo -e "\n${BOLD}Recent Commands${NC}"
    echo "------------------------"
    echo -e "${BOLD}#${NC} | ${BOLD}Command${NC}"
    echo "------------------------"
    history | tail -n 20 | while read -r line; do
        if [[ $line =~ ^[[:space:]]*[0-9]+[[:space:]]+(.+)$ ]]; then
            cmd="${BASH_REMATCH[1]}"
            echo -e "${GREEN}$cmd${NC}"
        fi
    done
    echo "------------------------"
}

# Function to set verbosity level
set_verbosity() {
    local level=$1
    if [[ $level =~ ^[0-3]$ ]]; then
        CURRENT_VERBOSITY=$level
        echo -e "\n${BOLD}Verbosity Level${NC}"
        echo "------------------------"
        case $level in
            0) echo -e "Level ${GREEN}$level${NC}: Quiet mode (minimal output)" ;;
            1) echo -e "Level ${GREEN}$level${NC}: Normal mode (default)" ;;
            2) echo -e "Level ${GREEN}$level${NC}: Verbose mode (detailed output)" ;;
            3) echo -e "Level ${GREEN}$level${NC}: Debug mode (all output)" ;;
        esac
        echo "------------------------"
        log_event "INFO" "Verbosity level set to $level"
    else
        handle_error "INVALID VERBOSITY LEVEL. USE 0-3."
    fi
}

# Function to show documentation
show_docs() {
    local topic="$1"
    
    if [ -z "$topic" ]; then
        winston_say $VERBOSITY_NORMAL "AVAILABLE DOCUMENTATION TOPICS" $MAGENTA
        echo "------------------------"
        echo -e "${BOLD}general${NC}     - General usage and features"
        echo -e "${BOLD}commands${NC}    - Available commands and usage"
        echo -e "${BOLD}interface${NC}   - Terminal interface features"
        echo -e "${BOLD}security${NC}    - Security features and best practices"
        echo -e "${BOLD}trouble${NC}     - Troubleshooting guide"
        echo "------------------------"
        winston_say $VERBOSITY_NORMAL "TYPE 'docs <topic>' FOR DETAILED INFORMATION" $YELLOW
    else
        case $topic in
            "general")
                winston_say $VERBOSITY_NORMAL "GENERAL USAGE" $MAGENTA
                echo "------------------------"
                echo -e "${BOLD}Winston The Wifi Hound${NC} is an advanced WiFi security toolkit that combines"
                echo "the power of aircrack-ng with a user-friendly interface."
                echo ""
                echo -e "${BOLD}Key Features:${NC}"
                echo "- Interactive terminal interface"
                echo "- Network scanning and monitoring"
                echo "- Handshake capture and analysis"
                echo "- Password cracking capabilities"
                echo "- Secure password management"
                echo "- User authentication system"
                ;;
            "commands")
                show_help
                ;;
            "interface")
                winston_say $VERBOSITY_NORMAL "TERMINAL INTERFACE FEATURES" $MAGENTA
                echo "------------------------"
                echo -e "${BOLD}Command History${NC}"
                echo "- Use up/down arrows to navigate"
                echo "- View history with 'history' command"
                echo "- History persists between sessions"
                echo ""
                echo -e "${BOLD}Tab Completion${NC}"
                echo "- Press TAB to see available commands"
                echo "- Press TAB after a command for options"
                echo "- Available for interfaces, networks, and files"
                echo ""
                echo -e "${BOLD}Verbosity Levels${NC}"
                echo "- Use 'verbose' command to adjust output"
                echo "- Levels 0-3 for different detail levels"
                echo ""
                echo -e "${BOLD}Color Coding${NC}"
                echo "- RED: Errors and warnings"
                echo "- GREEN: Success messages"
                echo "- YELLOW: Important notices"
                echo "- BLUE: Information"
                echo "- MAGENTA: Headers"
                echo "- CYAN: Debug messages"
                ;;
            "security")
                winston_say $VERBOSITY_NORMAL "SECURITY FEATURES" $MAGENTA
                echo "------------------------"
                echo -e "${BOLD}Authentication${NC}"
                echo "- User-based access control"
                echo "- Secure password storage"
                echo "- Session management"
                echo ""
                echo -e "${BOLD}Data Protection${NC}"
                echo "- Encrypted password storage"
                echo "- Secure handshake storage"
                echo "- Process cleanup on exit"
                echo ""
                echo -e "${BOLD}Best Practices${NC}"
                echo "- Always use with authorization"
                echo "- Keep wordlists secure"
                echo "- Regular cleanup of temporary files"
                echo "- Monitor system resources"
                ;;
            "trouble")
                winston_say $VERBOSITY_NORMAL "TROUBLESHOOTING GUIDE" $MAGENTA
                echo "------------------------"
                echo -e "${BOLD}Common Issues:${NC}"
                echo "1. Permission issues:"
                echo "   sudo chmod +x *.sh"
                echo ""
                echo "2. Screen session problems:"
                echo "   sudo apt-get install screen"
                echo ""
                echo "3. Aircrack-ng issues:"
                echo "   sudo apt-get install aircrack-ng"
                echo ""
                echo -e "${BOLD}Debugging:${NC}"
                echo "- Use 'verbose 3' for maximum output"
                echo "- Check status with 'status' command"
                echo "- Verify interface with 'interfaces'"
                ;;
            *)
                winston_say $VERBOSITY_NORMAL "NO DOCUMENTATION AVAILABLE FOR '$topic'" $RED
                winston_say $VERBOSITY_NORMAL "TYPE 'docs' TO SEE AVAILABLE TOPICS" $YELLOW
                ;;
        esac
    fi
}

# Trap Ctrl+C and other termination signals
trap cleanup_and_exit SIGINT SIGTERM

# Main authentication loop
while true; do
    # Initialize environment first
    if ! initialize_environment; then
        echo "Failed to initialize environment. Exiting..."
        exit 1
    fi
    
    clear
    echo "WINSTON: WELCOME TO WIFI HOUND"
    echo "1. Login"
    echo "2. Exit"
    read -p "Select an option: " login_option
    
    if [ "$login_option" = "2" ]; then
        cleanup_and_exit
    elif [ "$login_option" = "1" ]; then
        echo "WINSTON: PLEASE ENTER YOUR CREDENTIALS"
        read -p "username: " username
        read -sp "password: " password
        echo ""
        
        if check_authorization "$username" "$password"; then
            echo "WINSTON: WELCOME."
            # Record session start time
            date +%s > "/tmp/winston_session_start"
            clear
            break
        fi
    else
        echo "WINSTON: INVALID OPTION. PLEASE TRY AGAIN."
        sleep 2
    fi
done

# Setup history navigation after successful login
setup_history_navigation

# Main command loop
while true; do
    # Check session timeout
    check_session_timeout
    
    # Update session timestamp
    date +%s > "/tmp/winston_session_start"
    
    # Read command with readline support
    if ! read -e -p "winston> " cmd args; then
        # Handle EOF (Ctrl+D)
        echo
        cleanup_and_exit
    fi
    
    # Skip empty commands
    if [ -z "$cmd" ]; then
        continue
    fi
    
    # Add command to history
    add_to_history "$cmd $args"
    
    # Log command
    log_event "DEBUG" "Command executed: $cmd $args"
    
    case $cmd in
        "help")
            show_help $args
            ;;
        "docs")
            show_docs $args
            ;;
        "scan")
            if [ -z "$interface" ]; then
                handle_error "No interface selected. Use 'interfaces' to list available interfaces and 'monitor <interface>' to select one."
                continue
            fi
            if [ "$args" = "all" ]; then
                scan_networks "$interface" "range" ""
            elif [ ! -z "$args" ]; then
                scan_networks "$interface" "specific" "$args"
            else
                handle_error "USAGE: scan [all|target]"
            fi
            ;;
        "interfaces")
            list_interfaces
            ;;
        "monitor")
            if [ -z "$args" ]; then
                handle_error "PLEASE SPECIFY AN INTERFACE"
                continue
            fi
            if set_monitor_mode "$args"; then
                interface="$args"
            fi
            ;;
        "managed")
            if [ -z "$args" ]; then
                handle_error "PLEASE SPECIFY AN INTERFACE"
                continue
            fi
            if set_managed_mode "$args"; then
                interface=""
            fi
            ;;
        "capture")
            if [ -z "$interface" ]; then
                handle_error "No interface selected. Use 'interfaces' to list available interfaces and 'monitor <interface>' to select one."
                continue
            fi
            if [ ! -z "$args" ]; then
                echo "name: $args" > "$KENEL_DIR/network_settings"
                start_capture_screen
            else
                handle_error "USAGE: capture <network>"
            fi
            ;;
        "deauth")
            if [ -z "$interface" ]; then
                handle_error "No interface selected. Use 'interfaces' to list available interfaces and 'monitor <interface>' to select one."
                continue
            fi
            if [ ! -z "$args" ]; then
                echo "name: $args" > "$KENEL_DIR/network_settings"
                start_deauth_screen
            else
                handle_error "USAGE: deauth <network>"
            fi
            ;;
        "handshakes")
            list_handshakes
            ;;
        "crack")
            if [ ! -z "$args" ]; then
                crack_handshake "$args"
            else
                handle_error "USAGE: crack <handshake>"
            fi
            ;;
        "wordlist")
            set_wordlist $args
            ;;
        "status")
            show_status
            ;;
        "history")
            show_history
            ;;
        "verbose")
            set_verbosity $args
            ;;
        "clear")
            clear
            ;;
        "exit")
            cleanup_and_exit
            ;;
        "stop")
            stop_scan
            ;;
        *)
            handle_error "UNKNOWN COMMAND. TYPE 'help' FOR AVAILABLE COMMANDS"
            ;;
    esac
done

# Function to crack a handshake
crack_handshake() {
    if [ -z "$1" ]; then
        handle_error "PLEASE SPECIFY A HANDSHAKE FILE"
        return 1
    fi
    
    winston_say $VERBOSITY_NORMAL "PREPARING TO CRACK HANDSHAKE..." $BLUE
    echo -e "\n${BOLD}Cracking Session${NC}"
    echo "------------------------"
    
    # Get wordlist from user
    echo -e "${BOLD}Step 1:${NC} Selecting wordlist"
    wordlist=$(/winston/scripts/select_wordlist.sh)
    
    if [ "$wordlist" = "none" ]; then
        winston_say $VERBOSITY_NORMAL "CRACKING ATTEMPT CANCELLED" $YELLOW
        return 1
    fi
    
    echo -e "${BOLD}Step 2:${NC} Starting cracking process"
    # Start cracking in a screen session
    screen -dmS crack aircrack-ng -w "$wordlist" "$1"
    
    # Wait a moment and check if screen started
    sleep 2
    if screen -ls | grep -q "crack"; then
        echo -e "${BOLD}Status:${NC} ${GREEN}Running${NC}"
        echo -e "${BOLD}Screen:${NC} crack"
        echo -e "${BOLD}To view:${NC} screen -r crack"
        echo -e "${BOLD}To detach:${NC} Ctrl+A, D"
        echo "------------------------"
        log_event "INFO" "Started cracking session for $1"
    else
        handle_error "Failed to start cracking session"
        return 1
    fi
}
