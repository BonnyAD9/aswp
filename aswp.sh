#!/usr/bin/bash

CONFIG_DIR=~/.config/aswp
CONFIG_FILE=$CONFIG_DIR/.aswp
VERSION="1.0.2"

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
        NEW_NAME="$NAME2"
    else
        NEW_SINK="$SINK1"
        NEW_PORT="$PORT1"
        NEW_NAME="$NAME1"
    fi

    TAB=`printf '\t'`
    echo "Swapping to: $NEW_NAME"

    pactl set-default-sink "$NEW_SINK" &&
        pactl set-sink-port "$NEW_SINK" "$NEW_PORT"
    RES=$?

    if [[ "$NOTIFY" == "yes" ]] ; then
        notify-send -a aswp -t "$N_LEN" "Now output in $NEW_NAME"
    fi
}

function config() {
    printf "This will set up aswp. You need a way to set your audio outputs
while this script is running. To cancel the process you can press Ctrl+C
The first audio output you set will be the default to change to if neither of
the two devices is selected.

To continue, change your default audio output to the first device and enter its
name (how would you like the device to be reffered to e.g. headphones):
 > "
    NAME1=`head -1`

    get_current_device
    SINK1="$CUR_SINK"
    PORT1="$CUR_PORT"
    echo "Device 1:
    Sink: $SINK1
    Port: $PORT1
    Name: '$NAME1'
"

    printf "Now change the default audio output to the second device and enter
its name (how would you like the device to be reffered to e.g. speakers):
 > "
    NAME2=`head -1`

    get_current_device
    SINK2="$CUR_SINK"
    PORT2="$CUR_PORT"
    echo "Device 2:
    Sink: $SINK2
    Port: $PORT2
    Name: '$NAME2'
"

    printf "Would you like to push notification every time you swap your
device? [yes/<other>]
 > "
    NOTIFY=`head -1`
    if [[ "$NOTIFY" != 'yes' ]] ; then
        NOTIFY=no
    fi

    echo "
Press enter now to write the settings to the configuration file
'$CONFIG_FILE'. All contets of that file will be overwritten. You can edit the
file any time:"

    read

    mkdir -p "$CONFIG_DIR"

    # write the configuration
    echo "#!/usr/bin/bash

# this script is run every time the aswp script is run
# this file is generated again every time 'awp config' is run

# valid values are case sensitive [yes/no]
NOTIFY='$NOTIFY'

# how long to show notifications (in ms)
N_LEN='1000'

# devices:
SINK1='$SINK1'
PORT1='$PORT1'
NAME1='$NAME1'

SINK2='$SINK2'
PORT2='$PORT2'
NAME2='$NAME2'
" > "$CONFIG_FILE"
}

# prints the help
function help_fun() {
    ESC=`printf "\e"`

    RESET="$ESC[0m"

    ITALIC="$ESC[3m"

    DARK="$ESC[90m"
    DGREEN="$ESC[32m"
    DYELLOW="$ESC[33m"

    RED="$ESC[91m"
    GREEN="$ESC[92m"
    YELLOW="$ESC[93m"
    WHITE="$ESC[97m"

    SIGNATURE="$ESC[38;2;250;50;170mB$ESC[38;2;240;50;180mo\
$ESC[38;2;230;50;190mn$ESC[38;2;220;50;200mn$ESC[38;2;210;50;210my\
$ESC[38;2;200;50;220mA$ESC[38;2;190;50;230mD$ESC[38;2;180;50;240m9$ESC[0m"
    echo "Welcome in $GREEN${ITALIC}aswp$RESET by $SIGNATURE
Version $VERSION

${GREEN}Usage:$RESET
  ${WHITE}aswp$RESET
    Swaps the audio output devices

  ${WHITE}aswp config$RESET
    Runs the interactive configuration

  ${WHITE}aswp help$RESET
    Shows this help

  ${WHITE}aswp notify$RESET
    Shows notification with the current audio device

${GREEN}Options:
  $YELLOW-h  --help  -?$RESET
    shows this help"
}

function notify() {
    # the config file is just script with the variables
    . $CONFIG_FILE || exit 1

    get_current_device

    if [[ "$CUR_SINK" == "$SINK1" && "$CUR_PORT" == "$PORT1" ]] ; then
        CUR_NAME="$NAME1"
    elif [[ "$CUR_SINK" == "$SINK2" && "$CUR_PORT" == "$PORT2" ]] ; then
        CUR_NAME="$NAME2"
    else
        CUR_NAME="$CUR_SINK - $CUR_PORT"
    fi

    notify-send -a aswp -t $N_LEN "$CUR_NAME"
}

case "$1" in
"") swap ;;
config) config ;;
help|-h|--help|-\?) help_fun ;;
notify) notify ;;
*)  echo "Invalid argument"
    exit 1
    ;;
esac
