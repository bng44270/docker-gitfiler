SHELL := /bin/bash

define newsetting
@read -p "$(1) [$(3)]: " thisset ; [[ -z "$$thisset" ]] && echo "$(2) $(3)" >> $(4) || echo "$(2) $$thisset" | sed 's/\/$$//g' >> $(4)
endef

define getsetting
$$(grep "^$(2)[ \t]*" $(1) | sed 's/^$(2)[ \t]*//g')
endef

ISDEBIAN := $(shell awk '/^NAME=.*[Dd]ebian/ { print "Yes" }' /etc/*release*)

all: 
	@echo "usage:  make <conf | build>"

ifneq ($(ISDEBIAN),Yes)
	$(error Debian is required to build)
endif

build:
	sudo -v
	sudo docker build -t gitfiler .

conf : tmp/settings
	@printf "Building Dockerfile..."
	@m4 -DPATHVAR="ENV makenewpath=$(call getsetting,tmp/settings,NEWPATH)" -DWEBPORTVAR="ENV makewebport=$(call getsetting,tmp/settings,WEBPORT)" -DSSHPORTVAR="ENV makesshport=$(call getsetting,tmp/settings,SSHPORT)" -DCOPYCONTENT="$(call getsetting,tmp/settings,CONTENTPATH)" -DCERTFILE="ENV certfile=/tmp/$(call getsetting,tmp/settings,CERTFILE)" -DKEYFILE="ENV keyfile=/tmp/$(call getsetting,tmp/settings,CONTENTPATH)" Dockerfile.m4 > Dockerfile
	@printf "done\n"

tmp/settings: tmp
	$(call newsetting,Enter local path (where repositories are),NEWPATH,/tmp,tmp/settings)
	$(call newsetting,Enter web port,WEBPORT,8080,tmp/settings)
	$(call newsetting,Enter SSH port,SSHPORT,22,tmp/settings)
	$(call newsetting,Enter SSL Key file,KEYFILE,,tmp/settings)
	$(call newsetting,Enter SSL Cert file,CERTFILE,,tmp/settings)
	@(test -n "$(call getsetting,tmp/settings,CERTFILE)" && test -n "$(call getsetting,tmp/settings,KEYFILE)" && test -f $(call getsetting,tmp/settings,CERTFILE) && test -f $(call getsetting,tmp/settings,KEYFILE) && echo "Verified Cert/Key files") || test 1 -eq 0
	$(call newsetting,Enter path containing existing repositories (leave empty to skip),CONTENTPATH,,tmp/settings)
	@(grep '^CONTENTPATH[ \t]\+[^ \t]\+' tmp/settings > /dev/null && sed -i 's/^\(CONTENTPATH[ \t]\+\)\(.*\)$$/\1 COPY \2\/* '"$$(sed 's/\//\\\//g' <<< "$(call getsetting,tmp/settings,NEWPATH)")"'\//g' tmp/settings) || grep '^CONTENTPATH[ \t]*$$' tmp/settings

tmp:
	@[[ ! -d tmp ]] && mkdir tmp || echo "tmp folder already exists"

clean:
	rm -rf tmp
	rm Dockerfile
