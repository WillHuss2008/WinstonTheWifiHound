#!/bin/bash
# start this at home
# add password requirements later

winston=/winston
user=$(cat $winston/user.profile | grep username | awk {'print $2'})

echo "WIFI HOUND: LET'S BEGIN.
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
read -p "$user: " option
interface=$(echo "$interfaces" | grep $option)
sleep 2s
echo "
WIFI HOUND: SEARCHING FOR NETWORKS
"

sudo airodump-ng --write /winston/airodump-ng --output-format csv $interface
