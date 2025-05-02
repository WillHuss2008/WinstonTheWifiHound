#!/bin/bash
# Winston The Wifi Hound - Setup Script

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to print messages with appropriate verbosity
winston_say() {
    local level=$1
    local message=$2
    local color=$3
    
    if [ -z "$color" ]; then
        echo -e "WINSTON: $message"
    else
        echo -e "${color}WINSTON: $message${NC}"
    fi
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        winston_say 1 "PLEASE RUN THIS SCRIPT AS ROOT" $RED
        winston_say 1 "USE: sudo ./Wifi_Hound_Setup.sh" $YELLOW
        exit 1
    fi
}

# Function to check dependencies
check_dependencies() {
    winston_say 1 "CHECKING DEPENDENCIES..." $BLUE
    
    local missing_deps=()
    
    # Check for aircrack-ng
    if ! command -v aircrack-ng &> /dev/null; then
        missing_deps+=("aircrack-ng")
    fi
    
    # Check for screen
    if ! command -v screen &> /dev/null; then
        missing_deps+=("screen")
    fi
    
    # Check for iwconfig
    if ! command -v iwconfig &> /dev/null; then
        missing_deps+=("wireless-tools")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        winston_say 1 "MISSING DEPENDENCIES:" $RED
        for dep in "${missing_deps[@]}"; do
            echo "- $dep"
        done
        winston_say 1 "INSTALLING MISSING DEPENDENCIES..." $YELLOW
        apt-get update
        apt-get install -y "${missing_deps[@]}"
    else
        winston_say 1 "ALL DEPENDENCIES FOUND" $GREEN
    fi
}

# Function to create user account
create_user() {
    winston_say 1 "CREATING USER ACCOUNT..." $BLUE
    
    read -p "Enter username: " username
    read -sp "Enter password: " password
    echo ""
    
    # Create user directory
    mkdir -p /winston/$username
    
    # Create user profile
    echo "username: $username" > /winston/$username/user.profile
    echo "password: $(echo -n "$password" | sha256sum | awk {'print $1'})" >> /winston/$username/user.profile
    
    winston_say 1 "USER ACCOUNT CREATED" $GREEN
}

# Function to set up directories
setup_directories() {
    winston_say 1 "SETTING UP DIRECTORIES..." $BLUE
    
    # Create main directories
    mkdir -p /winston/kenel
    mkdir -p /winston/kenel/handshakes
    
    # Set permissions
    chmod -R 700 /winston
    
    winston_say 1 "DIRECTORIES CREATED" $GREEN
}

# Function to create default wordlist
create_wordlist() {
    winston_say 1 "CREATING DEFAULT WORDLIST..." $BLUE
    
    # Create a basic wordlist
    cat > /winston/kenel/wordlist.txt << EOL
password
12345678
qwerty
admin
welcome
EOL
    
    winston_say 1 "DEFAULT WORDLIST CREATED" $GREEN
}

