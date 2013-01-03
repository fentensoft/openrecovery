#!/sbin/bash

echo "备份" > "$MENU_FILE"
echo "返回:menu:.." >> "$MENU_FILE"
echo "备份全部:shell:nandroid-backup_openrecovery.sh --all" >> "$MENU_FILE"
echo "备份选择项:shell:nandroid-backup_openrecovery.sh" >> "$MENU_FILE"
echo "设置:break:*" >> "$MENU_FILE"
echo "完成后重启:tag:nand_bkp_autoreboot" >> "$MENU_FILE"
echo "压缩备份包:tag:nand_bkp_compress" >> "$MENU_FILE"
echo "分区:break:*" >> "$MENU_FILE"
echo "系统(system):tag:nand_bkp_system" >> "$MENU_FILE"
echo "数据(data):tag:nand_bkp_data" >> "$MENU_FILE"
echo "缓存(cache):tag:nand_bkp_cache" >> "$MENU_FILE"
echo "CD-Rom:tag:nand_bkp_cdrom" >> "$MENU_FILE"
echo "内核(boot):tag:nand_bkp_boot" >> "$MENU_FILE"
echo "引导(Bootloader):tag:nand_bkp_lbl" >> "$MENU_FILE"
echo "标志(Logo):tag:nand_bkp_logo" >> "$MENU_FILE"

#use /sddata to see, as the nandroid is configured to mount /sddata
if [ -d /sddata ]; then
	echo "SD数据(ext2):tag:nand_bkp_ext2" >> "$MENU_FILE"
fi
