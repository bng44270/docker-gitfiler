#!/bin/bash

REPOROOT="/tmp/gitfiler"

getsetting() {
	gawk '/^'"$2"'/ { print gensub(/^'"$2"'[ \t]+(.*)$/,"\\1","g",$0); }' $1
}

if [ ! -f /tmp/functions ]; then
	read -p "Enter password length [10]: " PASSLEN
	[[ -z "$PASSLEN" ]] && PASSLEN="10"

	cat <<HERE > /tmp/functions.inc.sh
#####################
# Setting default file mode (u=rwx,g=rwx,o=)
#####################
umask 007

######################
# General Functions
######################
randompass () {
        [[ -z "\$1" ]] && echo "usage: randompass <password-length>" || echo "\$(cat /dev/urandom | tr -dc 'a-z' | head -c\$1) \$(cat /dev/urandom | tr -dc 'A-Z' | head -c\$1) \$(cat /dev/urandom | tr -dc '0-9' | head -c\$1) \$(for dash in \$(seq 0 \$[\$1/10]); do echo "-" ; done)" | sed 's/[ \t]//g' | fold -w1 | shuf | tr -d '\n' | head -c\$1
}

######################
# ServerFunctions
######################
sshserver() {
	if [ "\$1" == "start" ]; then
		if [ -f /etc/dropbear/dropbear.PID ]; then
			echo "Dropbear already running (\$(cat /etc/dropbear/dropbear.PID))"
		else
			/etc/dropbear/run
		fi
	elif [ "\$1" == "stop" ]; then
		if [ -f /etc/dropbear/dropbear.PID ]; then
			kill -9 \$(cat /etc/dropbear/dropbear.PID)
		else
			echo "Dropbear is not running"
		fi
	elif [ "\$1" == "restart" ]; then
		if [ -f /etc/dropbear/dropbear.PID ]; then
			sshserver stop
			sshserver start
		else
			sshserver start
		fi
	elif [ "\$1" == "status" ]; then
		if [ -f /etc/dropbear/dropbear.PID ]; then
			echo "Dropbear is currently running (\$(cat /etc/dropbear/dropbear.PID))"
		else
			echo "Dropbear is not currently running"
		fi
	else
		echo "usage: sshserver <start | stop | restart | status>"
	fi
}

gitfiler() {
	if [ "\$1" == "start" ]; then
		if [ -f /tmp/gitfiler.PID ]; then
			echo "Gitfiler already running (\$(cat /tmp/gitfiler.PID))"
		else
			pushd .
			cd /tmp/gitfiler/build
			/usr/bin/python3 gitfiler.py 2>&1 > gitfiler.log &
			echo "\$!" > /tmp/gitfiler.PID
			popd
		fi
	elif [ "\$1" == "stop" ]; then
		if [ -f /tmp/gitfiler.PID ]; then
			kill -9 \$(cat /tmp/gitfiler.PID)
		else
			echo "Gitfiler is not running"
		fi
	elif [ "\$1" == "restart" ]; then
		if [ -f /tmp/gitfiler.PID ]; then
			gitfiler stop
			gitfiler start
		else
			gitfiler start
		fi
	elif [ "\$1" == "status" ]; then
		if [ -f /tmp/gitfiler.PID ]; then
			echo "Gitfiler is currently running (\$(cat /tmp/gitfiler.PID))"
		else
			echo "Gitfiler is not currently running"
		fi
	else
		echo "usage: gitfiler <start | stop | restart | status>"
	fi
}

userutil() {
	if [ "\$1" == "add" ] || [ "\$1" == "reset" ]; then
		[[ "\$1" == "add" ]] && useradd -G git-users \$2
		NEWPASS="\$(randompass $PASSLEN)"
		chpasswd <<< "\$2:\$NEWPASS"
		echo "Username: \$2"
		echo "Password: \$NEWPASS"
	elif [ "\$1" == "delete" ]; then
		userdel \$2
		[[ \$? -eq 0 ]] && echo "User \$2 Deleted" || echo "Error Deleting User \$2"
	else
		echo "usage: userutil <add | delete | reset>"
	fi
}

complete -W "start stop restart status" sshserver
complete -W "start stop restart status" gitfiler
complete -W "add reset delete" userutil

echo "###########################"
echo "#  Gitfiler Docker Usage  #"
echo "###########################"
echo " Commands:"
echo "      sshserver <start | stop | restart | status>"
echo "            Manage SSH server process"
echo ""
echo "      gitfiler <start | stop | restart | status>"
echo "             Manage Gitfiler web server process"
echo ""
echo "      userutil <add | reset | delete>"
echo "             Manage users on Gitfiler server"
echo ""
HERE
fi

bash --rcfile /tmp/functions.inc.sh
