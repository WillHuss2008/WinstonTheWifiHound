#!/bin/bash

echo "WIFI HOUND: HELLO.
"
sleep 2s
echo "WIFI HOUND: MY NAME IS THE WIFI HOUND.
"
sleep 2s
echo "WIFI HOUND: THIS IS THE SET-UP SCRIPT, SO WE'RE GOING TO SET UP YOUR PASSWORD, USERNAME, AND OTHER THINGS THAT'LL MAKE YOUR EXPERIENCE EASIER.
"
sleep 2s
echo "WIFI HOUND: LET'S START WITH THE BASICS. 
"
sleep 2s
while true; do
    echo "WIFI HOUND: WHAT'S YOUR FULL NAME?
"
    read -p "YOUR NAME: " FULLNAME
    sleep 2s
    echo "
WIFI HOUND: YOUR NAME IS $FULLNAME. CORRECT?
"
    read -p "YOU: " answer
    if [[ $answer = "yes" ]]; then
       break 
    elif ! [[ $answer = "yes" && $answer = "no" ]]; then
        sleep 2s
        echo "
WIFI HOUND: I'M SORRY, I COULDN'T UNDERSTAND. PLEASE TRY AGAIN.
"
    fi
done
sleep 2s
echo "
WIFI HOUND: OKAY.
"
while true; do
    sleep 2s
    echo "WIFI HOUND: WHAT WOULD YOU LIKE YOUR USERNAME TO BE?
    "
    read -p "YOUR USERNAME: " USERNAME
    sleep 2s
    echo "
WIFI HOUND: YOUR USERNAME IS $USERNAME. CORRECT?
"
    read -p "YOU: " answer
    if [[ $answer = "yes" ]]; then
        break
    elif ! [[ $answer = "yes" && $answer = "no" ]]; then
        sleep 2s
        echo "
WIFI HOUND: I'M SORRY, I COULDN'T UNDERSTAND. PLEASE TRY AGAIN.
"
    fi
done
sleep 2s
echo "
WIFI HOUND: OKAY.
"
while true; do
    sleep 2s
    echo "WIFI HOUND: PLEASE ENTER THE PASSWORD YOU WOULD LIKE TO USE
"
    read -sp "YOUR PASSWORD: " PASSWORD
    sleep 1s
    echo "
WIFI HOUND: PLEASE ENTER IT AGAIN TO DOUBLE CHECK IT.
"
    read -sp "YOUR PASSWORD: " PASSWORD1
    if [[ $PASSWORD = $PASSWORD1 ]]; then
        break
    else
        sleep 2s
        echo "
WIFI HOUND: YOUR PASSWORDS DON'T MATCH. PLEASE TRY AGAIN.
"
    fi
done
sleep 2s 
echo "WIFI HOUND: WHERE IS YOUR WIFI_HOUND_PROJECT FOLDER KEPT? EX: /home/pi/Desktop/
"
while true; do
    read -p "$USERNAME: " location
    sleep 2s
    echo "
WIFI HOUND: YOUR WIFI_HOUND_PROJECT IS IN $location. CORRECT?
    "
    read -p "$USERNAME: " answer
    if [[ $answer = "yes" ]]; then
        break
    elif ! [[ $answer = "yes" && $answer = "no" ]]; then
        sleep 2s
        echo "
WIFI HOUND: I'M SORRY, I DON'T UNDERSTAND. PLEASE TRY AGAIN.
        "
    fi
done
profile=$location/Wifi_Hound_Project/Wifi_Hound_User.profile
conifg=$location/Wifi_Hound_Project/Wifi_Hound.conf
echo "name: $FULLNAME
username: $USERNAME" > $profile
echo "password: $PASSWORD" >> $profile
vim -X -c "let &key='$PASSWORD'" -c ":x" $profile
sleep 2s
echo "
WIFI HOUND: THANK YOU FOR SETTING UP WIFI HOUND.
"
sleep 2s
echo "WIFI HOUND: THE USE OF THIS PROGRAM WILL ONLY BE AVAILABLE TO YOU AND WHOEVER HAS THE LOGIN INFORMATION. PLEASE KEEP IT SAFE.
"
sleep 2s
echo "WIFI HOUND: ALL OF THIS INFORMATION CAN BE REVISITED IN THE WIFI_HOUND_USER.PROFILE FILE, WHICH IS ONLY READABLE THROUGH VIM WITH THE PASSWORD YOU'VE JUST ENTERED.
"
