#!/bin/bash

# Password Manager for Winston The Wifi Hound
# This script manages the storage and retrieval of captured passwords

KENEL_DIR="/winston/kenel"
PASSWORD_DB="$KENEL_DIR/password_database.txt"
HANDSHAKE_DIR="$KENEL_DIR/handshakes"

# Create necessary directories if they don't exist
mkdir -p "$HANDSHAKE_DIR"

# Function to store a new password
store_password() {
    local network_name="$1"
    local bssid="$2"
    local password="$3"
    local handshake_file="$4"
    
    # Create a timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Store in database
    echo "$timestamp|$network_name|$bssid|$password" >> "$PASSWORD_DB"
    
    # If handshake file exists, move it to handshake directory
    if [ -f "$handshake_file" ]; then
        cp "$handshake_file" "$HANDSHAKE_DIR/${network_name}_${bssid}.cap"
    fi
}

# Function to search for a password
search_password() {
    local search_term="$1"
    if [ -f "$PASSWORD_DB" ]; then
        grep -i "$search_term" "$PASSWORD_DB"
    else
        echo "No passwords stored yet."
    fi
}

# Function to list all stored passwords
list_passwords() {
    if [ -f "$PASSWORD_DB" ]; then
        echo "Timestamp | Network Name | BSSID | Password"
        echo "----------------------------------------"
        cat "$PASSWORD_DB" | while IFS='|' read -r timestamp network bssid password; do
            echo "$timestamp | $network | $bssid | $password"
        done
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