# Function to download and manage wordlists
manage_wordlists() {
    winston_say 1 "MANAGING WORDLISTS..." $BLUE
    
    # Create wordlists directory
    mkdir -p /winston/kenel/wordlists
    
    # Function to download a wordlist
    download_wordlist() {
        local url=$1
        local filename=$2
        local description=$3
        
        winston_say 1 "DOWNLOADING $description..." $YELLOW
        wget -q --show-progress "$url" -O "/winston/kenel/wordlists/$filename"
        if [ $? -eq 0 ]; then
            winston_say 1 "$description DOWNLOADED SUCCESSFULLY" $GREEN
            chmod 600 "/winston/kenel/wordlists/$filename"
            chown $SUDO_USER:$SUDO_USER "/winston/kenel/wordlists/$filename"
            return 0
        else
            winston_say 1 "FAILED TO DOWNLOAD $description" $RED
            return 1
        fi
    }
    
    # Function to check and update wordlist
    check_and_update_wordlist() {
        local filename=$1
        local url=$2
        local description=$3
        
        if [ -f "/winston/kenel/wordlists/$filename" ]; then
            winston_say 1 "CHECKING $description FOR UPDATES..." $BLUE
            # Get remote file size
            remote_size=$(wget --spider "$url" 2>&1 | grep "Length:" | awk '{print $2}')
            local_size=$(stat -f%z "/winston/kenel/wordlists/$filename" 2>/dev/null || stat -c%s "/winston/kenel/wordlists/$filename")
            
            if [ "$remote_size" != "$local_size" ]; then
                winston_say 1 "UPDATING $description..." $YELLOW
                download_wordlist "$url" "$filename" "$description"
            else
                winston_say 1 "$description IS UP TO DATE" $GREEN
            fi
        else
            download_wordlist "$url" "$filename" "$description"
        fi
    }
    
    # Check for rockyou.txt in system
    if [ -f "/usr/share/wordlists/rockyou.txt.gz" ]; then
        winston_say 1 "FOUND ROCKYOU IN SYSTEM WORDLISTS" $GREEN
        cp "/usr/share/wordlists/rockyou.txt.gz" "/winston/kenel/wordlists/"
        gunzip "/winston/kenel/wordlists/rockyou.txt.gz"
    else
        # Download rockyou.txt
        check_and_update_wordlist "rockyou.txt.gz" \
            "https://github.com/praetorian-inc/Hob0Rules/raw/master/wordlists/rockyou.txt.gz" \
            "ROCKYOU WORDLIST"
        if [ -f "/winston/kenel/wordlists/rockyou.txt.gz" ]; then
            gunzip "/winston/kenel/wordlists/rockyou.txt.gz"
        fi
    fi
    
    # Download additional wordlists
    check_and_update_wordlist "darkc0de.lst" \
        "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/darkc0de.txt" \
        "DARKC0DE WORDLIST"
    
    check_and_update_wordlist "common-passwords.txt" \
        "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-1000000.txt" \
        "COMMON PASSWORDS WORDLIST"
    
    # Create wordlist selection script
    cat > /winston/scripts/select_wordlist.sh << 'EOL'
#!/bin/bash

# Function to show wordlist selection menu
select_wordlist() {
    echo "Available wordlists:"
    echo "1) rockyou.txt (14 million passwords)"
    echo "2) darkc0de.lst (1.5 million passwords)"
    echo "3) common-passwords.txt (1 million most common passwords)"
    echo "4) Use custom wordlist"
    echo "5) None (skip wordlist)"
    
    while true; do
        read -p "Enter your choice (1-5): " choice
        case $choice in
            1)
                echo "/winston/kenel/wordlists/rockyou.txt"
                break
                ;;
            2)
                echo "/winston/kenel/wordlists/darkc0de.lst"
                break
                ;;
            3)
                echo "/winston/kenel/wordlists/common-passwords.txt"
                break
                ;;
            4)
                read -p "Enter path to your custom wordlist: " custom_wordlist
                if [ -f "$custom_wordlist" ]; then
                    echo "$custom_wordlist"
                    break
                else
                    echo "File not found. Please try again." >&2
                fi
                ;;
            5)
                echo "none"
                break
                ;;
            *)
                echo "Invalid choice. Please try again." >&2
                ;;
        esac
    done
}

# If script is run directly, show selection menu
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    select_wordlist
fi
EOL
    
    chmod +x /winston/scripts/select_wordlist.sh
    chown $SUDO_USER:$SUDO_USER /winston/scripts/select_wordlist.sh
    
    # Create update script
    cat > /winston/scripts/update_wordlists.sh << 'EOL'
