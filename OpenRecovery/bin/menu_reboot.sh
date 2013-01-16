#!/sbin/bash

echo "重启模式" > "$MENU_FILE"
echo "返回:menu:.." >> "$MENU_FILE"
echo "*:break:*" >> "$MENU_FILE"
echo "关闭手机:shell:halt.sh" >> "$MENU_FILE"
echo "引导模式:shell:reboot-btl.sh" >> "$MENU_FILE"
echo "恢复模式:shell:reboot-rcvr.sh" >> "$MENU_FILE"
