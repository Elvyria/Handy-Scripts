#!/bin/sh

set -e

# Performs simple file conversions

usage () {
	printf '
Usage:
    morph.sh SUBCOMMAND INPUT [OUTPUT]

SUBCOMMAND:
	APPS:
		discord  encode file for minimal size and preview support

	IMAGE:
		jxl      encode image file using JPEG XL

	AUDIO:
		opus     encode audio file using Opus (.opus)

	VIDEO:
		vp9      encode video file using VP9  (.webm)
		x265     encode video file using x265 (.mp4)
'

	exit
}

temp_fd() {
	# ARGS: --------
	pattern=$1
	#---------------

	tmp=$(mktemp "$pattern")
	exec 3>"$tmp"
	exec 4<"$tmp"
	rm "$tmp"
	unset tmp
}

close_fd() {
	exec 3>&-
	exec 4<&-
}

jxl() {
	# ARGS: --------
	input=$1
	output=${2:-${1%.*}.jxl}
	#---------------

	command cjxl --lossless_jpeg=1 "$input" "$output"
}

x265() {
	# ARGS: --------
	input=$1
	output=${2:-${1%.*}.mp4}
	#---------------

	ffmpeg -y -i "$input" -c:v libx265 -b:v 2600k -x265-params pass=1 -an -f null /dev/null && \
	ffmpeg -i "$input" -c:v libx265 -b:v 2600k -x265-params pass=2 -c:a aac -b:a 128k "$output"
}

vp9() {
	# ARGS: --------
	input=$1
	output=${2:-${1%.*}.webm}
	#---------------

	ffmpeg -i "$input" -c:v libvpx-vp9 -b:v 0 -crf 30 -row-mt 1 -deadline good -pass 1  -an -f null /dev/null && \
	ffmpeg -i "$input" -c:v libvpx-vp9 -b:v 0 -crf 30 -row-mt 1 -deadline good -pass 2 -c:a libopus "$output"
}

opus() {
	# ARGS: --------
	input=$1
	output=${2:-${1%.*}.opus}
	tmp='/tmp/morph-audio.XXX.wav'
	#---------------

	case "$input" in
		*.ogg)
			temp_fd "$tmp"
			oggdec --output=- "$input" >&3
			input="/proc/self/fd/4"
			;;
	esac

	opusenc --bitrate 128 --ignorelength "$input" "$output"
}

discord() {
	vp9 "$1" "$2"
}

input=$2; output=$3

case "$1" in
	'discord') discord "$input" "$output" ;;
	'vp9')     vp9     "$input" "$output" ;;
	'x256')    x256    "$input" "$output" ;;
	'opus')    opus    "$input" "$output" ;;
	'jxl')     jxl     "$input" "$output" ;;
	*)         usage                      ;;
esac
