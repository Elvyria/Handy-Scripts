#!/bin/sh

# Create Filesystem Backup

usage () {
	printf '
Usage:
    [sudo -E] backup.sh SOURCE DESTINATION
'

	exit
}

backup () {
	# ARGS: --------
	source="$1"
	destination="$2"
	#---------------

	. /etc/os-release

	date=$(date "+%F")
	backup="$destination/$ID-backup-$date.tar.gz"

	if [ -f "$XDG_CONFIG_HOME/backup.ignore" ]; then
		exclude="-X$XDG_CONFIG_HOME/backup.ignore"
	fi

	# Compression method
	if command -v "pbzip2"; then
		method='-I pbzip2'
	fi

	tar "$exclude" --acls --xattrs -cpPvf "$backup" "$method" "$source"
}

if [ -z "$2" ] || [ ! -d "$1" ] || [ ! -d "$2" ]; then
	usage
fi

backup "$1" "$2"
