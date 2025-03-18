#!/bin/bash

channel="$(cat /winston/kenel/network_settings | grep Channel | awk {'print $2'} | grep -oe '[A-Za-z0-9:_-]\+')"
ssid="$(cat /winston/kenel/network_settings | grep SSID | awk {'print $2'} | grep -oe '[A-Za-z0-9:_-]\+')"
interface="$(cat /winston/kenel/network_settings | grep interface | awk {'print $2'} | grep -oe '[A-Za-z0-9:_-]\+')"
echo "$channel, $ssid, $interface"

sudo airodump-ng -c $channel --bssid $ssid -w /winston/kenel/psk $interface & &>/dev/null
