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
    sudo mkdir /winston/
    sudo chmod 700 /winston/
    sudo chown $user /winston/
fi
if ! sudo ls "/winston/$USERNAME"; then
    sudo mkdir /winston/$USERNAME/
    sudo chmod 700 /winston/$USERNAME/
    sudo chown $user /winston/$USERNAME/
fi
if ! sudo ls "/winston/kenel"; then
    sudo mkdir /winston/kenel/
    sudo chmod 700 /winston/kenel/
    sudo chown $(whoami) /winston/kenel
fi

echo "username: $USERNAME
full name: $FULLNAME
password: $(echo -n $PASSWORD | sha256sum | awk {'print $1'})" > /winston/$USERNAME/user.profile
sudo chmod 600 /winston/$USERNAME/user.profile
sudo chown $user /winston/$USERNAME/user.profile
clear
exit 0
