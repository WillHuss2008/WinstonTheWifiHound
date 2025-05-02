#!/bin/bash

# Wordlist selector for Winston The Wifi Hound
# This script allows users to select a wordlist for password cracking

# Standard paths
SCRIPTS_DIR="/winston/scripts"
KENEL_DIR="/winston/kenel"
WORDLIST_DIR="$KENEL_DIR/wordlists"

# Create wordlist directory if it doesn't exist
mkdir -p "$WORDLIST_DIR"

# Function to list available wordlists
list_wordlists() {
    echo "Available wordlists:"
    echo "1. Default (rockyou.txt)"
    echo "2. Custom wordlist 1"
    echo "3. Custom wordlist 2"
    echo "4. Custom wordlist 3"
    echo "5. None (skip wordlist)"
}

# Function to validate wordlist
validate_wordlist() {
    local wordlist="$1"
    if [ ! -f "$wordlist" ]; then
        echo "ERROR: Wordlist file not found: $wordlist"
        return 1
    fi
    if [ ! -r "$wordlist" ]; then
        echo "ERROR: Cannot read wordlist file: $wordlist"
        return 1
    fi
    return 0
}

# Main script logic
list_wordlists
read -p "Select a wordlist (1-5): " choice

case "$choice" in
    1)
        wordlist="/usr/share/wordlists/rockyou.txt"
        ;;
    2)
        wordlist="$WORDLIST_DIR/custom1.txt"
        ;;
    3)
        wordlist="$WORDLIST_DIR/custom2.txt"
        ;;
    4)
        wordlist="$WORDLIST_DIR/custom3.txt"
        ;;
    5)
        echo "none"
        exit 0
        ;;
    *)
        echo "ERROR: Invalid selection"
        exit 1
        ;;
esac

# Validate selected wordlist
if validate_wordlist "$wordlist"; then
    echo "$wordlist"
else
    echo "none"
fi 