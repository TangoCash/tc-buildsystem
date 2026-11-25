#
# makefile to build ni-images; just a collection of targets
#
# -----------------------------------------------------------------------------

# packages of the image, depending on the box; config.local may leave some
# out (BS_PACKAGES_SKIP, but not those of NI_IMAGE_REQUIRED) and add own ones
# (BS_PACKAGES_OWN); 'make print-image-packages' lists them (menuconfig)
NI_IMAGE_REQUIRED = kernel blobs neutrino busybox sysvinit autofs sysconfdir init-scripts

NI_IMAGE_PACKAGES = \
	neutrino-plugins \
	doscam-webif-skin \
	logo-addon \
	fbshot \
	chrony \
	tzdata \
	smartmontools \
	sg3_utils \
	nano \
	hd-idle \
	hdparm \
	nfs-utils \
	e2fsprogs \
	ntfs-3g \
	exfat-utils \
	dosfstools \
	mtd-utils \
	ushare \
	xupnpd \
	inadyn \
	samba \
	vsftpd \
	dropbear \
	busybox \
	sysvinit \
	coreutils \
	procps-ng \
	wpa_supplicant \
	wget \
	streamripper \
	lua-cjson
# djmount: not built (was "#make djmount")
ifeq ($(BOXSERIES),$(filter $(BOXSERIES),hd2 hd5x hd6x vusolo4k vuduo4k vuduo4kse vuultimo4k vuzero4k vuuno4k vuuno4kse vuduo))
NI_IMAGE_PACKAGES += \
	channellogos \
	fart \
	sl \
	jq \
	less \
	parted \
	openvpn \
	openssh \
	ethtool \
	f2fs-tools
  ifneq ($(BOXMODEL),kronos_v2)
NI_IMAGE_PACKAGES += \
	links \
	bash \
	iperf \
	minicom \
	minidlna \
	mc \
	dvbsnoop \
	dvb-apps
  endif
  ifeq ($(BOXSERIES),$(filter $(BOXSERIES),hd5x hd6x vusolo4k vuduo4k vuduo4kse vuultimo4k vuzero4k vuuno4k vuuno4kse vuduo))
NI_IMAGE_PACKAGES += \
	irqbalance \
	udpxy \
	evtest \
	gptfdisk \
	rsync \
	ofgwrite \
	aio-grab \
	minisatip \
	xfsprogs \
	libxslt \
	xz \
	sysstat \
	davfs2 \
	python3 \
	python-pip \
	python-streamlink \
	python-yt-dlp \
	openhbbtvbrowser
  endif
  ifeq ($(DEBUG),yes)
NI_IMAGE_PACKAGES += \
	strace \
	valgrind \
	gdb
  endif
endif

NI_IMAGE_BUILD = $(filter-out $(filter-out $(NI_IMAGE_REQUIRED),$(BS_PACKAGES_SKIP)),$(NI_IMAGE_PACKAGES))

image \
ni-image:
	@echo "starting 'make $(@)' build with "$(PARALLEL_JOBS)" threads!"
	$(MAKE) kernel
	$(MAKE) blobs
	$(MAKE) neutrino
	$(foreach p,$(NI_IMAGE_BUILD),$(MAKE) $(p)$(sep))
	$(MAKE) autofs
	$(MAKE) sysconfdir
	$(MAKE) init-scripts
ifneq ($(BS_PACKAGES_OWN),)
	$(MAKE) $(BS_PACKAGES_OWN)
endif
ifeq ($(PERSONALIZE),yes)
	$(MAKE) personalize
endif
	$(MAKE) rootfs
	$(MAKE) flash-image
	@$(MAKE) done

print-image-packages:
	@echo "required: $(NI_IMAGE_REQUIRED)"
	@echo "packages: $(NI_IMAGE_PACKAGES)"
	@echo "skip: $(BS_PACKAGES_SKIP)"
	@echo "own: $(BS_PACKAGES_OWN)"

# -----------------------------------------------------------------------------

IMAGES_BOXMODELS =
ifneq ($(DEBUG),yes)
  IMAGES_BOXMODELS += nevis
endif
IMAGES_BOXMODELS += apollo kronos kronos_v2
IMAGES_BOXMODELS += hd51 bre2ze4k h7
IMAGES_BOXMODELS += e4hdultra protek4k
IMAGES_BOXMODELS += hd60 hd61 multibox multiboxse
ifeq ($(BUILD_DAY),saturday)
  IMAGES_BOXMODELS += vusolo4k vuduo4k vuduo4kse vuultimo4k vuzero4k vuuno4k vuuno4kse
  #IMAGES_BOXMODELS += vuduo
endif

images \
ni-images:
	for boxmodel in $(IMAGES_BOXMODELS); do \
		$(MAKE) BOXMODEL=$${boxmodel} clean image || true; \
	done;
	$(MAKE) clean

personalized-image:
	$(MAKE) image PERSONALIZE=yes

# -----------------------------------------------------------------------------

PHONY += image ni-image
PHONY += print-image-packages
PHONY += images ni-images
PHONY += personalized-image
