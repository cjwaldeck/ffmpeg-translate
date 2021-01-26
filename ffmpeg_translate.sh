#!/bin/bash

function usage {
	echo "
	Translation utility using ffmpeg to mix in an tramslator into a video feed.
	Video audio will duck for the translation input.

	Mandatory arguments:
		-i, --stream_in    Input video stream
		-o, --stream_out   Output video stream
		-ti, --trans_in    Translator input alsa device
		-to, --trans_mon   Translator monitor alsa device
	"
}

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONFIG="$SCRIPTDIR/config"
DEFAULT_CONFIG="
COMP_GAIN=1
COMP_THRESHOLD=0.1
COMP_RATIO=8
COMP_RELEASE=1000
COMP_ATTACK=1

TRANS_DELAY=0
"

if [[ ! -f $CONFIG ]]; then
	echo "Generating default config."
	echo "$DEFAULT_CONFIG" >> $CONFIG
fi

. $CONFIG

while [[ "$#" -gt 0 ]]; do
	case $1 in
		-i|--stream_in) STREAM_IN=$2 ;;
		-o|--stream_out) STREAM_OUT=$2 ;;
		-ti|--trans_in) TRANS_IN=$2 ;;
		-tm|--trans_mon) TRANS_MON=$2 ;;
		-h|--help) usage ; exit 0 ;;
	esac
	shift
done

echo "
Starting translation stream with the following:

    Stream input:        $STREAM_IN
    Stream output:       $STREAM_OUT
    Translation input:   $TRANS_IN
    Translation monitor: $TRANS_MON
"

ffmpeg -re -i $STREAM_IN -f alsa -i $TRANS_IN -c:v copy -c:a aac -filter_complex \
    "[0:a]asplit[compin][tmon]; \
     [1:a]agate=ratio=10:threshold=0.05,loudnorm,adelay=$TRANS_DELAY|$TRANS_DELAY,asplit[sc][tnorm]; \
     [compin][sc]sidechaincompress=threshold=$COMP_THRESHOLD:ratio=$COMP_RATIO: \
         level_sc=$COMP_GAIN:release=$COMP_RELEASE:attack=$COMP_ATTACK[compout]; \
     [compout][tnorm]amix" \
    -f flv $STREAM_OUT \
    -map '[tmon]' -f alsa $TRANS_IN
