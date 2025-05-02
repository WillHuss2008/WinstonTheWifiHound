#!/bin/bash
clear

echo "WINSTON: HELLO."
echo "WINSTON: MY NAME IS WINSTON, THE WIFI HOUND."
echo "WINSTON: THIS IS THE SET-UP SCRIPT, SO WE'RE GOING TO SET UP YOUR PASSWORD, USERNAME, AND OTHER THINGS THAT'LL MAKE YOUR EXPERIENCE EASIER."
echo "WINSTON: LET'S START WITH THE BASICS."

# Check for required tools
echo "WINSTON: CHECKING FOR REQUIRED TOOLS..."
required_tools=("aircrack-ng" "screen" "iwconfig")
missing_tools=()

for tool in "${required_tools[@]}"; do
    if ! command -v $tool &> /dev/null; then
        missing_tools+=("$tool")
    fi
done

if [ ${#missing_tools[@]} -ne 0 ]; then
    echo "WINSTON: SOME REQUIRED TOOLS ARE MISSING:"
    for tool in "${missing_tools[@]}"; do
        echo "- $tool"
    done
    echo "WINSTON: PLEASE INSTALL THE MISSING TOOLS AND RUN THIS SCRIPT AGAIN."
    exit 1
fi

# User setup
while true; do
    echo "WINSTON: WHAT'S YOUR FULL NAME?"
    read -p "YOUR NAME: " FULLNAME
    echo "WIFI HOUND: YOUR NAME IS $FULLNAME. CORRECT?"
    read -p "YOU: " answer
    if [[ $answer = "yes" ]]; then
       break 
    elif ! [[ $answer = "yes" && $answer = "no" ]]; then
        clear
        echo "WINSTON: I'M SORRY, I COULDN'T UNDERSTAND. PLEASE TRY AGAIN."
    fi
done

clear
while true; do
    echo "WINSTON: WHAT WOULD YOU LIKE YOUR USERNAME TO BE?"
    read -p "YOUR USERNAME: " USERNAME
    echo "WINSTON: YOUR USERNAME IS $USERNAME. CORRECT?"
    read -p "YOU: " answer
    if [[ $answer = "yes" ]]; then
        break
    elif ! [[ $answer = "yes" && $answer = "no" ]]; then
        clear
        echo "WINSTON: I'M SORRY, I COULDN'T UNDERSTAND. PLEASE TRY AGAIN."
    fi
done

clear
while true; do
    echo "WINSTON: PLEASE ENTER THE PASSWORD YOU WOULD LIKE TO USE"
    read -sp "YOUR PASSWORD: " PASSWORD
    echo "WINSTON: PLEASE ENTER IT AGAIN TO DOUBLE CHECK IT."
    read -sp "YOUR PASSWORD: " PASSWORD1
    if [[ $PASSWORD = $PASSWORD1 ]]; then
        break
    else
        clear
        echo "WINSTON: YOUR PASSWORDS DON'T MATCH. PLEASE TRY AGAIN."
    fi
done

clear
echo "WINSTON: PLEASE WAIT WHILE WE SET UP YOUR WIFI HOUND"

# Create necessary directories and set permissions
user=$(whoami)
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
    sudo chown $user /winston/kenel
fi

# Create user profile
echo "username: $USERNAME
full name: $FULLNAME
password: $(echo -n $PASSWORD | sha256sum | awk {'print $1'})" > /winston/$USERNAME/user.profile
sudo chmod 600 /winston/$USERNAME/user.profile
sudo chown $user /winston/$USERNAME/user.profile

# Create default wordlist if it doesn't exist
if [ ! -f "/winston/kenel/wordlist.txt" ]; then
    echo "WINSTON: CREATING DEFAULT WORDLIST..."
    # Add some common passwords to the wordlist
    echo "password
123456
admin
welcome
qwerty" > /winston/kenel/wordlist.txt
    sudo chmod 600 /winston/kenel/wordlist.txt
    sudo chown $user /winston/kenel/wordlist.txt
fi

# Make scripts executable
chmod +x Wifi_Hound_Script.sh
chmod +x password_manager.sh
chmod +x capture.sh
chmod +x deauth.sh

clear
echo "WINSTON: SETUP COMPLETE!"
echo "WINSTON: TO START USING WIFI HOUND, RUN: ./Wifi_Hound_Script.sh"
echo "WINSTON: AVAILABLE COMMANDS:"
echo "- ./Wifi_Hound_Script.sh : Start the main program"
echo "- ./password_manager.sh list : View stored passwords"
echo "- ./password_manager.sh search <term> : Search for specific networks"
echo "WINSTON: REMEMBER TO RUN THESE COMMANDS WITH SUDO PRIVILEGES!"
exit 0
