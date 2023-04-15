#!/usr/bin/bash

CONFIG_DIR=~/.config/aswp
CONFIG_FILE=$CONFIG_DIR/.aswp
VERSION="1.0.0"

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

# determines the currently default sink and its active port
# the result is saved in the variables $CUR_SINK and $CUR_PORT
# get_current_device
function get_current_device() {
    CUR_SINK=`pactl get-default-sink`
    CUR_PORT=`get_active_port $CUR_SINK`
}

# swaps the devices specified in the config file
# swap
function swap() {
    # the config file is just script with the variables
    . $CONFIG_FILE || exit 1

    get_current_device

    if [[ "$CUR_SINK" == "$SINK1" && "$CUR_PORT" == "$PORT1" ]] ; then
        NEW_SINK="$SINK2"
        NEW_PORT="$PORT2"
    else
        NEW_SINK="$SINK1"
        NEW_PORT="$PORT1"
    fi

    echo "Swapping to:
        Sink: $NEW_SINK
        Port: $NEW_PORT"

    pactl set-default-sink "$NEW_SINK" &&
        pactl set-sink-port "$NEW_SINK" "$NEW_PORT"
}

function config() {
    echo "This will set up aswp. You need a way to set your audio outputs
while this script is running. To cancel the process you can press Ctrl+C
The first audio output you set will be the default to change to if neither of
the two devices is selected.

To continue, change your default audio output to the first device and press
enter:"
    read

    get_current_device
    SINK1="$CUR_SINK"
    PORT1="$CUR_PORT"
    echo "Device 1:
    Sink: $SINK1
    Port: $PORT1
"

    echo "Now change the default audio output to the second device and press
enter:"
    read

    get_current_device
    SINK2="$CUR_SINK"
    PORT2="$CUR_PORT"
    echo "Device 2:
    Sink: $SINK2
    Port: $PORT2
"

    echo "Press enter now to write the settings to the configuration file
'$CONFIG_FILE'. All contets of that file will be overwritten:"

    read

    mkdir -p "$CONFIG_DIR"

    # write the configuration
    echo "#!/usr/bin/bash

# this script is run every time the aswp script is run
# this file is generated again every time 'awp config' is run

# devices:
SINK1='$SINK1'
PORT1='$PORT1'

SINK2='$SINK2'
PORT2='$PORT2'" > "$CONFIG_FILE"
}

# prints the help
function help_fun() {
    echo "Welcome in aswp by BonnyAD9
Version: $VERSION

Usage:
  aswp
    Swaps the audio output devices

  aswp config
    Runs the interactive configuration

  aswp help
    Shows this help"
}

case "$1" in
"") swap ;;
config) config ;;
help|-h|--help|-\?) help_fun ;;
*)  echo "Invalid argument"
    exit 1
    ;;
esac
