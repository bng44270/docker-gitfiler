#!/bin/bash

REPOROOT="/tmp/gitfiler"

getsetting() {
	gawk '/^'"$2"'/ { print gensub(/^'"$2"'[ \t]+(.*)$/,"\\1","g",$0); }' $1
}

if [ ! -f /etc/dropbear/run.orig ]; then
	mv /etc/dropbear/run /etc/dropbear/run.orig

	sed "s|SSHPORT|$(getsetting $REPOROOT/tmp/settings SSHPORT)|g" <<HERE > /etc/dropbear/run
#!/bin/sh
exec 2>&1
ROOT="\$(dirname \$0)"
exec dropbear \
    -r \$ROOT/dropbear_rsa_host_key \
    -r \$ROOT/dropbear_ecdsa_host_key \
    -r \$ROOT/dropbear_ed25519_host_key \
    -E -p SSHPORT -P \$ROOT/dropbear.PID
HERE

	chmod +x /etc/dropbear/run
fi
