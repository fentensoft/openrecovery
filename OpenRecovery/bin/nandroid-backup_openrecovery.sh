#!/sbin/bash

NOTHING=1

REBOOT=0
COMPRESS=0

BKP_BOOT=0
BKP_LBL=0
BKP_LOGO=0

BKP_SYSTEM=0
BKP_DATA=0
BKP_CACHE=0
BKP_CDROM=0

BKP_EXT2=0

TAGPREFIX="/tags/."

#the backup is compatible with the adbrecovery format
BACKUPPATH="/sdcard/nandroid/openrecovery"
BACKUPPREFIX="OR-"

#amount of space remaining
FREEBLOCKS="`df -k /sdcard| grep sdcard | awk '{ print $4 }'`"

echo "+------------------------------------------+"
echo "+                                          +"
echo "+               备 份 模 式                 +"
echo "+                                          +"
echo "+------------------------------------------+"
sleep 2

#===============================================================================
# Parse the arguments
#===============================================================================

if [ -f "$TAGPREFIX"nand_bkp_autoreboot ]; then
	REBOOT=1
fi

if [ -f "$TAGPREFIX"nand_bkp_compress ]; then
	COMPRESS=1
fi

if [ "$1" == "--all" ]; then
	BKP_BOOT=1
	BKP_LBL=1
	BKP_LOGO=1
	BKP_SYSTEM=1
	BKP_DATA=1
	BKP_CACHE=1
	BKP_CDROM=1
	BKP_EXT2=1
	NOTHING=0
else

	if [ -f "$TAGPREFIX"nand_bkp_system ]; then
		BKP_SYSTEM=1
		NOTHING=0
	fi
	
	if [ -f "$TAGPREFIX"nand_bkp_data ]; then
		BKP_DATA=1
		NOTHING=0
	fi
	
	if [ -f "$TAGPREFIX"nand_bkp_boot ]; then
		BKP_BOOT=1
		NOTHING=0
	fi
	
	if [ -f "$TAGPREFIX"nand_bkp_cache ]; then
		BKP_CACHE=1
		NOTHING=0
	fi
	
	if [ -f "$TAGPREFIX"nand_bkp_lbl ]; then
		BKP_LBL=1
		NOTHING=0
	fi
	
	if [ -f "$TAGPREFIX"nand_bkp_logo ]; then
		BKP_LOGO=1
		NOTHING=0
	fi
	
	if [ -f "$TAGPREFIX"nand_bkp_cdrom ]; then
		BKP_CDROM=1
		NOTHING=0
	fi
	
	if [ -f "$TAGPREFIX"nand_bkp_ext2 ]; then
		BKP_EXT2=1
		NOTHING=0
	fi
fi

if [ $NOTHING -eq 1 ]; then
	echo "E: 未执行任何操作"
	exit 1
fi

#===============================================================================
# Prepare the backing up
#===============================================================================

#check availbility of the utilities
mkyaffs2image=`which mkyaffs2image`
if [ "$mkyaffs2image" == "" ]; then
	mkyaffs2image=`which mkyaffs2image-or`
	if [ "$mkyaffs2image" == "" ]; then
		echo "E: 未找到 mkyaffs2image 或 mkyaffs2image-or."
		exit 1
	fi
fi

dump_image=`which dump_image`
if [ "$dump_image" == "" ]; then
	dump_image=`which dump_image-or`
	if [ "$dump_image" == "" ]; then
		echo "E: 未找到 dump_image 或 dump_image-or."
		exit 1
	fi
fi


#check battery
if [ "$COMPRESS" == 1 ]; then
	ENERGY=`cat /sys/class/power_supply/battery/capacity`
	if [ "`cat /sys/class/power_supply/battery/status`" == "Charging" ]; then
		ENERGY=100
	fi
	if [ ! $ENERGY -ge 30 ]; then
		echo "E: 电量不足"      
		exit 1
	fi
fi

#===============================================================================
# Check partitions and free space
#===============================================================================

#require at least 400 MiB to proceed
if [ $FREEBLOCKS -le 409600 ]; then
	echo "E: 存储空间不足"
	echo "请确认 SD 卡上至少有 400MB 或更大的空间."
	exit 1
else
	echo "请确认 SD 卡上至少有 400MB 或更大的空间."
fi

#build the prefix and check if the filesystem partitions are properly mounteable
BACKUPLEGEND=""

if [ $BKP_BOOT -eq 1 ]; then
	BACKUPLEGEND=$BACKUPLEGEND"B"
fi

if [ $BKP_LBL -eq 1 ]; then
	BACKUPLEGEND=$BACKUPLEGEND"L"
fi

if [ $BKP_LOGO -eq 1 ]; then
	BACKUPLEGEND=$BACKUPLEGEND"l"
fi

if [ $BKP_SYSTEM -eq 1 ]; then
	umount /system 2> /dev/null
	mount /system || FAIL=1
	
	if [ $FAIL -eq 1 ]; then
		BKP_SYSTEM=0
	else	
		BACKUPLEGEND=$BACKUPLEGEND"S"
	fi
fi

if [ $BKP_DATA -eq 1 ]; then
	umount /data 2> /dev/null
	mount /data || FAIL=1
	
	if [ $FAIL -eq 1 ]; then
		BKP_DATA=0 
	else
		BACKUPLEGEND=$BACKUPLEGEND"D"
	fi
fi

if [ $BKP_CACHE -eq 1 ]; then
	umount /cache 2> /dev/null
	mount /cache || FAIL=1
	
	if [ $FAIL -eq 1 ]; then
		BKP_CACHE=0 
	else	
		BACKUPLEGEND=$BACKUPLEGEND"C"
	fi
