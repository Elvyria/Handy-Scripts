#!/bin/sh

# Performs simple file conversions

usage () {
	printf '
Usage:
    morph.sh SUBCOMMAND INPUT [OUTPUT]

SUBCOMMAND:
	APPS:
		discord  encode file for minimal size and preview support

	AUDIO:       
		opus     encode audio file using Opus (.opus)

	VIDEO:       
		vp9      encode video file using VP9  (.webm)
		x265     encode video file using x265 (.mp4)
'

	exit
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
	#---------------

	opusenc --bitrate 128 --ignorelength "$input" "$output"
}

discord() {
	vp9 "$1" "$2"
}

input=$2; output=$3

case "$1" in
	'discord')
		discord "$input" "$output"
		;;
	'vp9')
		vp9 "$input" "$output"
		;;
	'x256')
		x256 "$input" "$output"
		;;
	'opus')
		opus "$input" "$output"
		;;
	*)
		usage
		;;
esac
