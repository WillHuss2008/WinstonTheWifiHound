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
    
    # Remove all .sh files from repository
    rm -f "$current_dir"/*.sh
    
    # Remove .git directory if it exists
    if [ -d "$current_dir/.git" ]; then
        rm -rf "$current_dir/.git"
    fi
    
    # Remove the directory itself if it's empty
    if [ -z "$(ls -A $current_dir)" ]; then
        rmdir "$current_dir"
    fi
    
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

# Create default wordlist
create_wordlist

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