fi

if [ $BKP_CDROM -eq 1 ]; then
	umount /cdrom 2> /dev/null
	mount /cdrom || FAIL=1
	
	if [ $FAIL -eq 1 ]; then
		BKP_CDROM=0
	else
		BACKUPLEGEND=$BACKUPLEGEND"r"
	fi
fi

if [ $BKP_EXT2 -eq 1 ]; then
	umount /sddata 2> /dev/null
	mount /sddata || FAIL=1
	
	if [ $FAIL -eq 1 ]; then
		BKP_EXT2=0 
	else
		BACKUPLEGEND=$BACKUPLEGEND"E"
	fi
fi

BACKUPLEGEND=$BACKUPLEGEND"-"
TIMESTAMP="`date +%Y%m%d-%H%M`"
DESTDIR="$BACKUPPATH/$BACKUPPREFIX$BACKUPLEGEND$TIMESTAMP"

if [ ! -d $DESTDIR ]; then 
	mkdir -p $DESTDIR
	if [ ! -d $DESTDIR ]; then 
		echo "E: 无法创建$DESTDIR ."
		exit 1
	fi
fi

echo "备份至:"
echo "$DESTDIR"

CWD=$PWD
cd $DESTDIR

#===============================================================================
# Backup the non-filesystem partitions
#===============================================================================

for image in boot lbl logo; do
	case $image in
		boot)
			if [ $BKP_BOOT -eq 0 ]; then
				echo "内核(boot): 已跳过."
				continue
			fi
			;;
			
		lbl)
			if [ $BKP_LBL -eq 0 ]; then
				echo "引导(bootloader): 已跳过."
				continue
			fi
			;;
			
		logo)
			if [ $BKP_LOGO -eq 0 ]; then
				echo "标志(logo): 已跳过."
				continue
			fi
			;;
					
	esac
	
	DEVICEMD5=`$dump_image $image - | md5sum | awk '{ print $1 }'`
	sleep 1s
	MD5RESULT=1
	echo -n "${image}: 正在备份..."
	ATTEMPT=0
	
	while [ $MD5RESULT -eq 1 ]; do
		let ATTEMPT=$ATTEMPT+1
		$dump_image $image $DESTDIR/$image.img > /dev/null 2> /dev/null
		sync
		echo "${DEVICEMD5}  $DESTDIR/$image.img" | md5sum -c -s -
		if [ $? -eq 1 ]; then
			true
		else
			MD5RESULT=0
		fi
		
		if [ "$ATTEMPT" == "5" ]; then
			echo "failed"
			echo "E: 备份 $image 时发生严重错误, 已终止."
			exit 1
		fi
	done
	
	echo "完成"
	
	#generate the md5 sum
	echo -n "${image}: 正在创建校验文件..."
	md5sum $image.img > $image.md5
	echo "完成"
	
done

#===============================================================================
# Backup the yaffs2 filesystem partitions
#===============================================================================

for image in system data cache cdrom; do
	case $image in
		system)
			if [ $BKP_SYSTEM -eq 0 ]; then
				echo "系统(system): 已跳过."
				continue
			fi
			;;
		  
		data)
			if [ $BKP_DATA -eq 0 ]; then
				echo "数据(data): 已跳过."
				continue
			fi
			;;
		  
		cache)
			if [ $BKP_CACHE -eq 0 ]; then
				echo "缓存(cache): 已跳过."
				continue
			fi
			;;
		
		cdrom)
			if [ $BKP_CDROM -eq 0 ]; then
				echo "CD-Rom: 已跳过."
				continue
			fi
			;;    
	esac
	
	echo -n "${image}: 正在备份..."
	$mkyaffs2image /$image $DESTDIR/$image.img > /dev/null 2> /dev/null
	sync
	echo "完成"
	
	#generate the md5 sum
	echo -n "${image}: 正在创建校验文件..."
	md5sum $image.img > $image.md5
	echo "完成"
	
done

#===============================================================================
# EXT2
#===============================================================================

if [ $BKP_EXT2 -eq 1 ]; then
	echo -n "SD 卡分区(ext): 正在检查..."
	umount /sddata 2> /dev/null
	e2fsck -fp /dev/block/mmcblk0p2 > /dev/null
	echo "完成"
	mount /sddata
	echo -n "SD 卡分区(ext): 正在备份..."
	CW2=$PWD
	cd /sddata
	tar -cvf $DESTDIR/ext.tar ./ > /dev/null
	cd $CW2
	echo "完成"
	
	#generate the md5 sum
	echo -n "SD 卡分区(ext): 正在创建校验文件..."
	md5sum ext.tar > ext.md5
	echo "完成"
else
	echo "SD 卡分区(ext): 已跳过."
fi


#===============================================================================
# Compression
#===============================================================================

if [ $COMPRESS -eq 1 ]; then
	# we need about 70MiB for the intermediate storage needs
	if [ $FREEBLOCKS -le 71680 ]; then
		echo "E: 没有足够的空间来压缩备份文件(至少需要 70MB)"
		echo "备份文件未压缩"
		exit 1
	else
		echo -n "正在压缩备份文件，请稍等..."
		# we are already in $DESTDIR, start compression from the smallest files
		# to maximize space for the largest's compression, less likely to fail.
		# To decompress reverse the order.
		bzip2 -6 `ls -S -r *.img` > /dev/null
		bzip2 -6 `ls -S -r *.tar` > /dev/null
		echo "完成"
	fi
fi

#===============================================================================
# Exit
#===============================================================================

cd $CWD
echo "备份完成"

if [ $REBOOT -eq 1 ]; then
	reboot
fi
