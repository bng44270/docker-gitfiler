#!/bin/bash

REPOROOT="/tmp/gitfiler"

getsetting() {
	gawk '/^'"$2"'/ { print gensub(/^'"$2"'[ \t]+(.*)$/,"\\1","g",$0); }' $1
}

umask 007
unzip /tmp/repo_content.zip -d $(getsetting $REPOROOT/tmp/settings NEWPATH)
