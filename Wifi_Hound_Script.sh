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

echo "WINSTON: LET'S BEGIN.
"
processes="$(sudo airmon-ng check | sed -n '/Name/,$p' | awk {'print $2'} | grep -v Name | grep -v '^[[:space:]]*$')"
num_processes=$(echo "$processes" | wc -l)

if [[ $((num_processes)) -ne 0 ]]; then
    sleep 2s
    echo "WIFI HOUND: I FOUND $num_processes PROCESSES THAT COULD DISRUPT YOUR WORK.
    "
    sleep 2s
    echo "WIFI HOUND: KILLING THEM NOW
    "
    sudo airmon-ng check kill
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
sleep 2s
echo "
WINSTON: SEARCHING FOR NETWORKS
"
if ! ls /winston/kenel; then
    sudo mkdir /winston/kenel
fi

sudo airodump-ng $interface -w /winston/kenel/airodump-ng --write-interval 1 --output-format csv &>/dev/null &


# latest work
echo "WINSTON: IS THERE A SPECIFIC NETWORK YOU'RE LOOKING FOR?
"
read -p "$username: " answer
if [[ $answer = "yes" ]]; then
    echo "WINSTON: WHAT'S THE NETWORK NAME?
    "
    read -p "$username: " answer1
    while true; do
        if cat /winston/kenel/airodump-ng-01.csv | grep $answer1; then
            sudo kill -9 $(pstree -p | grep airodump-ng | grep -o '[0-9]\+') &>/dev/null
            clear
            echo "WINSTON: WE FOUND IT
            "
            break
        fi
    done
else
    sleep 10
    sudo kill -9 $(pstree -p | grep airodump-ng | grep -o '[0-9]\+') &>/dev/null
fi
search=/winston/kenel/airodump-ng-01.csv
echo "WINSTON: HERE'S THE NETWORK INFORMATION.
"
name=$(cat $search | grep $answer1 | awk {'print $19'} | grep -oE '[A-Za-z0-9:-]+')
SSID=$(cat $search | grep $answer1 | head -n 1 | awk {'print $1'} | grep -oE '[A-Za-z0-9:-]+')
channel=$(cat $search | grep $answer1 | head -n 1 | awk {'print $6'} | grep -oE '[A-Za-z0-9:-]+')
security=$(cat $search | grep $answer1 | head -n 1 | awk {'print $8'} | grep -oE '[A-Za-z0-9:-]+')
if [[ $security = "not" ]]; then
    security="not found"
fi
echo "name: $name
SSID: $SSID
Channel: $channel
Network Security: $security
"
if [[ $security = "WPA3" ]]; then
    echo "WINSTON: I'M SORRY, THERE'S NOTHING I CAN DO ABOUT THIS ONE.
    "
    exit 0
fi

