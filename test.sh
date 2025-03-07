#!/bin/bash

password=$(cat /winston/user.profile | grep password | awk {'print $2'})
echo $password

read -sp "password: " pass
pass1=$(echo -n $pass | sha256sum | awk {'print $1'})
echo $pass1

if [[ $pass1 = $password ]]; then
    echo "good"
elif ! [[ $pass1 = $password ]]; then
    echo "no good"
else
    echo "I don't understand"
fi
