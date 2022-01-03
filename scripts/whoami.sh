#!/bin/sh

#-------- GLOBALS --------
provider='icanhazip.com'
yellow=$(tput setaf 3)
normal=$(tput sgr0)
#-------------------------

usage () {
	printf '
Usage:
    whoami.sh [opts]

OPTIONS
    -h, --help   print this message
    -l, --local  print local IP
    -4, --IPv4   print public IPv4
    -6, --IPv6   print public IPv6
'
	exit
}

_local () {
	hostname -i
}

ipv4 () {
	curl -m 1 -s -4 "$provider"
}

ipv6 () {
	curl -m 1 -s -6 "$provider"
}

info () {
	local=$(_local)
	IPv4=$(ipv4)
	IPv6=$(ipv6)

	if [ -n "$local" ]; then
		printf "%sLocal%s:\n    IPv4: %s\n" "${yellow}" "${normal}" "$local"
	fi

	if [ -n "$IPv4" ] || [ -n "$IPv6" ]; then \
		printf "%sPublic%s:\n" "${yellow}" "${normal}"

		[ -n "$IPv4" ] && printf '    IPv4: %s\n' "$IPv4"
		[ -n "$IPv6" ] && printf '    IPv6: %s\n' "$IPv6"
	fi
}

case "$1" in
	-h | --help)
		usage
		;;
	-l | --local)
		_local
		;;
	-4 | --[Ii][Pp][Vv]4)
		ipv4
		;;
	-6 | --[Ii][Pp][Vv]6)
		ipv6
		;;
	*)
		info
		;;
esac
