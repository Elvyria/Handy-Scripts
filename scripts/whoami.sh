#!/bin/sh

#-------- GLOBALS --------
provider='icanhazip.com'
yellow=$(tput setaf 3)
normal=$(tput sgr0)
#-------------------------

usage () {
	printf '
Usage:
    whoami.sh [--help] [[-l, -p] [-4] [-6]]

OPTIONS
    -h, --help   print this message
    -l, --local  print local IP
	-p, --public print public IP
    -4, --IPv4   output only IPv4
    -6, --IPv6   output only IPv6
'
	exit
}

_local_v4 () {
	ip -c=never -4 -br addr show | perl -pge 's/.*?UP +(.+?)[\r\n\$]+.*/$1/s;s/\/24//'
}

_local_v6 () {
	ip -c=never -6 -br addr show | perl -pge 's/.*?UP +(.+?)[\r\n\$]+.*/$1/s;s/\/64//'
}

_public_v4 () {
	curl -m 1 -s -4 "$provider"
}

_public_v6 () {
	curl -m 1 -s -6 "$provider"
}

info () {
	localV4=$(_local_v4)
	localV6=$(_local_v6)

	if [ -n "$localV4" ] || [ -n "$localV6" ]; then \
		printf "%sLocal%s:\n" "${yellow}" "${normal}"

		[ -n "$localV4" ] && printf '    IPv4: %s\n' "$localV4"
		[ -n "$localV6" ] && printf '    IPv6: %s\n' "$localV6"
	fi

	publicV4=$(_public_v4)
	publicV6=$(_public_v6)

	if [ -n "$publicV4" ] || [ -n "$publicV6" ]; then \
		printf "%sPublic%s:\n" "${yellow}" "${normal}"

		[ -n "$publicV4" ] && printf '    IPv4: %s\n' "$publicV4"
		[ -n "$publicV6" ] && printf '    IPv6: %s\n' "$publicV6"
	fi
}

asked_public=''
asked_local=''
asked_v4=''
asked_v6=''

[ $# -eq 0 ] && info && exit

for arg; do
	case "$arg" in
		-4 | --[Ii][Pp][Vv]4) asked_v4=true ;;
		-6 | --[Ii][Pp][Vv]6) asked_v6=true ;;
		-l | --local) asked_local=true ;;
		-p | --public) asked_public=true ;;
		-h | --help) usage ;;
	esac
done

if [ -n "$asked_local" ]; then
	if [ -z "$asked_v4" ] && [ -z "$asked_v6" ]; then
		_local_v4
		echo
		_local_v6
		exit
	fi

	[ -n "$asked_v4" ] && _local_v4 && echo
	[ -n "$asked_v6" ] && _local_v6 && echo
fi

if [ -n "$asked_public" ]; then
	if [ -z "$asked_v4" ] && [ -z "$asked_v6" ]; then
		_public_v4
		echo
		_public_v6
		exit
	fi

	[ -n "$asked_v4" ] && _public_v4 && echo
	[ -n "$asked_v6" ] && _public_v6 && echo
fi
