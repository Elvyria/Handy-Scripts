#!/bin/zsh

# Advanced media control

usage () {
	printf '
Usage:
    playback.sh SUBCOMMAND

SUBCOMMAND:
	toggle     pause/resume
	pause      pause everything
'

	exit
}

playback_status='unknown'

function dbus_players() {
	dbus-send                          \
		--print-reply                  \
		--dest=org.freedesktop.DBus    \
		/org/freedesktop/DBus          \
		org.freedesktop.DBus.ListNames \
		| rg -o --color=never "org\.mpris\.MediaPlayer2\.\w+\.instance\d+"
}

function pause_all() {
	# MPD
	mpc pause

	# DBus
	dbus_players | while read -r player ; do
		dbus-send                   \
			--type=method_call      \
			--dest="$player"        \
			/org/mpris/MediaPlayer2 \
			org.mpris.MediaPlayer2.Player.Pause
	done
}

function play() {
	#MPD
	mpc play
}

function update_status() {
	#MPD
	if [[ $(mpc | sed -n '2{p;q}') == *'[playing]'* ]]; then
			playback_status='playing'
			return
	fi

	# DBus
	while read -r player; do
		response=$(dbus-send                                \
					--print-reply                           \
					--dest="$player"                        \
					/org/mpris/MediaPlayer2                 \
					org.freedesktop.DBus.Properties.Get     \
					string:org.mpris.MediaPlayer2.Player    \
					string:PlaybackStatus                   \
					| sed -n '2p')

		if [[ "$response" == *'Playing'* ]]; then
			playback_status='playing'
			return
		fi

	done < <(dbus_players)

	playback_status='paused'
}

function toggle() {
	update_status

	case "$playback_status" in
		'playing') pause_all
		;;
		'paused')  play
		;;
		*) echo "Unknown playback status"
		;;
	esac
}

case "$1" in
	'toggle')
		toggle
		;;
	'pause')
		pause_all
		;;
	*)
		usage
		;;
esac
