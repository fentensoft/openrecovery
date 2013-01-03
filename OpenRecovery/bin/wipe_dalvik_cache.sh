#!/sbin/bash

rm -Rf /data/dalvik-cache/*
[ -d /sddata/dalvik-cache ] && rm -Rf /sddata/dalvik-cache/*
echo "清除虚拟机缓存成功."
