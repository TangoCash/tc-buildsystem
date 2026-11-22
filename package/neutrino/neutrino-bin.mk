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

ifneq ($(DEBUG),yes)
define NEUTRINO_BIN_STRIP
	$(TARGET_STRIP) $(TARGET_bindir)/neutrino
endef
NEUTRINO_BIN_TARGET_FINALIZE_HOOKS += NEUTRINO_BIN_STRIP

# the rootfs-strip target only runs for full image builds; make sure every
# build of neutrino-bin leaves a fully stripped install tree (same recipe and
# exclusions as target-rootfs.mk, applied to $(TARGET_DIR))
define NEUTRINO_BIN_STRIP_ROOTFS
	@echo "Stripping installed binaries and libraries";
	for dir in $(base_bindir) $(base_sbindir) $(bindir) $(sbindir) $(libexecdir) /usr/share/tuxbox/neutrino/plugins; do \
		$(INSTALL) -d $(TARGET_DIR)$${dir}; \
		find $(TARGET_DIR)$${dir} \
			-type f -print0 | xargs -n 128 -0 $(TARGET_STRIP) || true; \
	done
	for dir in $(base_libdir) $(libdir); do \
		$(INSTALL) -d $(TARGET_DIR)$${dir}; \
		find $(TARGET_DIR)$${dir} \( \
				-path $(TARGET_DIR)/lib/libnexus.so -o \
				-path $(TARGET_DIR)/lib/libnxpl.so -o \
				-path $(TARGET_DIR)/lib/libv3ddriver.so -o \
				\
				-path $(TARGET_DIR)/lib/modules \) -prune -o \
			-type f -print0 | xargs -n 128 -0 $(TARGET_STRIP) || true; \
	done
endef
NEUTRINO_BIN_TARGET_FINALIZE_HOOKS += NEUTRINO_BIN_STRIP_ROOTFS
endif

neutrino-bin: | $(TARGET_DIR)
	$(call virtual-package,$(PKG_NO_TOUCH))
