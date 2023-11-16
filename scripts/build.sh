#!/bin/bash

REPOROOT="/tmp/gitfiler"

getsetting() {
	gawk '/^'"$2"'/ { print gensub(/^'"$2"'[ \t]+(.*)$/,"\\1","g",$0); }' $1
}

if [ ! -d /tmp/gitfiler ]; then
    mkdir $REPOROOT

	git clone https://github.com/bng44270/gitfiler.git /tmp/gitfiler
fi

mkdir $REPOROOT/tmp
cat <<HERE > $REPOROOT/tmp/settings
NEWPATH $1
WEBPORT $2
SSHPORT $3
CERTFILE $4
KEYFILE $5
HERE

if [ ! -d $REPOROOT/build ]; then
    make -C $REPOROOT
fi


GITPATH="$(getsetting $REPOROOT/tmp/settings NEWPATH)"

if [ ! -d $GITPATH ]; then
    mkdir -p $GITPATH
fi
