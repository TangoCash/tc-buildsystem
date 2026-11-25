################################################################################
#
# openhbbtvbrowser update: the HbbTV browser with Qt as update package (.bin)
#
################################################################################

# the browser, its neutrino plugin and what Qt needs at run time; QML is
# left out, the browser is a widgets application
OPENHBBTVBROWSER_UPDATE_FILES = \
	$(bindir)/openhbbtvbrowser \
	$(sysconfdir)/openhbbtvbrowser \
	$(datadir)/tuxbox/neutrino/plugins/hbbtv.lua \
	$(datadir)/tuxbox/neutrino/plugins/hbbtv.cfg \
	$(libdir)/qt/plugins \
	$(libexecdir)/QtWebEngineProcess \
	$(prefix)/resources \
	$(prefix)/translations/qtwebengine_locales

# libraries chromium dlopen()s, so no NEEDED entry names them
OPENHBBTVBROWSER_UPDATE_DLOPEN = \
	libudev.so.1 \
	libsoftokn3.so libfreebl3.so libfreeblpriv3.so libnssckbi.so libnssdbm3.so

# libraries every image has: those neutrino needs, the toolchain's in /lib,
# and the GL driver of the box (blobs)
OPENHBBTVBROWSER_UPDATE_IN_IMAGE = $(BUILD_DIR)/openhbbtvbrowser-update.image-libs
OPENHBBTVBROWSER_UPDATE_LIBS = $(BUILD_DIR)/openhbbtvbrowser-update.libs
OPENHBBTVBROWSER_UPDATE_GL_LIBS = '/lib(EGL|GLES|Mali|mali|gbm|nexus|nxpl|v3ddriver)'

define OPENHBBTVBROWSER_UPDATE_SCRIPTS
	echo "killall openhbbtvbrowser 2>/dev/null; sleep 1"	>> $(PREINSTALL_SH)
	echo "wget -q -O /dev/null http://localhost/control/reloadplugins"	>> $(POSTINSTALL_SH)
	echo "wget -q -O /dev/null 'http://localhost/control/message?popup=HbbTV-Browser%20installiert.'"	>> $(POSTINSTALL_SH)
endef

define OPENHBBTVBROWSER_UPDATE_COLLECT
	$(CD) $(TARGET_DIR); \
		for f in $(OPENHBBTVBROWSER_UPDATE_FILES); do \
			cp -a --parents .$$f $(UPDATE_INST_DIR); \
		done
	$(SUPPORT_DIR)/scripts/elf-libs.sh $(TARGET_READELF) $(TARGET_DIR) \
		$(TARGET_bindir)/neutrino > $(OPENHBBTVBROWSER_UPDATE_IN_IMAGE)
	$(CD) $(TARGET_DIR); \
		dlopen=""; \
		for n in $(OPENHBBTVBROWSER_UPDATE_DLOPEN); do \
			test -e .$(libdir)/$$n && dlopen="$$dlopen $(libdir)/$$n"; \
		done; \
		{ \
			for l in $$dlopen; do echo $$l; done; \
			$(SUPPORT_DIR)/scripts/elf-libs.sh $(TARGET_READELF) . \
				.$(bindir)/openhbbtvbrowser .$(libexecdir)/QtWebEngineProcess \
				$$(find .$(libdir)/qt/plugins -name '*.so') \
				$$(for l in $$dlopen; do echo .$$l; done); \
		} | sort -u \
			| grep -vxF -f $(OPENHBBTVBROWSER_UPDATE_IN_IMAGE) \
			| grep -v '^$(base_libdir)/' \
			| grep -vE $(OPENHBBTVBROWSER_UPDATE_GL_LIBS) \
			> $(OPENHBBTVBROWSER_UPDATE_LIBS)
	$(CD) $(TARGET_DIR); \
		while read l; do \
			cp -a --parents .$$l $(UPDATE_INST_DIR); \
			cp -a --parents ./$$(realpath --relative-to=. .$$l) $(UPDATE_INST_DIR); \
		done < $(OPENHBBTVBROWSER_UPDATE_LIBS)
	@$(call MESSAGE,"Libraries: $$(tr '\n' ' ' < $(OPENHBBTVBROWSER_UPDATE_LIBS))")
	rm -f $(OPENHBBTVBROWSER_UPDATE_IN_IMAGE) $(OPENHBBTVBROWSER_UPDATE_LIBS)
endef

openhbbtvbrowser-update:
	$(MAKE) neutrino openhbbtvbrowser
	$(MAKE) u-init
	$(OPENHBBTVBROWSER_UPDATE_SCRIPTS)
	$(OPENHBBTVBROWSER_UPDATE_COLLECT)
	$(MAKE) strip STRIP_DIR=$(UPDATE_INST_DIR)
	find $(UPDATE_INST_DIR) -type d -empty -delete
	@$(call MESSAGE,"Update content: $$(du -sh $(UPDATE_INST_DIR) | cut -f1)")
	$(MAKE) u-update-bin \
			UPDATE_TYPE=A \
			UPDATE_DATE=$(shell date +%Y%m%d%H%M) \
			UPDATE_MD5FILE=$(UPDATE_MD5FILE_BOXMODEL) \
			UPDATE_NAME=$(IMAGE_NAME)-openhbbtvbrowser \
			UPDATE_DESC='"HbbTV-Browser [$(BOXTYPE_SC)][$(BOXMODEL)] Addon"'

PHONY += openhbbtvbrowser-update
