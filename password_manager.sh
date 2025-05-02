#!/bin/bash

# Password Manager for Winston The Wifi Hound
# This script manages the storage and retrieval of captured passwords

# Standard paths
SCRIPTS_DIR="/winston/scripts"
KENEL_DIR="/winston/kenel"
PASSWORD_DB="$KENEL_DIR/password_database.txt"
HANDSHAKE_DIR="$KENEL_DIR/handshakes"
ENCRYPTED_DB="$KENEL_DIR/password_database.enc"

# Create necessary directories if they don't exist
mkdir -p "$HANDSHAKE_DIR"

# Set secure permissions
chmod 700 "$KENEL_DIR"
chmod 600 "$PASSWORD_DB" 2>/dev/null
chmod 600 "$ENCRYPTED_DB" 2>/dev/null

# Function to encrypt data
encrypt_data() {
    local data="$1"
    echo "$data" | openssl enc -aes-256-cbc -salt -pass pass:"$ENCRYPTION_KEY" 2>/dev/null
}

# Function to decrypt data
decrypt_data() {
    local data="$1"
    echo "$data" | openssl enc -aes-256-cbc -d -salt -pass pass:"$ENCRYPTION_KEY" 2>/dev/null
}

# Function to store a new password
store_password() {
    local network_name="$1"
    local bssid="$2"
    local password="$3"
    local handshake_file="$4"
    
    # Validate inputs
    if [ -z "$network_name" ] || [ -z "$bssid" ] || [ -z "$password" ]; then
        echo "ERROR: Missing required parameters"
        return 1
    fi
    
    # Create a timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Encrypt and store in database
    local entry="$timestamp|$network_name|$bssid|$password"
    encrypt_data "$entry" >> "$ENCRYPTED_DB"
    
    # If handshake file exists, move it to handshake directory
    if [ -f "$handshake_file" ]; then
        local handshake_dest="$HANDSHAKE_DIR/${network_name}_${bssid}.cap"
        cp "$handshake_file" "$handshake_dest"
        chmod 600 "$handshake_dest"
    fi
}

# Function to search for a password
search_password() {
    local search_term="$1"
    if [ -f "$ENCRYPTED_DB" ]; then
        while IFS= read -r line; do
            decrypted=$(decrypt_data "$line")
            if echo "$decrypted" | grep -qi "$search_term"; then
                echo "$decrypted"
            fi
        done < "$ENCRYPTED_DB"
    else
        echo "No passwords stored yet."
    fi
}

# Function to list all stored passwords
list_passwords() {
    if [ -f "$ENCRYPTED_DB" ]; then
        echo "Timestamp | Network Name | BSSID | Password"
        echo "----------------------------------------"
        while IFS= read -r line; do
            decrypted=$(decrypt_data "$line")
            IFS='|' read -r timestamp network bssid password <<< "$decrypted"
            echo "$timestamp | $network | $bssid | $password"
        done < "$ENCRYPTED_DB"
    else
        echo "No passwords stored yet."
    fi
}

# Main script logic
case "$1" in
    "store")
        if [ "$#" -ne 5 ]; then
            echo "Usage: $0 store <network_name> <bssid> <password> <handshake_file>"
            exit 1
        fi
        store_password "$2" "$3" "$4" "$5"
        ;;
    "search")
        if [ "$#" -ne 2 ]; then
            echo "Usage: $0 search <search_term>"
            exit 1
        fi
        search_password "$2"
        ;;
    "list")
        list_passwords
        ;;
    *)
        echo "Usage: $0 {store|search|list}"
        echo "  store <network_name> <bssid> <password> <handshake_file>"
        echo "  search <search_term>"
        echo "  list"
        exit 1
        ;;
esac 