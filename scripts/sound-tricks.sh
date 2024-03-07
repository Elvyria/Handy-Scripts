#!/bin/sh

usage () {
	printf '
Usage:
    sound-tricks.sh [OPTION]

OPTIONS:
    -c, --cycle            cycle through output sinks
    -w, --window [volume]  change focused window volume
    -m, --mute             change microphone state
'

	exit
}

# Cycle active output sinks
cycle () {
	sinks=$(pactl list sinks | rg --trim -r '$1' 'Name: (.*?)' | rg -vi "(easyeffects|pulseeffects|controller)")
	current=$(pactl get-default-sink)

	[ -z "$sinks" ] && exit 1

	next=$(echo "$sinks" | rg -A1 "$current" | tail -n +2)

	[ -z "$next" ] && next=$(echo "$sinks" | head -n 1)

	temp='/tmp/sound-tricks.cycle.id'

	[ -f "$temp" ] && id=$(cat "$temp")

	pactl set-default-sink "$next" && notify-send -p ${id:+ -r "$id"} -t 1100 "Switched Audio Device" "$next" > "$temp"
}

# Change focused window volume
window () {
	# ARGS: --------
	volume="$1"
	#---------------

	inputs=$(pactl list sink-inputs)
	active_pid=$(xdotool getwindowfocus getwindowpid)

	line_nums=$(echo "$inputs" | awk "/application.process.id = \"$active_pid\"/ {print NR}")

	if [ "$(echo "$line_nums" | wc -l)" -ne 1 ]; then
		exit
	fi

	id=$(echo "$inputs" | head -n"$line_nums" | tac | rg -m 1 -r '$1' 'Sink Input #(\d+)')

	pactl 'set-sink-input-volume' "$id" "$volume"
}

# Toggle microphone state
mute() {
	pactl set-source-mute '@DEFAULT_SOURCE@' toggle

	temp='/tmp/sound-tricks.mute.id'

	[ -f "$temp" ] && id=$(cat "$temp")

	case "$(pactl get-source-mute '@DEFAULT_SOURCE@')" in
		'Mute: yes') notify-send -p ${id:+ -r "$id"} -t 2000 'Changed Microphone State' ' Muted'        > "$temp" ;;
		'Mute: no')  notify-send -p ${id:+ -r "$id"} -t 2000 'Changed Microphone State' ' Listening...' > "$temp" ;;
	esac
}

case "$1" in
	-c | --cycle)
		cycle
		;;
	-w | --window)
		[ -z "$2" ] && usage

		window "$2"
		;;
	-m | --mute)
		mute
		;;
	*)
		usage
		;;
esac
