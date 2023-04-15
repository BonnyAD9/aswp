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
    _SINK_NAME=sed_escape <<<"$1"
    pactl list sinks | gawk '
        BEGIN {
            is_match = false;
            sink_info = "";
        }

        # match start of new sink
        /^Sink.*?$/ {
            if (is_match) {
                printf("%s", sink_info);
                exit 0;
            }
            sink_info = $0;
        }

        # find whether the sink has the searched name
        /^\t.*?$/ {
            sink_info = $0;
            is_match = $0 ~ /\tName: '"$_SINK_NAME"'/;
        }

        # exit with error if there is no sink with that name
        END {
            if (!is_match)
                exit 1;
        }
    '
}

# gets the active port of sink
# get_active_port SINK_NAME
function get_active_port() {

}

# get current sink
CUR_SINK=`pactl get-default-sink`
CUR_PORT=`get_port_of_sink $CUR_SINK`
