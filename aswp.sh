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
            sink_info = "";
        }

        # match start of new sink
        /^Sink.*?$/ {
            sink_info = $0;
        }

        # find whether the sink has the searched name
        /^\tName: '"$_SINK_NAME"'$/ {

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
