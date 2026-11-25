#!/bin/bash
#
# support/menuconfig.sh - whiptail menu for config.local
#
# Only the assignment lines in question are changed: an active assignment
# ("VAR = value", continuation lines included) is replaced, a commented
# template ("#VAR = value") stays as it is and the new line goes below it.
#

cd "$(dirname "$0")/.." || exit 1

CONFIG_FILE="config.local"
EXAMPLE_FILE="support/config.example"
PLUGINS_CONFIGURE="source/ni-neutrino-plugins/configure.ac"
PLUGINS_MK="package/neutrino-plugins/neutrino-plugins.mk"
TITLE="ni-buildsystem - $CONFIG_FILE"

[ -f "$CONFIG_FILE" ] || { echo "$CONFIG_FILE fehlt ('make local-files')"; exit 1; }

# -----------------------------------------------------------------------------

# cfg <get|set|unset|select> VAR [VALUE]
#  get    - value of the last active assignment, continuation lines joined
#  set    - VAR = VALUE; newlines in VALUE become continuation lines
#  unset  - drop the active assignments when a commented template is left,
#           else comment them out
#  select - comment out all active assignments, uncomment "#VAR = VALUE"
#           (BOXMODEL: one of the listed models)
cfg() {
	local tmp
	tmp=$(mktemp) || return 1
	CFG_VAR="$2" CFG_VAL="$3" awk -v mode="$1" '
	function span_end(i) {
		while (i < n && line[i] ~ /\\[ \t]*$/)
			i++
		return i
	}
	function block(v,   k, t, out) {
		k = split(v, t, "\n")
		if (k <= 1)
			return var " = " v
		out = var " = \\"
		for (j = 1; j <= k; j++)
			out = out "\n\t" t[j] (j < k ? " \\" : "")
		return out
	}
	BEGIN {
		var = ENVIRON["CFG_VAR"]; val = ENVIRON["CFG_VAL"]
		act = "^[ \t]*" var "[ \t]*[:?]?="
		com = "^#[ \t]*" var "[ \t]*[:?]?="
	}
	{ line[NR] = $0 }
	END {
		n = NR; nact = 0; lastcom = 0; pick = 0
		for (i = 1; i <= n; i++) {
			if (line[i] ~ act) {
				e = span_end(i); nact++; as[nact] = i; ae[nact] = e
				for (k = i; k <= e; k++) inact[k] = nact
				i = e
			} else if (line[i] ~ com) {
				lastcom = span_end(i)
				if (!pick) {
					v = line[i]; sub(com "[ \t]*", "", v); sub(/[ \t]+$/, "", v)
					if (v == val) pick = i
				}
				i = lastcom
			}
		}
		if (mode == "get") {
			if (!nact) exit 1
			v = ""
			for (k = as[nact]; k <= ae[nact]; k++) {
				l = line[k]
				if (k == as[nact]) sub(act, "", l)
				sub(/\\[ \t]*$/, "", l); gsub(/^[ \t]+|[ \t]+$/, "", l)
				if (l != "") v = (v == "" ? l : v " " l)
			}
			print v
			exit 0
		}
		for (i = 1; i <= n; i++) {
			if (i in inact) {
				b = inact[i]
				if (mode == "set") {
					if (b == 1 && i == as[1]) print block(val)
				} else if (mode == "select" || !lastcom) {
					print "#" line[i]
				}
			} else if (mode == "select" && i == pick) {
				l = line[i]; sub(/^#[ \t]*/, "", l); print l
			} else {
				print line[i]
			}
			if (i == lastcom && !nact && (mode == "set" || (mode == "select" && !pick)))
				print block(val)
		}
		if (!nact && !lastcom && (mode == "set" || mode == "select"))
			print "\n" block(val)
	}' "$CONFIG_FILE" > "$tmp"
	local rc=$?
	if [ "$1" = get ]; then
		cat "$tmp"
	elif [ $rc -eq 0 ]; then
		cat "$tmp" > "$CONFIG_FILE"
	fi
	rm -f "$tmp"
	return $rc
}

# default of a variable from the makefiles (the first "VAR ?= value")
mk_default() {
	grep -hE "^[[:space:]]*$1[[:space:]]*\?=" package/pkg-configuration.mk make/*.mk 2>/dev/null |
		head -n1 | sed -E "s/^[[:space:]]*$1[[:space:]]*\?=[[:space:]]*//"
}

# size of the terminal, read again for every dialog (it may be resized)
term_size() {
	local s
	s=$(stty size < /dev/tty 2>/dev/null)
	ROWS=${s% *}; COLS=${s#* }
	[[ "$ROWS" =~ ^[0-9]+$ ]] && [ "$ROWS" -gt 0 ] || ROWS=24
	[[ "$COLS" =~ ^[0-9]+$ ]] && [ "$COLS" -gt 0 ] || COLS=80
}

# dialog of fixed content: wt --inputbox|--msgbox|--textbox TEXT HEIGHT WIDTH ...
# (clamped to the terminal)
wt() {
	local kind=$1 text=$2 h=$3 w=$4
	shift 4
	term_size
	[ "$h" -gt $(( ROWS - 2 )) ] && h=$(( ROWS - 2 ))
	[ "$w" -gt $(( COLS - 4 )) ] && w=$(( COLS - 4 ))
	whiptail --title "$TITLE" "$kind" "$text" "$h" "$w" "$@" 3>&1 1>&2 2>&3
}

# list dialog sized to its entries and the terminal:
# wl --menu|--radiolist|--checklist TEXT ENTRY...
# (menu entries: tag description, the other two: tag description state)
wl() {
	local kind=$1 text=$2 stride=3 extra=16 i n tag=0 desc=0 tw=0 tl=0 l h w lh
	shift 2
	[ "$kind" = --menu ] && { stride=2; extra=10; }
	local a=("$@")
	n=$(( ${#a[@]} / stride ))
	for ((i = 0; i < ${#a[@]}; i += stride)); do
		[ ${#a[i]} -gt $tag ] && tag=${#a[i]}
		[ ${#a[i+1]} -gt $desc ] && desc=${#a[i+1]}
	done
	local lines=()
	mapfile -t lines < <(printf '%b\n' "$text")
	for l in "${lines[@]}"; do
		[ ${#l} -gt $tw ] && tw=${#l}
	done

	term_size
	w=$(( tag + desc + extra ))
	[ $(( tw + 6 )) -gt $w ] && w=$(( tw + 6 ))
	[ $w -lt 40 ] && w=40
	[ $w -gt $(( COLS - 4 )) ] && w=$(( COLS - 4 ))
	# text lines as whiptail wraps them (4 columns of frame and margin)
	for l in "${lines[@]}"; do
		tl=$(( tl + (${#l} + w - 5) / (w - 4) + (${#l} == 0) ))
	done
	# frame, title, text, blank line, buttons: 7 rows besides the text
	lh=$(( ROWS - 2 - 7 - tl ))
	[ $lh -lt 3 ] && lh=3
	[ $n -lt $lh ] && lh=$n
	h=$(( lh + 7 + tl ))
	whiptail --title "$TITLE" "$kind" "$text" "$h" "$w" "$lh" "$@" 3>&1 1>&2 2>&3
}

# -----------------------------------------------------------------------------

# 1. BOXMODEL, from the template lines (config.local, then config.example),
#    described by the comment of their group ("# AX/Mutant")
menu_boxmodel() {
	local current items=() m d
	current=$(cfg get BOXMODEL)
	while IFS='|' read -r m d; do
		items+=("$m" "$d" "$([ "$m" = "$current" ] && echo ON || echo OFF)")
	done < <(awk '
		/^#[ \t]*BOXMODEL[ \t]*=/ || /^[ \t]*BOXMODEL[ \t]*=/ {
			m = $0; sub(/^#?[ \t]*BOXMODEL[ \t]*=[ \t]*/, "", m); sub(/[ \t]+$/, "", m)
			if (m != "" && !(m in seen)) { seen[m] = 1; print m "|" group }
			next
		}
		/^#[ \t]*[A-Za-z]/ { group = $0; sub(/^#[ \t]*/, "", group) }
		/^[ \t]*$/ { }
	' "$CONFIG_FILE" "$EXAMPLE_FILE")

	if [ ${#items[@]} -eq 0 ]; then
		m=$(wt --inputbox "BOXMODEL:" 10 60 "$current") && [ -n "$m" ] && cfg select BOXMODEL "$m"
		return
	fi
	m=$(wl --radiolist "BOXMODEL (aktuell: ${current:-nicht gesetzt})" "${items[@]}") || return
	[ -n "$m" ] && cfg select BOXMODEL "$m"
}

# 2. Neutrino flavour, from the list in config.example
menu_flavour() {
	local var=BS_PACKAGE_NEUTRINO_FLAVOUR current def items=() f d
	def=$(mk_default $var)
	current=$(cfg get $var)
	while IFS='|' read -r f d; do
		items+=("$f" "$d" "$([ "$f" = "${current:-$def}" ] && echo ON || echo OFF)")
	done < <(sed -nE 's/^#[[:space:]]+([a-z0-9]+)[[:space:]]+-[[:space:]]+(.*)/\1|\2/p' "$EXAMPLE_FILE")
	[ ${#items[@]} -eq 0 ] && items=(ni "" OFF tc "" OFF tuxbox "" OFF)

	f=$(wl --radiolist "Neutrino-Flavour (aktuell: ${current:-Standard, $def})" "${items[@]}") || return
	[ -z "$f" ] && return
	if [ "$f" = "$def" ]; then
		cfg unset $var
	else
		cfg set $var "$f"
	fi
}

# 3. y/n options, the ones config.example lists as "#VAR = y" or "#VAR = n"
menu_options() {
	local vars=() descs=() v d choice i
	while IFS='|' read -r v d; do
		vars+=("$v"); descs+=("$d")
	done < <(awk '
		/^#[ \t]*[A-Z][A-Z0-9_]*[ \t]*=[ \t]*[yn][ \t]*$/ {
			v = $0; sub(/^#[ \t]*/, "", v); sub(/[ \t]*=.*/, "", v); print v "|" desc; desc = ""; next
		}
		/^#[ \t]+[^ \t-]/ { if (desc == "") { desc = $0; sub(/^#[ \t]+/, "", desc) } ; next }
		{ desc = "" }
	' "$EXAMPLE_FILE")

	while true; do
		local items=()
		for i in "${!vars[@]}"; do
			v=$(cfg get "${vars[$i]}")
			items+=("${vars[$i]}" "[${v:-Standard}] ${descs[$i]}")
		done
		choice=$(wl --menu "Option wählen (Standard: Vorgabe der Makefiles, je nach Box)" "${items[@]}") || return
		v=$(wl --menu "$choice" \
			Standard "Vorgabe der Makefiles" y "ein" n "aus") || continue
		case "$v" in
			Standard) cfg unset "$choice" ;;
			*) cfg set "$choice" "$v" ;;
		esac
	done
}

# 4. Neutrino plugins: --disable-<plugin> in BS_NEUTRINO_PLUGINS_CONF_OPTS
menu_plugins() {
	local var=BS_NEUTRINO_PLUGINS_CONF_OPTS opts plugins p items=() keep=() sel o
	if [ ! -f "$PLUGINS_CONFIGURE" ]; then
		wt --msgbox "$PLUGINS_CONFIGURE fehlt.\nDie Plugin-Liste kommt aus den Quellen der neutrino-plugins (erst nach 'make neutrino-plugins' bzw. dem ersten Checkout vorhanden)." 11 70
		return
	fi
	opts=" $(cfg get $var) "
	plugins=$(sed -nE 's/^AC_ARG_ENABLE\(([A-Za-z0-9_-]+),.*/\1/p' "$PLUGINS_CONFIGURE" | tr "\n" " ")
	for p in $plugins; do
		local d="" state=ON
		[[ "$opts" == *" --disable-$p "* ]] && state=OFF
		grep -q -- "--disable-$p\b" "$PLUGINS_MK" && d="(vom Buildsystem ggf. abgeschaltet)"
		items+=("$p" "$d" "$state")
	done

	sel=$(wl --checklist "Plugins, die gebaut werden (Leertaste schaltet um)" "${items[@]}") || return
	sel=" $(echo $sel | tr -d '"') "

	# options in the variable that are not about a plugin stay
	for o in $opts; do
		[[ "$o" == --disable-* || "$o" == --enable-* ]] &&
			[[ " $plugins " == *" ${o#--*able-} "* ]] && continue
		keep+=("$o")
	done
	for p in $plugins; do
		[[ "$sel" == *" $p "* ]] || keep+=("--disable-$p")
	done
	if [ ${#keep[@]} -eq 0 ]; then
		cfg unset $var
	else
		cfg set $var "$(printf '%s\n' "${keep[@]}")"
	fi
}

# packages of 'make image' (make/ni.mk) for the BOXMODEL of config.local:
# sets IMG_REQUIRED, IMG_PACKAGES, IMG_SKIP and IMG_OWN
image_packages() {
	local out
	out=$(make -s BS_IGNORE_BOXMODEL_CHECK=y print-image-packages 2>/dev/null | tr -d '\r') || out=""
	IMG_REQUIRED=$(sed -n 's/^required: //p' <<< "$out")
	IMG_PACKAGES=$(sed -n 's/^packages: //p' <<< "$out")
	IMG_SKIP=$(sed -n 's/^skip: //p' <<< "$out")
	IMG_OWN=$(sed -n 's/^own: //p' <<< "$out")
	[ -n "$IMG_PACKAGES" ]
}

# every package of package/ (also in group directories like package/qt5/)
all_packages() {
	find package -mindepth 2 -maxdepth 3 -name '*.mk' |
		awk -F/ '{ d = $(NF-1); f = $NF; sub(/\.mk$/, "", f); if (d == f) print f }' |
		grep -v '^pkg-' | sort -u
}

# 5. packages of the image: leave some out (BS_PACKAGES_SKIP)
menu_image_skip() {
	local items=() p sel skip=()
	image_packages || { wt --msgbox "Die Paketliste von 'make image' ließ sich nicht ermitteln\n('make print-image-packages')." 9 70; return; }
	for p in $IMG_PACKAGES; do
		[[ " $IMG_REQUIRED " == *" $p "* ]] && continue
		local state=ON
		[[ " $IMG_SKIP " == *" $p "* ]] && state=OFF
		items+=("$p" "" "$state")
	done
	sel=$(wl --checklist "Pakete von 'make image' für $(cfg get BOXMODEL) (aus = BS_PACKAGES_SKIP)\nImmer gebaut: $IMG_REQUIRED" "${items[@]}") || return
	sel=" $(echo $sel | tr -d '"') "
	for p in $IMG_PACKAGES; do
		[[ " $IMG_REQUIRED " == *" $p "* ]] && continue
		[[ "$sel" == *" $p "* ]] || skip+=("$p")
	done
	# skipped packages that are not in the list of this box stay
	for p in $IMG_SKIP; do
		[[ " $IMG_PACKAGES " == *" $p "* ]] || skip+=("$p")
	done
	if [ ${#skip[@]} -eq 0 ]; then
		cfg unset BS_PACKAGES_SKIP
	else
		cfg set BS_PACKAGES_SKIP "${skip[*]}"
	fi
}

# 6. own packages added to the image (BS_PACKAGES_OWN)
menu_image_own() {
	local items=() p sel own=()
	image_packages || { wt --msgbox "Die Paketliste von 'make image' ließ sich nicht ermitteln\n('make print-image-packages')." 9 70; return; }
	for p in $(all_packages); do
		[[ "$p" == host-* ]] && continue
		[[ " $IMG_REQUIRED $IMG_PACKAGES " == *" $p "* ]] && continue
		local state=OFF
		[[ " $IMG_OWN " == *" $p "* ]] && state=ON
		items+=("$p" "" "$state")
	done
	sel=$(wl --checklist "Zusätzliche Pakete fürs Image (BS_PACKAGES_OWN)" "${items[@]}") || return
	for p in $(echo $sel | tr -d '"'); do own+=("$p"); done
	# own entries that are no package of package/ (e.g. of internal/) stay
	for p in $IMG_OWN; do
		[[ " ${items[*]} " == *" $p "* ]] || own+=("$p")
	done
	if [ ${#own[@]} -eq 0 ]; then
		cfg unset BS_PACKAGES_OWN
	else
		cfg set BS_PACKAGES_OWN "${own[*]}"
	fi
}

# 7. every variable of config.local
menu_all_vars() {
	local choice cur action new short
	while true; do
		local items=() v
		while read -r v; do
			if cur=$(cfg get "$v"); then
				items+=("$v" "[AKTIV] $cur")
			else
				items+=("$v" "[AUS]")
			fi
		done < <(sed -nE 's/^#?[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[:?]?=.*/\1/p' "$CONFIG_FILE" |
			grep -vx 'BOXMODEL' | awk '!seen[$0]++')

		choice=$(wl --menu "Variable auswählen" "${items[@]}") || return

		cur=$(cfg get "$choice")
		short=$cur; [ ${#short} -gt 60 ] && short="${short:0:57}..."
		action=$(wl --menu "$choice = $short" \
			1 "Wert ändern (aktiviert die Variable)" \
			2 "Deaktivieren (auskommentieren)") || continue
		case "$action" in
			1)
				new=$(wt --inputbox "Neuer Wert für $choice:" 10 90 "$cur") || continue
				# a value of several configure options: one per line
				if [[ "$new" == *" --"* ]]; then
					new=$(echo "$new" | sed -E 's/[[:space:]]+--/\n--/g')
				fi
				cfg set "$choice" "$new"
				;;
			2)
				cfg unset "$choice"
				;;
		esac
	done
}

# -----------------------------------------------------------------------------

while true; do
	box=$(cfg get BOXMODEL); box=${box:-NICHT GESETZT}
	flavour=$(cfg get BS_PACKAGE_NEUTRINO_FLAVOUR) || flavour="$(mk_default BS_PACKAGE_NEUTRINO_FLAVOUR) (Standard)"
	layout=$(cfg get IMAGE_LAYOUT) || layout="Standard der Box"

	choice=$(wl --menu "BOXMODEL: $box\nFlavour:  $flavour\nLayout:   $layout" \
		1 "BOXMODEL wählen" \
		2 "Neutrino-Flavour wählen" \
		3 "Optionen (y/n)" \
		4 "Neutrino-Plugins" \
		5 "Image-Pakete abwählen (ni.mk)" \
		6 "Eigene Pakete hinzufügen" \
		7 "Alle Variablen bearbeiten" \
		8 "$CONFIG_FILE anzeigen" \
		9 "Beenden") || break

	case "$choice" in
		1) menu_boxmodel ;;
		2) menu_flavour ;;
		3) menu_options ;;
		4) menu_plugins ;;
		5) menu_image_skip ;;
		6) menu_image_own ;;
		7) menu_all_vars ;;
		8) term_size; whiptail --title "$CONFIG_FILE" --scrolltext --textbox "$CONFIG_FILE" $(( ROWS - 2 )) $(( COLS - 4 )) ;;
		9) break ;;
	esac
done
