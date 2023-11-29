#!/bin/bash

grep 'git-users' /etc/group
if [ $? -ne 0 ]; then
    groupadd git-users
fi

groups root | grep 'git-users' > /dev/null
if [ $? -ne 0 ]; then
    usermod -g git-users root
fi
