#!/cache/OpenRecovery/sbin/bash

export PATH="$PATH:/cache/OpenRecovery/bin:/cache/OpenRecovery/sbin"

mkdir /cdrom
chmod 0755 /cdrom

mkdir /sddata
chmod 0755 /sddata

cp -fR /cache/OpenRecovery/* /
rm -R /cache/OpenRecovery

	MTDBLOCK_SYSTEM=$(/sbin/cat /proc/mtd | /sbin/grep "system")
	MTDBLOCK_SYSTEM=${MTDBLOCK_SYSTEM%%:*}
	MTDBLOCK_SYSTEM=${MTDBLOCK_SYSTEM##mtd}
	MTDBLOCK_SYSTEM="\/dev\/block\/mtdblock$MTDBLOCK_SYSTEM"
	
	MTDBLOCK_DATA=$(/sbin/cat /proc/mtd | /sbin/grep "userdata")
	MTDBLOCK_DATA=${MTDBLOCK_DATA%%:*}
	MTDBLOCK_DATA=${MTDBLOCK_DATA##mtd}
	MTDBLOCK_DATA="\/dev\/block\/mtdblock$MTDBLOCK_DATA"
	
	MTDBLOCK_CDROM=$(/sbin/cat /proc/mtd | /sbin/grep "cdrom")
	MTDBLOCK_CDROM=${MTDBLOCK_CDROM%%:*}
	MTDBLOCK_CDROM=${MTDBLOCK_CDROM##mtd}
	MTDBLOCK_CDROM="\/dev\/block\/mtdblock$MTDBLOCK_CDROM"
	
	MTDBLOCK_CACHE=$(/sbin/cat /proc/mtd | /sbin/grep "cache")
	MTDBLOCK_CACHE=${MTDBLOCK_CACHE%%:*}
	MTDBLOCK_CACHE=${MTDBLOCK_CACHE##mtd}
	MTDBLOCK_CACHE="\/dev\/block\/mtdblock$MTDBLOCK_CACHE"
	
	MTDBLOCK_CUST=$(/sbin/cat /proc/mtd | /sbin/grep "cust")
	MTDBLOCK_CUST=${MTDBLOCK_CUST%%:*}
	MTDBLOCK_CUST=${MTDBLOCK_CUST##mtd}
	MTDBLOCK_CUST="\/dev\/block\/mtdblock$MTDBLOCK_CUST"
	
	sed -i "s/MTDBLOCKSYSTEM/$MTDBLOCK_SYSTEM/g" /etc/fstab
	sed -i "s/MTDBLOCKDATA/$MTDBLOCK_DATA/g" /etc/fstab
	sed -i "s/MTDBLOCKCDROM/$MTDBLOCK_CDROM/g" /etc/fstab
	sed -i "s/MTDBLOCKCACHE/$MTDBLOCK_CACHE/g" /etc/fstab
	sed -i "s/MTDBLOCKCUST/$MTDBLOCK_CUST/g" /etc/fstab
	
#ext2/3/4 partition on sdcard
	if [ -b /dev/block/mmcblk0p2 ]; then
	
		echo "/dev/block/mmcblk0p2          /sddata         auto            defaults        0 0" >> /etc/fstab
		e2fsck -p /dev/block/mmcblk0p2 
	fi

# toggle adb function to get correct initial usb state 
echo 0 > /sys/class/usb_composite/adb/enable 
echo 1 > /sys/class/usb_composite/adb/enable
