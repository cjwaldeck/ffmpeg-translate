#!/bin/bash

function usage {
	echo "
	Translation utility using ffmpeg to mix in an tramslator into a video feed.
	Video audio will duck for the translation input.

	Mandatory arguments:
		-o, --stream_out   Output stream
		-ti, --trans_in    Translator input alsa device
	"
}

while [[ "$#" -gt 0 ]]; do
	case $1 in
		-o|--stream_out) STREAM_OUT=$2 ;;
		-ti|--trans_in) TRANS_IN=$2 ;;
		-h|--help) usage ; exit 0 ;;
	esac
	shift
done

echo "
Starting translation stream with the following:

    Stream output:       $STREAM_OUT
    Translation input:   $TRANS_IN
"

ffmpeg -f lavfi -i nullsrc=s=256x256:d=5 -f alsa -i $TRANS_IN -c:v libx264 -c:a aac \
    -filter_complex "[1:a]loudnorm" -f flv $STREAM_OUT
