FROM debian:latest

PATHVAR
WEBPORTVAR
SSHPORTVAR
CERTFILE
KEYFILE

RUN apt-get update
RUN apt-get install -y dropbear git make m4 python3 python3-pip python3-git python3-full gawk acl unzip
RUN pip3 install --break-system-packages flask
RUN mkdir -p /tmp/scripts
COPY scripts/* /tmp/scripts/
RUN chmod +x /tmp/scripts/*

# Copy SSL Key/Cert
COPY $certfile /tmp
COPY $keyfile /tmp

# Create git-users group
RUN /tmp/scripts/group.sh

# Build Gitfiler and create Git root
RUN /tmp/scripts/build.sh "$makenewpath" "$makewebport" "$makesshport" "/tmp/$certfile" "/tmp/$keyfile"

# Configure dropbear ssh server
RUN /tmp/scripts/sshconf.sh

COPYCONTENT
RUN (test -f /tmp/repo_contents.zip && /tmp/scripts/extract.sh) || echo "No repository content found"

ENTRYPOINT ["/tmp/scripts/startup.sh"]
