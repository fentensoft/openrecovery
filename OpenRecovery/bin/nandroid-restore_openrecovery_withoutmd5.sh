#!/sbin/bash

# $1 DIRECTORY (absolute path)
# $2 --all (optional)

RESTOREPATH=$1

REBOOT=0
NOTHING=1

REST_BOOT=0
REST_LBL=0
REST_LOGO=0

REST_SYSTEM=0
REST_DATA=0
REST_CACHE=0
REST_CDROM=0

REST_EXT2=0

TAGPREFIX="/tags/."

#amount of space remaining
FREEBLOCKS="`df -k /sdcard| grep sdcard | awk '{ print $4 }'`"
#error
ERROR=""

echo "+------------------------------------------+"
echo "+                                          +"
echo "+               恢 复 模 式                +"
echo "+                                          +"
echo "+------------------------------------------+"
sleep 2

#===============================================================================
# Parse the arguments
#===============================================================================

if [ -f "$TAGPREFIX"nand_rest_autoreboot ]; then
	REBOOT=1
fi

if [ "$2" == "--all" ]; then
	REST_BOOT=1
	REST_LBL=1
	REST_LOGO=1
	REST_SYSTEM=1
	REST_DATA=1
	REST_CACHE=1
	REST_CDROM=1
	REST_EXT2=1
	NOTHING=0
else

	if [ -f "$TAGPREFIX"nand_rest_system ]; then
		REST_SYSTEM=1
		NOTHING=0
	fi
	
	if [ -f "$TAGPREFIX"nand_rest_data ]; then
		REST_DATA=1
		NOTHING=0
	fi
	
	if [ -f "$TAGPREFIX"nand_rest_boot ]; then
		REST_BOOT=1
		NOTHING=0
	fi
	
	if [ -f "$TAGPREFIX"nand_rest_cache ]; then
		REST_CACHE=1
		NOTHING=0
	fi
	
	if [ -f "$TAGPREFIX"nand_rest_lbl ]; then
		REST_LBL=1
		NOTHING=0
	fi
	
	if [ -f "$TAGPREFIX"nand_rest_logo ]; then
		REST_LOGO=1
		NOTHING=0
	fi
	
	if [ -f "$TAGPREFIX"nand_rest_cdrom ]; then
		REST_CDROM=1
		NOTHING=0
	fi
	
	if [ -f "$TAGPREFIX"nand_rest_ext2 ]; then
		REST_EXT2=1
		NOTHING=0
	fi
fi

if [ $NOTHING -eq 1 ]; then
	echo "E:未执行操作"
	exit 1
fi

#===============================================================================
# Prepare the restoration
#===============================================================================

#check availbility of the utilities
erase_image=`which erase_image`
if [ "$erase_image" == "" ]; then
	erase_image=`which erase_image-or`
	if [ "$erase_image" == "" ]; then
		echo "E:未找到 erase_image 或 erase_image-or."
		exit 1
	fi
fi

flash_image=`which flash_image`
if [ "$flash_image" == "" ]; then
	flash_image=`which flash_image-or`
	if [ "$flash_image" == "" ]; then
		echo "E:未找到 flash_image 或 flash_image-or."
		exit 1
	fi
fi

unyaffs=`which unyaffs`
if [ "$unyaffs" == "" ]; then
	unyaffs=`which unyaffs-or`
	if [ "$unyaffs" == "" ]; then
		echo "E:未找到 unyaffs 或 unyaffs-or."
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
# Check compression
#===============================================================================

COMPRESSED=0

CWD=$PWD
cd "$RESTOREPATH"

if [ `ls *.bz2 2>/dev/null|wc -l` -ge 1 ]; then
	echo "此备份包为压缩存储"
	COMPRESSED=1
	
	if [ $FREEBLOCKS -le 262144 ]; then
		echo "E: 没有足够的空间来解压备份包(至少需要 256MB 空间)"
		cd $CWD
		exit 1
	else
		echo "请确认 SD 卡上至少有 256MB 或更大的空间."
	fi
fi

#===============================================================================
# Check the format (either nandroid.md5 exists or not)
# If it doesn't exist, think of it to be the Open Recovery Backup type
# and fail later when attempting to restore the partition.
#
# If old format, verify checksums now
# If mixed format, give priority to the old format
#===============================================================================
#===============================================================================
# Restore the non-filesystem partitions
#===============================================================================

for image in boot lbl logo; do
	if [ ! -f $image.img* ]; then
		echo "${image}: 无法执行备份."
		continue
	fi
	
	case $image in
		boot)
			if [ $REST_BOOT -eq 0 ]; then
				echo "内核(boot): 已跳过."
				continue
			fi
			;;
			
		lbl)
			if [ $REST_LBL -eq 0 ]; then
				echo "引导(lbl): 已跳过."
				continue
			fi
			;;
			
		logo)
			if [ $REST_LOGO -eq 0 ]; then
				echo "标志(logo): 已跳过."
				continue
			fi
			;;
			
	esac
	
	if [ $OPEN_RCVR_BKP -eq 1 ]; then  
	
		if [ $COMPRESSED -eq 1 ]; then
			echo -n "${image}: 正在解压..."
			bunzip2 -c $image.img.bz2 > $image.img
			echo "完成"
		fi
	fi
	
	echo -n "${image}: 正在恢复..."
	$flash_image $image $image.img > /dev/null 2> /dev/null
	echo "完成"
	
	if [ $COMPRESSED -eq 1 ]; then
		#delete the uncompressed part
		rm $image.img
	fi
	