#!/bin/bash
# Function to update wordlists
update_wordlists() {
    echo "Updating wordlists..."
    cd /winston/kenel/wordlists
    
    # Update rockyou
    if [ -f "rockyou.txt.gz" ]; then
        wget -q --show-progress "https://github.com/praetorian-inc/Hob0Rules/raw/master/wordlists/rockyou.txt.gz" -O rockyou.txt.gz.new
        if [ $? -eq 0 ]; then
            mv rockyou.txt.gz.new rockyou.txt.gz
            gunzip -f rockyou.txt.gz
        fi
    fi
    
    # Update darkc0de
    wget -q --show-progress "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/darkc0de.txt" -O darkc0de.lst.new
    if [ $? -eq 0 ]; then
        mv darkc0de.lst.new darkc0de.lst
    fi
    
    # Update common passwords
    wget -q --show-progress "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-1000000.txt" -O common-passwords.txt.new
    if [ $? -eq 0 ]; then
        mv common-passwords.txt.new common-passwords.txt
    fi
    
    echo "Wordlists updated successfully!"
}

# If script is run directly, update wordlists
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    update_wordlists
fi
EOL
    
    chmod +x /winston/scripts/update_wordlists.sh
    chown $SUDO_USER:$SUDO_USER /winston/scripts/update_wordlists.sh
    
    winston_say 1 "WORDLISTS SETUP COMPLETE" $GREEN
    winston_say 1 "TO UPDATE WORDLISTS, RUN: /winston/scripts/update_wordlists.sh" $YELLOW
    winston_say 1 "WORDLIST SELECTION WILL BE AVAILABLE DURING CRACKING" $YELLOW
}

