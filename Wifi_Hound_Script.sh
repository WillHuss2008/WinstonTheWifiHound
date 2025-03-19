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


echo "WINSTON: IS THERE A SPECIFIC NETWORK YOU'RE LOOKING FOR?
"
read -p "$username: " answer
if [[ $answer = "yes" ]]; then
    echo "WINSTON: WHAT'S THE NETWORK NAME?
    "
    read -p "$username: " answer1
    name=$answer1
    clear
    echo "WINSTON: SAY LESS.
    "
    while true; do
        if cat /winston/kenel/airodump-ng-01.csv | grep $answer1; then
            sudo kill -9 $(pstree -p | grep airodump-ng | grep -o '[0-9]\+') &>/dev/null
            clear
            echo "WINSTON: FOUND IT
            "
            break
        fi
    done
elif [[ $answer = "no" ]]; then
    while true; do
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
        if [ $line -eq 1 && $line -lt $(($lines + 1)) ]; then
            name="$(cat /winston/kenel/airodump-ng-01.csv | grep $(cat $options | sed -n ${line}p) | awk {'print $19'} | grep -oe '[A-Za-z0-9:_-]\+')"
            echo "$name"
            break
        elif [ $response1 -eq $(($lines + 1)) ]; then
            echo "WINSTON: PLEASE WAIT
            "
            sleep 10
            continue
        fi
        break
    done
fi

echo "WINSTON: HERE'S THE NETWORK INFORMATION.
"
search=/winston/kenel/airodump-ng-01.csv
name=$(cat $search | grep "$name" | awk {'print $19'} | grep -oE '[A-Za-z0-9:_-]+')
SSID=$(cat $search | grep "$name" | awk {'print $1'} | grep -oE '[A-Za-z0-9:_-]+')
channel=$(cat $search | grep "$name" | awk {'print $6'} | grep -oE '[A-Za-z0-9:_-]+')
security=$(cat $search | grep "$name" | awk {'print $8'} | grep -oE '[A-Za-z0-9:_-]+')
if [[ $security = "not" ]]; then
    security="not found"
fi
echo "name: $name
SSID: $SSID
Channel: $channel
Network Security: $security
interface: $interface" > /winston/kenel/network_settings

if [[ $security = "WPA3" ]]; then
    echo "WINSTON: I'M SORRY, THERE'S NOTHING I CAN DO ABOUT THIS ONE.
    "
    exit 0
fi
sudo kill -9 $(pstree -p | grep airodump-ng | grep -o '[0-9]\+') &>/dev/null
clear

screen -dmS capture ./capture.sh
sleep 10s
pid=$(screen -ls | grep capture | grep -oe '[0-9]')

cat /winston/kenel/psk-01.csv | grep -A 100 Station | awk {'print $1'} | grep -oe '[A-Za-z0-9:]\+' | grep -v Station > /winston/kenel/device_options

#start here

