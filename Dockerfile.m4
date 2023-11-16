FROM debian:latest

PATHVAR
WEBPORTVAR
SSHPORTVAR
CERTFILE
KEYFILE

RUN apt-get update
RUN apt-get install -y dropbear git make m4 python3 python3-pip python3-git python3-full gawk acl
RUN pip3 install --break-system-packages flask
RUN mkdir -p /tmp/scripts
COPY scripts/* /tmp/scripts/
RUN chmod +x /tmp/scripts/*

# Create git-users group
RUN /tmp/scripts/group.sh

# Build Gitfiler and create Git root
RUN /tmp/scripts/build.sh "$makenewpath" "$makewebport" "$makesshport" "$certfile" "$keyfile"

# Configure dropbear ssh server
RUN /tmp/scripts/sshconf.sh

COPYCONTENT

ENTRYPOINT ["/tmp/scripts/startup.sh"]
