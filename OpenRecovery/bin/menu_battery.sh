#!/sbin/sh

CAP=`cat /sys/class/power_supply/battery/charge_counter`
STATUS=`cat /sys/class/power_supply/battery/status`

echo "电池电量 - ${CAP}% (${STATUS})" > "$MENU_FILE"
echo "返回:menu:.." >> "$MENU_FILE"
