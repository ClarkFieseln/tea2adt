#!/bin/bash

# ask for password
while true
do
    while true
    do
        echo -n "password: "
        read -ers PASSWORD1
        echo ""
        # 2> /dev/null shall prevent showing the password if some error occurs
        if [ ! "${PASSWORD1}" == "" ] 2> /dev/null
        then
            break
        else
            echo "Password cannot be empty!"
        fi
    done
    echo -n "confirm password: "
    read -ers PASSWORD
    echo ""
    # 2> /dev/null shall prevent showing the password if some error occurs
    [ "${PASSWORD1}" == "${PASSWORD}" ] 2> /dev/null && break
    echo "Passwords dont match!"
done

# RX
source rx.src | python3 mmrx.py "${PASSWORD}" $1
