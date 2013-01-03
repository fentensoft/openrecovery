#!/sbin/bash

# arguments
# $1 the phone suffix
#
# SHOLS - Milestone (A853, XT702)
# STR - Milestone XT (XT720)
# STCU  - Sholes Tablet (XT701)

echo "正在加载恢复系统..."

#run the initializers
#=======================================

INIT_DIR=/sdcard/OpenRecovery/init

if [ -d $INIT_DIR ]
then
	for INIT in "$INIT_DIR/"*.sh; do
		#omit if there is none
		if [ "$INIT" != "$INIT_DIR/*.sh" ]
		then
			BN_INIT=`basename "$INIT"`
			"$INIT"
		fi
	done
fi

#initialize the application menu
#=======================================

export APP_MENU_FILE="/menu/app.menu"

echo "程序菜单" > "$APP_MENU_FILE"
echo "返回:menu:.." >> "$APP_MENU_FILE"

if [ -d /sdcard/OpenRecovery/app/ ]
then

	mkdir /app
	cp -fR /sdcard/OpenRecovery/app/ /
	chmod -R 0755 /app
	
	APP_DIR=/app

	for APPINIT in "$APP_DIR/"*.sh; do
		#omit if there is none
		if [ "$APPINIT" != "$APP_DIR/*.sh" ]
		then
			BN_APPINIT=`basename "$APPINIT"`
			"$APPINIT"
		fi
	done
fi

#initialize the Nandroid menu
#=======================================
export NAND_MENU_FILE="/menu/nand.menu"

echo "备份 / 还原" > "$NAND_MENU_FILE"
echo "返回:menu:.." >> "$NAND_MENU_FILE"
echo "备份:scripted_menu:nandroid_backup.menu:menu_nandroid_backup.sh" >> "$NAND_MENU_FILE"
echo "还原:scripted_menu:nandroid_restore.menu:menu_nandroid_restore.sh" >> "$NAND_MENU_FILE"
echo "删除:scripted_menu:nandroid_delete.menu:menu_nandroid_delete.sh" >> "$NAND_MENU_FILE"

#initialize the Settings menu
#=======================================
export SETTINGS_MENU_FILE="/menu/settings.menu"

echo "系统设置" > "$SETTINGS_MENU_FILE"
echo "返回:menu:.." >> "$SETTINGS_MENU_FILE"
echo "Bash 设置:scripted_menu:bash.menu:menu_bash.sh" >> "$SETTINGS_MENU_FILE"
echo "主题设置:scripted_menu:theme.menu:menu_theme.sh" >> "$SETTINGS_MENU_FILE"

echo "时区设置:scripted_menu:timezone.menu:menu_timezone.sh" >> "$SETTINGS_MENU_FILE"

#initialize the main menu
#=======================================

echo "正在创建主菜单..."

MAIN_MENU_FILE=/menu/init.menu

echo "主菜单" > "$MAIN_MENU_FILE"
echo "重新启动:reboot:*" >> "$MAIN_MENU_FILE"
echo "关闭手机:shell:halt.sh" >> "$MAIN_MENU_FILE"
echo "引导模式:shell:reboot-btl.sh" >> "$MAIN_MENU_FILE"
echo "恢复模式:shell:reboot-rcvr.sh" >> "$MAIN_MENU_FILE"
echo "设置:menu:settings.menu" >> "$MAIN_MENU_FILE"
echo "USB 大容量存储模式:shell:usb_mass_storage.sh" >> "$MAIN_MENU_FILE"
echo "USB 大容量存储模式(完全访问):shell:usb_mass_storage_complete_access.sh" >> "$MAIN_MENU_FILE"

echo "备份 / 还原:menu:nand.menu" >> "$MAIN_MENU_FILE"
echo "程序菜单:menu:app.menu" >> "$MAIN_MENU_FILE"

#only if not bootstrap
if [ ! -f /etc/bootstrap ]; then
	echo "获取权限:shell:root.sh" >> "$MAIN_MENU_FILE"
fi

echo "运行脚本:scripted_menu:runscript.menu:menu_scripts.sh" >> "$MAIN_MENU_FILE"
echo "安装升级包:scripted_menu:customupdate.menu:menu_updates.sh" >> "$MAIN_MENU_FILE"
echo "清除虚拟机缓存:shell:wipe_dalvik_cache.sh" >> "$MAIN_MENU_FILE"
echo "清除全部数据(恢复出厂设置):wipe_data:*" >> "$MAIN_MENU_FILE"
echo "清除系统缓存:wipe_cache:*" >> "$MAIN_MENU_FILE"
echo "电池状态:scripted_menu:battery.menu:menu_battery.sh" >> "$MAIN_MENU_FILE"

echo "完成."
