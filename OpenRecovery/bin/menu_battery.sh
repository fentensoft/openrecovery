#!/sbin/sh

CAP=`cat /sys/class/power_supply/battery/capacity`
CAP2=`cat /sys/class/power_supply/battery/charge_counter`
STATUS=`cat /sys/class/power_supply/battery/status`

echo "Battery - ${CAP}% raw / ${CAP2}% fine (${STATUS})" > "$MENU_FILE"
echo "返回:menu:.." >> "$MENU_FILE"
