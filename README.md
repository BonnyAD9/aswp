# aswp
*aswp* stands for *audio swap*. This script uses `pactl` to swap between two
audio devices. You can setup the devices by running `aswp config`.

## How to set the audio devices
Run the script as is shown below and follow the instructions:
```bash
aswp config
```

## Why is this useful?
You can bind shortcut to this script so you can swap your audio devices by
a keybord shortcut.

## Requirements
- `bash` - used for running the script, other shells will be propably fine
- `pactl` - used for getting the information about the devices and to swap them
- `gawk` - GNU awk, used for getting the useful information from the `pactl`
   output
- `sed` - used for escaping variables for regex patterns
- `notify-send` - used for notifications
