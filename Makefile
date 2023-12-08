SHELL := /bin/bash

define newsetting
@read -p "$(1) [$(3)]: " thisset ; [[ -z "$$thisset" ]] && echo "$(2) $(3)" >> $(4) || echo "$(2) $$thisset" | sed 's/\/$$//g' >> $(4)
endef

define getsetting
$$(grep "^$(2)[ \t]*" $(1) | sed 's/^$(2)[ \t]*//g')
endef

define certkeyval
@(test -n "$(call getsetting,tmp/settings,KEYFILE)" && test -n "$(call getsetting,tmp/settings,CERTFILE)" && test -f $(call getsetting,tmp/settings,KEYFILE) && test -f $(call getsetting,tmp/settings,CERTFILE) && test "$$(openssl rsa -modulus -noout -in $(call getsetting,tmp/settings,KEYFILE))" = "$$(openssl x509 -modulus -noout -in $(call getsetting,tmp/settings,CERTFILE))" && echo "Verified cert/key pair") || (echo "Error verifying cert/key pair"; exit 1)
endef

define packagerepos
@(test -n "$(call getsetting,tmp/settings,CONTENTPATH)" && echo "Packaging Repository Data" && pushd . > /dev/null && cd $(call getsetting,tmp/settings,CONTENTPATH) && zip -qr repo_content.zip . && popd > /dev/null && mv $(call getsetting,tmp/settings,CONTENTPATH)/repo_content.zip .) || echo "Skipping copying local repositories"
endef

ISDEBIAN := $(shell awk '/^NAME=.*[Dd]ebian/ { print "Yes" }' /etc/*release*)

all: 
	@echo "usage:  make <conf | build>"

ifneq ($(ISDEBIAN),Yes)
	$(error Debian is required to build)
endif

build: refresh
	sudo -v
	$(if $(shell sudo docker image ls | grep '$(1)'),$(error Docker image $(1) exists.  Remove image and assocciated container(s) and retry make build.),)
	sudo docker build -t gitfiler .

conf : tmp/settings
	$(call certkeyval)
	$(call packagerepos)
	@printf "Building Dockerfile..."
	@m4 -DPATHVAR="ENV makenewpath=$(call getsetting,tmp/settings,NEWPATH)" -DWEBPORTVAR="ENV makewebport=$(call getsetting,tmp/settings,WEBPORT)" -DSSHPORTVAR="ENV makesshport=$(call getsetting,tmp/settings,SSHPORT)" -DCOPYCONTENT="$$((test -f ./repo_content.zip && printf "COPY repo_content.zip /tmp") || echo "")" -DCERTFILE="ENV certfile=$(call getsetting,tmp/settings,CERTFILE)" -DKEYFILE="ENV keyfile=$(call getsetting,tmp/settings,KEYFILE)" Dockerfile.m4 > Dockerfile
	@printf "done\n"

tmp/settings: tmp
	$(call newsetting,Enter local path (where repositories are),NEWPATH,/tmp,tmp/settings)
	$(call newsetting,Enter web port,WEBPORT,8443,tmp/settings)
	$(call newsetting,Enter SSH port,SSHPORT,22,tmp/settings)
	$(call newsetting,Enter SSL Key file,KEYFILE,,tmp/settings)
	$(call newsetting,Enter SSL Cert file,CERTFILE,,tmp/settings)
	$(call newsetting,Enter path containing existing repositories (leave empty to skip),CONTENTPATH,,tmp/settings)

tmp:
	@[[ ! -d tmp ]] && mkdir tmp || echo "tmp folder already exists"

clean:
	rm -rf tmp
	rm Dockerfile
	@(test -f repo_content.zip && rm repo_content.zip && echo "rm repo_content.zip") || echo "Skipping rm repo_content.zip"
