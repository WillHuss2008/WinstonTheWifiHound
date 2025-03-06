#!/bin/bash
clear

echo "WINSTON: HELLO.
"
echo "WINSTON: MY NAME IS WINSTON, THE WIFI HOUND.
"
echo "WINSTON: THIS IS THE SET-UP SCRIPT, SO WE'RE GOING TO SET UP YOUR PASSWORD, USERNAME, AND OTHER THINGS THAT'LL MAKE YOUR EXPERIENCE EASIER.
"
echo "WINSTON: LET'S START WITH THE BASICS. 
"
while true; do
    echo "WINSTON: WHAT'S YOUR FULL NAME?
"
    read -p "YOUR NAME: " FULLNAME
    echo "
WIFI HOUND: YOUR NAME IS $FULLNAME. CORRECT?
"
    read -p "YOU: " answer
    if [[ $answer = "yes" ]]; then
       break 
    elif ! [[ $answer = "yes" && $answer = "no" ]]; then
        clear
        echo "
WINSTON: I'M SORRY, I COULDN'T UNDERSTAND. PLEASE TRY AGAIN.
"
    fi
done
clear
while true; do
    echo "WINSTON: WHAT WOULD YOU LIKE YOUR USERNAME TO BE?
    "
    read -p "YOUR USERNAME: " USERNAME
    echo "
WINSTON: YOUR USERNAME IS $USERNAME. CORRECT?
"
    read -p "YOU: " answer
    if [[ $answer = "yes" ]]; then
        break
    elif ! [[ $answer = "yes" && $answer = "no" ]]; then
        clear
        echo "
WINSTON: I'M SORRY, I COULDN'T UNDERSTAND. PLEASE TRY AGAIN.
"
    fi
done
clear
while true; do
    echo "WINSTON: PLEASE ENTER THE PASSWORD YOU WOULD LIKE TO USE
"
    read -sp "YOUR PASSWORD: " PASSWORD
    echo "
WINSTON: PLEASE ENTER IT AGAIN TO DOUBLE CHECK IT.
"
    read -sp "YOUR PASSWORD: " PASSWORD1
    if [[ $PASSWORD = $PASSWORD1 ]]; then
        break
    else
        clear
        echo "
WINSTON: YOUR PASSWORDS DON'T MATCH. PLEASE TRY AGAIN.
"
    fi
done
clear
echo "WINSTON: PLEASE WAIT WHILE WE SET UP YOUR WIFI HOUND
"
user=$(whoami)
wait
if ! sudo ls "/winston" 2>/dev/null; then
    sudo mkdir /winston
    sudo chmod 700 /winston
    sudo chown $user /winston
fi
echo "username: $USERNAME
full name: $FULLNAME
password: $(echo $PASSWORD | sha256sum)" > /winston/user.profile
sudo chmod 700 /winston/user.profile
sudo chown $user /winston/user.profile
clear
exit 0
