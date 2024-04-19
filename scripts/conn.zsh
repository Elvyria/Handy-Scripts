#!/usr/bin/env zsh

usage() {
printf '
Usage:
	%s [OPTION]

OPTIONS:
	-l, --listeners
	-c, --connections
	-k, --kill
' $1

exit
}

# Print established TCP/UDP ports.
listeners() {
	zmodload 'zsh/datetime'
	zmodload 'zsh/stat'

	local table=''

	while read -r protocol _ port _ process; do
		local address=${port%:*}
		local port=${port##*:}

		table+="$protocol|$address|$port|$process\n"
	done < <(command ss -r -H -n -l -t -u -p | perl -pe \
		'
			s/^(.+?) +\d+ + \d+ +/$1 /;
			s/users:\((.+)\)/$1/;
			s/\("(.+?)",pid=(\d+).*?\)/$1 ($2)/g;
			s/(.+) (.+? \(\d+\)),(.+? \(\d+\))/$1 $2\n$1 $3/
		')

	echo $table | sort -t '|' -n -k 3 | column -t -o ' │ ' --separator '|' \
		-C 'name=Protocol,right' \
		-C 'name=Address,right' \
		-C 'name=Port,right' \
		-C 'name=Process' \
		-O 'Port' \
	| sed '1 a ─────────────────────────────────────────────────────────'
}

# Print TCP/UDP connections.
connections() {
	local ip=$(command ip -br addr show | perl -pge 's/.*?UP +(.+?)[ \$].*/\1/s')

	while read -r protocol state src dst process; do
		table+="$protocol|$state|$src|$dst|$process\n"
	done < <(command ss -H -n -t -u -p src $ip | perl -pe \
		'
			s/^(.+?) +\d+ + \d+ +/$1 /;
			s/users:\((.+)\)/$1/;
			s/\("(.+?)",pid=(\d+).*?\)/$1 ($2)/g;
			s/(.+) (.+? \(\d+\)),(.+? \(\d+\))/$1 $2\n$1 $3/
		')

	echo $table | sort -t '|' -k5 | column -t -o ' │ ' --separator '|' \
		-C 'name=Protocol' \
		-C 'name=State' \
		-C 'name=Source,right' \
		-C 'name=Destination,right' \
		-C 'name=Process' \
	| sed '1 a ──────────────────────────────────────────────────────────────────────────────────────────────────────'
}

close() {
	ss -K src $1
}

case "$1" in
	-l|--listeners)   listeners   ;;
	-c|--connections) connections ;;
	-k|--kill)        close ;;
	*)                usage $0    ;;
esac
