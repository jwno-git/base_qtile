#!/bin/bash

# Set brightness to 100% before desktop starts
brightnessctl set 100%

# Set Volume upon Launch
wpctl set-volume @DEFAULT_SINK@ 0%

# Trigger monitor setup
~/.local/bin/monitor-config.sh &

# Screen saver settings
xset s 1000    # Set screensaver timeout to 1000 seconds
xset -dpms     # Disable DPMS (Display Power Management Signaling)

# Load X11 resources
xrdb ~/.Xresources

# Enable touchpad tap-to-click (dynamic device detection)
TOUCHPAD_ID=$(xinput list | grep -i touchpad | grep -o 'id=[0-9]*' | cut -d= -f2)
if [ -n "$TOUCHPAD_ID" ]; then
    xinput set-prop "$TOUCHPAD_ID" "libinput Tapping Enabled" 1
    xinput set-prop "$TOUCHPAD_ID" "libinput Tapping Button Mapping Enabled" 1 1
fi

# Start picom compositor
picom --backend glx &

# Start the window manager (must be last)
exec qtile start
