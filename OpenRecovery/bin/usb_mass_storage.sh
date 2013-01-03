#!/sbin/bash

#unmount the sdcard
umount /sdcard

echo "正在开启 USB 大容量存储模式..." 

#mount it to PC
echo "/dev/block/mmcblk0p1" > /sys/devices/platform/usb_mass_storage/lun0/file

echo "已开启 USB 大容量存储模式" 

#use imenu to wait for user response
imenu "已开启 USB 大容量存储模式" "关闭" > /dev/null

#unmount it from PC
echo "" > /sys/devices/platform/usb_mass_storage/lun0/file

echo "正在关闭 USB 大容量存储模式..." 

#mount it back
mount /sdcard

echo "已关闭 USB 大容量存储模式"
