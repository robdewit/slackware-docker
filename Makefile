LATEST		:= 14.2
VERSION		:= $(LATEST)
VERSIONS	:= 13.37 14.0 14.1 14.2 current
NAME		:= slackware
MIRROR		:= http://slackware.osuosl.org
ifdef ARCH
SYSARCH		:= $(ARCH)
else
SYSARCH		:= $(shell uname -m)
endif
ifeq ($(SYSARCH),x86_64)
SLACKARCH := 64
else ifeq ($(patsubst i%86,x86,$(SYSARCH)),x86)
SLACKARCH :=
else ifeq ($(SYSARCH),armv6l)
SLACKARCH := arm
else ifeq ($(SYSARCH),aarch64)
SLACKARCH := arm64
else
SLACKARCH := 64
endif
ifndef TMP
TMP		:= /tmp
endif
RELEASENAME	:= slackware$(SLACKARCH)
RELEASE		:= $(RELEASENAME)-$(VERSION)
CACHEFS		:= $(TMP)/$(NAME)/$(RELEASE)
ROOTFS		:= $(TMP)/rootfs-$(RELEASE)
#CRT		?= podman
CRT		?= docker

image: $(RELEASENAME)-$(LATEST).tar

arch:
	@echo $(SLACKARCH)
	@echo $(RELEASE)

$(RELEASENAME)-%.tar: mkimage-slackware.sh
	sudo \
		TMP=$(TMP) \
		VERSION="$*" \
		USER="$(USER)" \
		BUILD_NAME="$(NAME)" \
		bash $<

all: mkimage-slackware.sh
	TMP=$(TMP); \
	for version in $(VERSIONS) ; do \
		$(MAKE) $(RELEASENAME)-$${version}.tar && \
		$(MAKE) VERSION=$${version} clean && \
		$(CRT) import -c 'CMD ["/bin/sh"]' $(RELEASENAME)-$${version}.tar $(USER)/$(NAME):$${version} && \
		$(CRT) run -i --rm $(USER)/$(NAME):$${version} /usr/bin/echo "$(USER)/$(NAME):$${version} :: Success." ; \
	done && \
	$(CRT) tag $(USER)/$(NAME):$(LATEST) $(USER)/$(NAME):latest

.PHONY: umount
umount:
	@sudo umount $(ROOTFS)/cdrom || :
	@sudo umount $(ROOTFS)/dev || :
	@sudo umount $(ROOTFS)/sys || :
	@sudo umount $(ROOTFS)/proc || :
	@sudo umount $(ROOTFS)/etc/resolv.conf || :

.PHONY: clean
clean: umount
	sudo rm -rf $(ROOTFS) $(CACHEFS)/paths

.PHONY: dist-clean
dist-clean: clean
	sudo rm -rf $(CACHEFS)

