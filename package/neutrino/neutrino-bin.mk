################################################################################
#
# neutrino-bin
#
################################################################################

NEUTRINO_BIN_DEPENDENCIES = libstb-hal-clean neutrino-clean

define NEUTRINO_BIN_BUILD
	$(MAKE) neutrino \
		LIBSTB_HAL_PKG_FLAGS="$(PKG_NO_DOWNLOAD)" \
		NEUTRINO_PKG_FLAGS="$(PKG_NO_DOWNLOAD) $(PKG_NO_INSTALL)"
endef
NEUTRINO_BIN_INDIVIDUAL_HOOKS += NEUTRINO_BIN_BUILD

define NEUTRINO_BIN_INSTALL
	$(INSTALL_EXEC) -D $(NEUTRINO_OBJ_DIR)/src/neutrino $(TARGET_bindir)/neutrino
endef
NEUTRINO_BIN_INDIVIDUAL_HOOKS += NEUTRINO_BIN_INSTALL

# $(TARGET_DIR) stays unstripped: later packages link against its libraries
# and static archives, and gdb wants the symbols. Every build of neutrino-bin
# leaves a clean, stripped copy of it in $(ROOTFS_DIR) (.build/rootfs, or
# its linuxrootfs1 with IMAGE_LAYOUT=subdirboot), made the way 'make rootfs'
# makes it: copy, rootfs-cleanup, rootfs-strip (no strip with DEBUG=yes)
define NEUTRINO_BIN_ROOTFS
	rm -rf $(ROOTFS_DIR)
	$(MAKE) rootfs-cleanup rootfs-strip
	@$(call MESSAGE,"Stripped copy of $(TARGET_DIR): $(ROOTFS_DIR)")
endef
NEUTRINO_BIN_TARGET_FINALIZE_HOOKS += NEUTRINO_BIN_ROOTFS

neutrino-bin: | $(TARGET_DIR)
	$(call virtual-package,$(PKG_NO_TOUCH))
