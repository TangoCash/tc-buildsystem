# make/menuconfig.mk
# Interaktives Konfigurationsmenü für config.local via whiptail

PHONY += menuconfig

menuconfig:
	@if ! command -v whiptail >/dev/null 2>&1; then \
		echo "Fehler: 'whiptail' ist nicht installiert (sudo apt-get install whiptail)."; \
		exit 1; \
	fi
	@if [ ! -f config.local ]; then \
		echo "config.local nicht gefunden – führe 'make local-files' aus..."; \
		$(MAKE) local-files; \
	fi
	@bash support/menuconfig.sh
