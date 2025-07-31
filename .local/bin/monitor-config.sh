#!/bin/bash

# User-context monitor configuration script
export DISPLAY=:0

# Log activity
echo "$(date): User monitor script executed" >> /tmp/monitor-config.log

# Wait briefly for hardware to settle
sleep 1

# Check if HDMI is connected
if xrandr | grep -q "HDMI-A-0 connected"; then
    # HDMI connected - use dual monitor setup
    xrandr --output eDP --mode 2880x1800 --rate 60 --pos 0x1080 \
           --output HDMI-A-0 --mode 1920x1080 --rate 60 --pos 480x0
    
    # Set wallpaper on both monitors individually
    feh --bg-fill --output eDP --output HDMI-A-0 "$HOME/Pictures/Wallpapers/wallpaper.png"
    
    echo "$(date): Configured dual monitor setup" >> /tmp/monitor-config.log
else
    # HDMI disconnected - laptop only
    xrandr --output eDP --mode 2880x1800 --rate 60 --pos 0x0 \
           --output HDMI-A-0 --off
    
    # Set wallpaper on laptop monitor only
    feh --bg-fill "$HOME/Pictures/Wallpapers/wallpaper.png"
    
    echo "$(date): Configured single monitor setup" >> /tmp/monitor-config.log
fi
