#!/sbin/bash

TAGPREFIX="/tags/."

BACKUP_NAME=`basename "$1"`

echo "选项：$BACKUP_NAME" > "$MENU_FILE"
echo "返回:menu:.." >> "$MENU_FILE"
echo "还原全部:shell:nandroid-restore_openrecovery.sh \"$1\" --all" >> "$MENU_FILE"
echo "还原选择项:shell:nandroid-restore_openrecovery.sh \"$1\"" >> "$MENU_FILE"
echo "还原全部(不效验 md5):shell:nandroid-restore_openrecovery1.sh \"$1\" --all" >> "$MENU_FILE"
echo "还原选择项(不效验 md5):shell:nandroid-restore_openrecovery1.sh \"$1\"" >> "$MENU_FILE"
echo "设置:break:*" >> "$MENU_FILE"
echo "完成后重启:tag:nand_rest_autoreboot" >> "$MENU_FILE"
echo "分区:break:*" >> "$MENU_FILE"

CWD=$PWD
cd "$1"

for image in system data cache cust cdrom boot bpsw lbl logo devtree ext2; do
	if [ `ls $image* 2>/dev/null | wc -l` == 0 ]; then
  	continue
  fi
  
  case $image in
    system)
				echo "系统(system):tag:nand_rest_system" >> "$MENU_FILE"
			;;
    data)
				echo "数据(data):tag:nand_rest_data" >> "$MENU_FILE"
			;;   
    cache)
				echo "缓存(cache):tag:nand_rest_cache" >> "$MENU_FILE"
			;;   
    cdrom)
				echo "CD-Rom:tag:nand_rest_cdrom" >> "$MENU_FILE"
			;;   
    boot)
				echo "内核(boot):tag:nand_rest_boot" >> "$MENU_FILE"
			;;
    lbl)
				echo "引导系统(Bootloader):tag:nand_rest_lbl" >> "$MENU_FILE"
			;;
    logo)
				echo "标志(Logo):tag:nand_rest_logo" >> "$MENU_FILE"
			;;
    ext2)
				echo "SD 卡分区(ext2):tag:nand_rest_ext2" >> "$MENU_FILE"
			;;
  esac
  
done

cd "$PWD"
rm -f "$TAGPREFIX"nand_rest_*
