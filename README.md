# NI \o/ - Neutrino-Images Buildsystem #

## Für die Einrichtung unter Debian sind folgende Pakete nötig
```bash
apt-get install git subversion mercurial cvs
```
```bash
apt-get install curl wget
```
```bash
apt-get install tar lzma zip unzip bzip2 gzip xz-utils
```
```bash
apt-get install gawk grep sed findutils bc ncurses-bin
```
```bash
apt-get install build-essential ccache automake autoconf libtool libtool-bin
```
```bash
apt-get install patch pkg-config gettext autopoint intltool gtk-doc-tools
```
```bash
apt-get install gperf bison help2man texinfo flex libncurses-dev
```
```bash
apt-get install libltdl-dev libglib2.0-dev libssl-dev libcurl4-openssl-dev

```

Zusätzlich für QtWebEngine (openhbbtvbrowser): ein 32-Bit-fähiger
Host-Compiler für den V8-Snapshot von 32-Bit-ARM
```bash
apt-get install g++-multilib
```

Für das Konfigurationsmenü (`make menuconfig`)
```bash
apt-get install whiptail
```

## 1) Buildsystem initialisieren
```bash
git clone https://github.com/TangoCash/tc-buildsystem.git
```
```bash
cd tc-buildsystem
```

## 2) Archivverzeichnis erstellen
```bash
mkdir -p $HOME/archives
```
```bash
ln -s $HOME/archives download
```

## 3) Buildsystem konfigurieren
```bash
make local-files
```
config.local auf die eigenen Bedürfnisse anpassen. BOXMODEL **muss** gesetzt werden!

Alternativ im Menü (benötigt whiptail): BOXMODEL, Flavour, Optionen, Plugins
und die Pakete des Images (abwählen oder eigene hinzufügen)
```bash
make menuconfig
```

## 4) Buildumgebung prüfen
```bash
make toolcheck
```

## 5) Buildsystem initialisieren und Toolchain bauen
```bash
make init
```

## 6) Image(s) bauen
```bash
make image
```
oder
```bash
make images
```

## 7) Aktualisieren und aufräumen
```bash
make update
```
```bash
make clean
```
