#!/bin/bash

REPOROOT="/tmp/gitfiler"

getsetting() {
	gawk '/^'"$2"'/ { print gensub(/^'"$2"'[ \t]+(.*)$/,"\\1","g",$0); }' $1
}

unzip /tmp/repo_content.zip -d $(getsetting $REPOROOT/tmp/settings NEWPATH)

chgrp -R git-users $(getsetting $REPOROOT/tmp/settings NEWPATH)
chown -R root $(getsetting $REPOROOT/tmp/settings NEWPATH)
chmod -R 770 $(getsetting $REPOROOT/tmp/settings NEWPATH)