# Function to move scripts to secure location
move_scripts() {
    winston_say 1 "MOVING SCRIPTS TO SECURE LOCATION..." $BLUE
    
    # Create scripts directory in /winston
    mkdir -p /winston/scripts
    
    # Get current directory
    current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Copy all .sh files to /winston/scripts
    cp "$current_dir"/*.sh /winston/scripts/
    
    # Set proper permissions
    chmod 700 /winston/scripts/*.sh
    chown -R $SUDO_USER:$SUDO_USER /winston/scripts
    
    winston_say 1 "SCRIPTS MOVED TO /winston/scripts" $GREEN
}

# Function to set up permissions
setup_permissions() {
    winston_say 1 "SETTING UP PERMISSIONS..." $BLUE
    
    # Make scripts executable
    chmod +x "$(dirname "$0")"/*.sh
    
    # Set ownership
    chown -R $SUDO_USER:$SUDO_USER /winston
    
    winston_say 1 "PERMISSIONS SET" $GREEN
}

# Function to add winston command
add_winston_command() {
    winston_say 1 "ADDING WINSTON COMMAND..." $BLUE
    
    # Get the absolute path of the script in its new location
    script_path="/winston/scripts/Wifi_Hound_Script.sh"
    
    # Get the user's home directory
    user_home=$(eval echo ~$SUDO_USER)
    
    # Check if .bashrc exists
    if [ ! -f "$user_home/.bashrc" ]; then
        winston_say 1 "CREATING .bashrc FILE..." $YELLOW
        touch "$user_home/.bashrc"
        chown $SUDO_USER:$SUDO_USER "$user_home/.bashrc"
    fi
    
    # Check if alias already exists
    if grep -q "alias winston=" "$user_home/.bashrc"; then
        winston_say 1 "UPDATING EXISTING WINSTON ALIAS..." $YELLOW
        # Remove existing alias
        sed -i '/alias winston=/d' "$user_home/.bashrc"
    fi
    
    # Add alias to .bashrc
    echo "" >> "$user_home/.bashrc"
    echo "# Winston The Wifi Hound command" >> "$user_home/.bashrc"
    echo "alias winston='sudo $script_path'" >> "$user_home/.bashrc"
    
    # Set proper ownership
    chown $SUDO_USER:$SUDO_USER "$user_home/.bashrc"
    
    # Verify the alias was added
    if grep -q "alias winston=" "$user_home/.bashrc"; then
        winston_say 1 "WINSTON COMMAND ADDED SUCCESSFULLY" $GREEN
        winston_say 1 "PLEASE RUN 'source ~/.bashrc' TO APPLY CHANGES" $YELLOW
    else
        winston_say 1 "ERROR: FAILED TO ADD WINSTON COMMAND" $RED
        winston_say 1 "PLEASE MANUALLY ADD THE FOLLOWING LINE TO YOUR ~/.bashrc:" $YELLOW
        echo "alias winston='sudo $script_path'"
    fi
}

# Function to clean up repository
cleanup_repository() {
    winston_say 1 "CLEANING UP REPOSITORY..." $BLUE
    
    # Get current directory
    current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Store the parent directory
    parent_dir="$(dirname "$current_dir")"
    
    # Remove all .sh files from repository
    rm -f "$current_dir"/*.sh
    
    # Remove .git directory if it exists
    if [ -d "$current_dir/.git" ]; then
        rm -rf "$current_dir/.git"
    fi
    
    # Remove the directory itself
    cd "$parent_dir"
    rm -rf "$current_dir"
    
    winston_say 1 "REPOSITORY CLEANED" $GREEN
}

# Function to show example usage
show_example_usage() {
    winston_say 1 "EXAMPLE USAGE:" $MAGENTA
    echo "------------------------"
    winston_say 1 "1. START WINSTON:" $BLUE
    echo "   $ winston"
    echo ""
    winston_say 1 "2. LOGIN WITH YOUR CREDENTIALS:" $BLUE
    echo "   Username: $username"
    echo "   Password: [your password]"
    echo ""
    winston_say 1 "3. BASIC COMMANDS:" $BLUE
    echo "   - help                    : Show available commands"
    echo "   - interfaces              : List wireless interfaces"
    echo "   - monitor wlan0           : Set interface to monitor mode"
    echo "   - scan all                : Scan for all networks"
    echo "   - capture HomeNetwork     : Start capturing packets"
    echo "   - deauth HomeNetwork      : Start deauthentication attack"
    echo "   - handshakes              : List captured handshakes"
    echo "   - crack handshake.cap     : Attempt to crack a handshake"
    echo "   - status                  : Show current status"
    echo "   - verbose 2               : Set verbosity level"
    echo "   - docs                    : Show documentation"
    echo "   - exit                    : Exit the program"
    echo ""
    winston_say 1 "4. EXAMPLE WORKFLOW:" $BLUE
    echo "   $ winston"
    echo "   winston> interfaces"
    echo "   winston> monitor wlan0"
    echo "   winston> scan all"
    echo "   winston> capture HomeNetwork"
    echo "   winston> deauth HomeNetwork"
    echo "   winston> handshakes"
    echo "   winston> crack handshake.cap"
    echo ""
    winston_say 1 "5. GETTING HELP:" $BLUE
    echo "   - Type 'help' for command list"
    echo "   - Type 'help <command>' for specific help"
    echo "   - Type 'docs' for detailed documentation"
    echo "------------------------"
}

# Main setup process
winston_say 1 "STARTING WINSTON SETUP" $MAGENTA
echo "------------------------"

# Check if running as root
check_root

# Check and install dependencies
check_dependencies

# Create user account
create_user

# Set up directories
setup_directories

# Manage wordlists
manage_wordlists

# Move scripts to secure location
move_scripts

# Set up permissions
setup_permissions

# Add winston command
add_winston_command

# Clean up repository
cleanup_repository

echo "------------------------"
winston_say 1 "SETUP COMPLETE!" $GREEN
winston_say 1 "YOU CAN NOW USE THE 'winston' COMMAND TO START THE PROGRAM" $YELLOW
winston_say 1 "PLEASE RUN 'source ~/.bashrc' TO APPLY THE NEW COMMAND" $YELLOW

# Show example usage
show_example_usage
