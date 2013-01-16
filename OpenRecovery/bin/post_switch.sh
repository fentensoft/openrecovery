#!/sbin/bash

#set display brightness
if [ -f /sdcard/OpenRecovery/etc/brightness ] ; then
    cat /sdcard/OpenRecovery/etc/brightness > /sys/class/leds/lcd-backlight/brightness
fi
# toggle adb function to get correct initial usb state 
echo 0 > /sys/class/usb_composite/adb/enable 
echo 1 > /sys/class/usb_composite/adb/enable
killall -9 recovery

#then continue with the remains
killall -9 sleep
killall -9 updater
