# aswp
*aswp* stands for *audio swap*. This script uses `pactl` to swap between two
audio devices. The devices are currently hard-coded into the script so you need
to set them yourself if you want to use this script.

## Why is this useful?
You can bind shortcut to this script so you can swap your audio devices by
a keybord shortcut.

## Requirements
- `bash` - used for running the script, other shells will be propably fine
- `pactl` - used for getting the information about the devices and to swap them
- `gawk` - GNU awk, used for getting the useful information from the `pactl`
   output
- `sed` - used for escaping variables for regex patterns
