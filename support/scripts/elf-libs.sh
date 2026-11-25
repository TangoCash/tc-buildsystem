#!/bin/sh
#
# elf-libs.sh READELF ROOT FILE...
#
# Print the shared libraries the ELF files FILE need, directly and through
# each other, as paths below ROOT (/lib or /usr/lib, as on the box), one per
# line. Libraries not found below ROOT are left out.
#

readelf=$1
root=$2
shift 2

todo="$*"
seen=" "
while [ -n "$todo" ]; do
	set -- $todo
	todo=""
	for f; do
		for n in $($readelf -d "$f" 2>/dev/null | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p'); do
			case "$seen" in
				*" $n "*) continue ;;
			esac
			seen="$seen$n "
			for d in /lib /usr/lib; do
				if [ -e "$root$d/$n" ]; then
					echo "$d/$n"
					todo="$todo $root$d/$n"
					break
				fi
			done
		done
	done
done