done

#===============================================================================
# Restore the yaffs2 filesystem partitions
#===============================================================================

for image in system data cache cdrom; do
	if [ ! -f $image.img* ]; then
		echo "${image}: 无法执行备份."
		continue
	fi
	
	case $image in
		system)
			if [ $REST_SYSTEM -eq 0 ]; then
				echo "系统(system): 已跳过."
				continue
			fi
		  ;;
	    
		data)
			if [ $REST_DATA -eq 0 ]; then
				echo "数据(data): 已跳过."
				continue
			fi
			;;
	    
		cache)
			if [ $REST_CACHE -eq 0 ]; then
				echo "缓存(cache): 已跳过."
				continue
			fi
			;;
	
		cdrom)
			if [ $REST_CDROM -eq 0 ]; then
				echo "CD-Rom: 已跳过."
				continue
			fi
			;;
	esac
	
	umount /$image 2> /dev/null
	mount /$image 2> /dev/null
	
	if [ $? -ne 0 ]; then
		echo "E:无法挂载 /$image."
		echo "${image}: 无法恢复."
		ERROR="${ERROR}${image}: 挂载失败.\n"
		continue
	fi
	
	if [ $OPEN_RCVR_BKP -eq 1 ]; then  
	
		if [ $COMPRESSED -eq 1 ]; then
			echo -n "${image}: 正在解压..."
			bunzip2 -c $image.img.bz2 > $image.img
			echo "完成"
		fi
	fi
	
	if [ "$image" == "system" ]; then
		if [ -d /system/persistent ]; then
			echo -n "${image}: 正在备份..."
			
			mkdir /system_persistent > /dev/null
			cp -a /system/persistent /system_persistent > /dev/null
			
			#check .sh tag
			if [ -f /system/persistent/.persistent_sh ]; then
				cp -a /system/bin/sh /system_persistent/sh > /dev/null
			fi
			
			echo "完成"
		fi
	fi
	
	umount /$image 2> /dev/null
	echo -n "${image}: 正在删除..."
	
	if [ "$image" == "data" ]; then
		my_image="userdata"
	else
		my_image=$image	
	fi
		
	$erase_image $my_image > /dev/null 2> /dev/null
	echo "完成"
	mount /$image
	echo -n "${image}: 正在恢复..."
	$unyaffs $image.img /$image	> /dev/null 2> /dev/null
	echo "完成"
	
	if [ "$image" == "system" ]; then
		if [ -d /system_persistent ]; then
			echo -n "${image}: 正在恢复..."
			
			if [ -d /system/persistent ]; then
				rm -r /system/persistent > /dev/null
			fi
			
			cp -a /system_persistent/persistent /system > /dev/null
			
			#check .sh tag (can be checked in the copied one)
			if [ -f /system_persistent/persistent/.persistent_sh ]; then
				rm /system/bin/sh > /dev/null
				cp -a /system_persistent/sh /system/bin/sh  > /dev/null
			fi
			
			rm -r /system_persistent > /dev/null
			
			echo "完成"
		fi
	fi
	
	if [ $COMPRESSED -eq 1 ]; then
		#delete the uncompressed part
		rm $image.img
	fi
	
done

#===============================================================================
# EXT2
#===============================================================================

if [ ! -f ext.tar ]; then
	echo "SD 卡分区(ext): 无法执行备份."
else 
	if [ $REST_EXT2 -eq 0 ]; then
		echo "SD 卡分区(ext): 已跳过."
	elif [ ! -d /sddata ]; then
		echo "E: 未找到 SD 卡分区(ext)"
		echo "SD 卡分区(ext): 无法恢复."
		ERROR="${ERROR} SD 卡分区(ext): 无法恢复不存在的分区.\n"
	else	

        umount /sddata 2> /dev/null
      	e2fsck -fp /dev/block/mmcblk0p2 > /dev/null
	      echo "done"
 				echo -n "SD 卡分区(ext): 正在删除..."
        mount /sddata
        rm -rf /sddata/*
	        	echo "完成"
	        	echo -n "SD 卡分区(ext): 正在恢复..."
				CW2=$PWD
				cd /sddata
				tar -xvf $RESTOREPATH/ext.tar ./ > /dev/null
				cd "$CW2"
		echo "完成"
				
				if [ $COMPRESSED -eq 1 ]; then
					#delete the uncompressed part
					rm ext.tar
		fi
	fi
fi

#===============================================================================
# Exit
#===============================================================================

cd "$CWD"
if [ "$ERROR" != "" ]; then
	echo "+----------------------------------------------+"
	echo "+                                              +"
	echo "+                 恢复中的错误                  +"
	echo "+                                              +"
	echo "+----------------------------------------------+"
	
	printf "$ERROR"
	
else
	echo "恢复成功."
	
	if [ $REBOOT -eq 1 ]; then
		reboot
	fi
	
fi

