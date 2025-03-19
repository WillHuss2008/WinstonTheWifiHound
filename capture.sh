#!/bin/bash

settings=/winston/kenel/network_settings
kenel=/winston/kenel

channel=$(cat $settings | grep Channel | awk {'print $2'})
interface=$(cat $settings | grep interface | awk {'print $2'})
ssid=$(cat $settings | grep SSID | awk {'print $2'})

sudo airodump-ng -c $channel --bssid $ssid -w $kenel/psk $interface

cat psk-01.csv | grep -A 100 Station | awk {'print $1'} | grep -v Station > device_options
