################################################################################
#
# sysconfdir
#
################################################################################

SYSCONFDIR_FILES_DIR = $(PACKAGE_DIR)/sysconfdir/files

$(TARGET_sysconfdir)/date-dummy:
	echo "$(shell date +%Y)01010000" > $(@)

$(TARGET_sysconfdir)/filesystems:
	$(INSTALL_DATA) -D $(SYSCONFDIR_FILES_DIR)/filesystems $(@)

$(TARGET_sysconfdir)/fstab:
	$(INSTALL_DATA) -D $(SYSCONFDIR_FILES_DIR)/fstab $(@)

$(TARGET_sysconfdir)/group:
	$(INSTALL_DATA) -D $(SYSCONFDIR_FILES_DIR)/group $(@)

# the box model as default hostname; hostname.init would otherwise build
# it from the MAC address with ifconfig eth0, which hangs on some boxes
# early in rcS (seen on the hd60)
$(TARGET_sysconfdir)/hostname:
ifeq ($(PERSISTENT_VAR_PARTITION),yes)
	$(INSTALL) -d $(TARGET_localstatedir)/etc
	echo $(BOXMODEL) > $(TARGET_localstatedir)/etc/hostname
else
	$(INSTALL) -d $(dir $(@))
	echo $(BOXMODEL) > $(@)
endif

$(TARGET_sysconfdir)/hosts:
	$(INSTALL_DATA) -D $(SYSCONFDIR_FILES_DIR)/hosts $(@)

$(TARGET_sysconfdir)/issue.net:
	$(INSTALL_DATA) -D $(SYSCONFDIR_FILES_DIR)/issue.net $(@)

$(TARGET_sysconfdir)/model:
	echo $(BOXMODEL) > $(@)

$(TARGET_sysconfdir)/nsswitch.conf:
	$(INSTALL_DATA) -D $(SYSCONFDIR_FILES_DIR)/nsswitch.conf $(@)

$(TARGET_sysconfdir)/passwd:
ifeq ($(PERSISTENT_VAR_PARTITION),yes)
	$(INSTALL_DATA) -D $(SYSCONFDIR_FILES_DIR)/passwd $(TARGET_localstatedir)/etc/passwd
	ln -sf /var/etc/passwd $(@)
else
	$(INSTALL_DATA) -D $(SYSCONFDIR_FILES_DIR)/passwd $(@)
endif

$(TARGET_sysconfdir)/profile:
	$(INSTALL_DATA) -D $(SYSCONFDIR_FILES_DIR)/profile $(@)

$(TARGET_sysconfdir)/profile.local:
ifeq ($(PERSISTENT_VAR_PARTITION),yes)
	$(INSTALL_DATA) -D $(SYSCONFDIR_FILES_DIR)/profile.local-var $(TARGET_localstatedir)/etc/profile.local
endif
	$(INSTALL_DATA) -D $(SYSCONFDIR_FILES_DIR)/profile.local $(@)

$(TARGET_sysconfdir)/profile.d:
	$(foreach p,$(wildcard $(SYSCONFDIR_FILES_DIR)/profile.d/*.sh),\
		$(INSTALL_DATA) -D $(p) $(TARGET_sysconfdir)/profile.d/$(notdir $(p))$(sep))

PHONY += $(TARGET_sysconfdir)/profile.d

$(TARGET_sysconfdir)/protocols:
	$(INSTALL_DATA) -D $(SYSCONFDIR_FILES_DIR)/protocols $(@)

$(TARGET_sysconfdir)/services:
	$(INSTALL_DATA) -D $(SYSCONFDIR_FILES_DIR)/services $(@)

$(TARGET_localstatedir)/etc/fstab:
	$(INSTALL_DATA) -D $(SYSCONFDIR_FILES_DIR)/fstab-var $(@)

# -----------------------------------------------------------------------------

SYSCONFDIR_DEPENDENCIES = \
	$(TARGET_sysconfdir)/date-dummy \
	$(TARGET_sysconfdir)/filesystems \
	$(TARGET_sysconfdir)/fstab \
	$(TARGET_sysconfdir)/group \
	$(TARGET_sysconfdir)/hostname \
	$(TARGET_sysconfdir)/hosts \
	$(TARGET_sysconfdir)/issue.net \
	$(TARGET_sysconfdir)/model \
	$(TARGET_sysconfdir)/nsswitch.conf \
	$(TARGET_sysconfdir)/passwd \
	$(TARGET_sysconfdir)/profile \
	$(TARGET_sysconfdir)/profile.local \
	$(TARGET_sysconfdir)/profile.d \
	$(TARGET_sysconfdir)/protocols \
	$(TARGET_sysconfdir)/services \
	\
	$(TARGET_localstatedir)/etc/fstab

sysconfdir: | $(TARGET_DIR)
	$(call virtual-package)
