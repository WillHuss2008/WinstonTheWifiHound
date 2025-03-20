#!/bin/bash

settings=/winston/kenel/network_settings
kenel=/winston/kenel

channel=$(cat $settings | grep channel | awk {'print $2'})
interface=$(cat $settings | grep interface | awk {'print $2'})
ssid=$(cat $settings | grep ssid | awk {'print $2'})

sudo airodump-ng $interface -c $channel --bssid $ssid -w $kenel/psk 

cat $kenel/psk-01.csv | grep -A 100 Station | awk {'print $1'} | grep -oe '[A-Z0-9:]\+' | grep -v Station > /winston/kenel/device_options
