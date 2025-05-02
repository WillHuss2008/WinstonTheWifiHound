#!/bin/bash

# Standard paths
SCRIPTS_DIR="/winston/scripts"
KENEL_DIR="/winston/kenel"
SETTINGS_FILE="$KENEL_DIR/network_settings"

# Check if settings file exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "ERROR: Network settings file not found at $SETTINGS_FILE"
    exit 1
fi

# Read settings
channel=$(grep "channel" "$SETTINGS_FILE" | awk '{print $2}')
interface=$(grep "interface" "$SETTINGS_FILE" | awk '{print $2}')
ssid=$(grep "ssid" "$SETTINGS_FILE" | awk '{print $2}')

# Validate settings
if [ -z "$channel" ] || [ -z "$interface" ] || [ -z "$ssid" ]; then
    echo "ERROR: Missing required settings in $SETTINGS_FILE"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$KENEL_DIR"

# Start capture
sudo airodump-ng "$interface" -c "$channel" --bssid "$ssid" -w "$KENEL_DIR/psk"
