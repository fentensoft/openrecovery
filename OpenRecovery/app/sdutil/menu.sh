#!/sbin/sh

echo "SD 卡工具" > "$MENU_FILE"
echo "返回:menu:.." >> "$MENU_FILE"
echo "扫描 FAT 分区错误:shell:/app/sdutil/fsck_msdos.sh" >> "$MENU_FILE" 
if [ -b /dev/block/mmcblk0p2 ] ; then
    echo "扫描 EXT 分区错误:shell:/app/sdutil/fsck_ext.sh" >> "$MENU_FILE" 
fi

# if [ -f /system/etc/sdext/app2ext ]; then
# 	echo "[*] App2ext:label:*" >> "$MENU_FILE"
# 	echo "[ ] Link2SD:shell:/app/sdutil/link2sd.sh" >> "$MENU_FILE"
# 	echo "[ ] None:shell:/app/sdutil/none.sh" >> "$MENU_FILE"
# fi
# if [ -f /system/etc/sdext/link2sd ]; then
# 	echo "[ ] App2ext:shell:/app/sdutil/app2ext.sh" >> "$MENU_FILE"
# 	echo "[*] Link2SD:label:*" >> "$MENU_FILE"
# 	echo "[ ] None:shell:/app/sdutil/none.sh" >> "$MENU_FILE"
# fi
# if [ ! -f /system/etc/sdext/link2sd -a ! -f /system/etc/sdext/app2ext ]; then
#         echo "[ ] App2ext:shell:/app/sdutil/app2ext.sh" >> "$MENU_FILE" 
#         echo "[ ] Link2SD:shell:/app/sdutil/link2sd.sh" >> "$MENU_FILE"
# 	echo "[*] None:label:*" >> "$MENU_FILE"                
# fi


feat=$(tune2fs -l /dev/block/mmcblk0p2 | grep 'Filesystem features: ')
if [ ! -z "$feat" ] ; then
    ext=ext2
    if echo $feat | grep -q has_journal ; then
	ext=ext3
    fi
    if echo $feat | grep -q extent ; then
	ext=ext4
    fi
    case $ext in
	ext2)
	    echo "转换 EXT2 分区为 EXT3 分区:shell:/app/sdutil/convert3.sh" >> "$MENU_FILE" 
	    echo "转换 EXT2 分区为 EXT4 分区:shell:/app/sdutil/convert4.sh" >> "$MENU_FILE" 
	    ;;
	ext3)
	    echo "转换 EXT3 分区为 EXT4 分区:shell:/app/sdutil/convert4.sh" >> "$MENU_FILE" 
	    ;;
    esac
fi

echo "保存诊断数据到 /sdcard/sdcard-info.txt:shell:/app/sdutil/diagnostics.sh" >> "$MENU_FILE"

echo "*:break:*" >> "$MENU_FILE"
echo "                 分区 引导  Id 文件系统:label:*" >> "$MENU_FILE"
echo "*:break:*" >> "$MENU_FILE"
fdisk -l /dev/block/mmcblk0 | grep ^/dev/ | cut -c 1-28,63- | while read part
do
	echo "$part:label:*" >> "$MENU_FILE"
done
echo "*:break:*" >> "$MENU_FILE"
if [ ! -z "$ext" ] ; then
    echo "EXT 分区是$ext:label:*" >> "$MENU_FILE"
fi

