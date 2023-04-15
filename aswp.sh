#!/usr/bin/bash

# the two outputs to swap
SINK1='alsa_output.pci-0000_28_00.4.analog-stereo'
PORT1='analog-output-headphones'
SINK2='alsa_output.pci-0000_28_00.4.analog-stereo'
PORT2='analog-output-lineout'

CUR_SINK="$SINK1"
CUR_PORT="$PORT1"

# escapes text (from stdin) for use in sed regex (to stdout)
# sed_escape
function sed_escape() {
    sed -e 's/\\/\\\\/g' -e 's/\./\\./g' -e 's/\*/\\*/g' -e 's/\[/\\[/g' \
        -e 's/\//\\\//g' -e 's/\]/\\]/g' -e 's/\^/\\^/g' -e 's/\$/\\$/g' \
        -e 's/(/\\(/g'   -e 's/)/\\)/g'
}

# gets the information about sink
# get_sink_info SINK_NAME
function get_sink_info() {
    _SINK_NAME=`sed_escape <<<"$1"`
    pactl list sinks | gawk '
        BEGIN {
            is_match = false;
            sink_info = "";
        }

        # match start of new sink
        /^Sink.*$/ {
            # exit if the name has already been matched
            if (is_match) {
                exit 0;
            }
            sink_info = $0;
        }

        # find whether the sink has the searched name
        /^\t.*$/ {
            sink_info = sink_info "\n" $0;
            is_match = is_match || $0 ~ /\tName: '"$_SINK_NAME"'/;
        }

        # exit with error if there is no sink with that name
        END {
            if (!is_match)
                exit 1;
            print sink_info;
        }
    '
}

# gets the active port of sink
# get_active_port SINK_NAME
function get_active_port() {
    get_sink_info "$1" | gawk '
        match($0, /^\tActive Port: (.*)$/, a) {
            print a[1];
            exit 0;
        }
    '
}

# get current sink
CUR_SINK=`pactl get-default-sink`
CUR_PORT=`get_active_port $CUR_SINK`

if [[ "$CUR_SINK" == "$SINK1" && "$CUR_PORT" == "$PORT1" ]] ; then
    pactl set-default-sink "$SINK2"
    pactl set-sink-port "$SINK2" "$PORT2"
else
    pactl set-default-sink "$SINK1"
    pactl set-sink-port "$SINK1" "$PORT1"
fi
