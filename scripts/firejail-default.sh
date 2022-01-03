#!/bin/sh

# Creates/removes firejail links and modifies desktop entries that bypass them.

usage () {
	printf '
Usage:
    firejail-default.sh [options] [apps...]

OPTIONS
    -a, --add
    -r, --remove
'
	exit
}

add () {
	# ARGS: --------
	apps=$*
	#---------------

	mkdir -p "$XDG_DATA_HOME/applications"

	for app in $apps; do
		sudo ln -sf /usr/bin/firejail "/usr/local/bin/$app"
		desktop="$(rg -ilm1 "$app" /usr/share/applications/*.desktop | head -n 1)"
		name="$(basename "$desktop")"

		if [ ! -f "$XDG_DATA_HOME/applications/$name" ]; then
			cp "$desktop" "$XDG_DATA_HOME/applications/"
		fi

		# /usr/bin/app -> app
		sed -i "s/\/usr\/bin\/$app/$app/Ig" "$XDG_DATA_HOME/applications/$name"
	done

	update-desktop-database "$XDG_DATA_HOME/applications"
}

remove () {
	# ARGS: --------
	apps=$*
	#---------------

	for app in $apps; do
		if [ "$(readlink "/usr/local/bin/$app")" = "/usr/bin/firejail" ]; then
			sudo rm -i -- "/usr/local/bin/$app"
		fi
	done
}

case "$1" in
	-a | --add)
		shift
		add "$@"
		;;
	-r | --remove)
		shift
		remove "$@"
		;;
	*)
		usage
		;;
esac
