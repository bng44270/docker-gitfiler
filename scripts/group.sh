#!/bin/bash

grep 'git-users' /etc/group
if [ $? -ne 0 ]; then
    groupadd git-users
fi