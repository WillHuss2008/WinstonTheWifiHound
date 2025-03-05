#!/bin/bash
if [[ $(id -u) -ne 0 ]]; then
    echo "permission denied"
    echo "Please use sudo permissions"
    exit 0
fi

# introductions
echo "Wifi Hound: Hello, I'm the Wifi Hound or WH.
"
echo "WH: I was designed to make wifi hacking easier for the average person and will help you to find out how secure your network is.
"
echo "WH: Warning: I DO NOT CONDONE ANY ILLEGAL USE of this program. Please only use this to test network strength and please ask for permission BEFORE you do this.
"
echo "WH: enjoy.
"

#sleep 10
echo "WH: please press enter to continue"
read n
clear
echo "WH: What's your name?
"
read username

# airmon-ng check
processes="$(sudo airmon-ng check | awk '/Name/ {flag=1; next} flag' | awk {'print $2'})"
if [[ $(echo $processes | wc -l) = "1" ]]; then
    echo "WH: So, $username, I didn't find anything that could harm your work, would you like to continue? (just don't say no and we'll begin
    "
else
    echo "WH: so, $username, I found $(echo "$processes" | wc -l) that could potentially screw up your work. 

    $processes
"

    echo "Wh: These will be killed and you will be invisible to anyone not scanning for radio waves.
"
    echo "WH: would you like to continue? (just don't say no and we'll continue)
"
fi
read answer
if [[ "$answer" = "no" ]]; then
    echo "I understand, thank you and have a great day. :)"
    exit 0
fi

echo "allright. Let's begin."
sudo airmon-ng check kill

echo "WH: let's start by picking an interface
"

interfaces=$(sudo airmon-ng | awk '/phy/')

echo "WH: here are your options

$interfaces

which one would you like (please enter the line number (1, 2, 3, etc.)
"
read answer
interface=$(echo "$interfaces" | sed -n ${answer}p | awk {'print $2'})

echo "
WH: allright, let's find a network.

WH: cancel the scan (CTRL+C) after you've found the network you want to scan (look in the ESSID column)
"

# airodupm-ng
sudo airodump-ng "$interface" --write airodump --output-format csv 
