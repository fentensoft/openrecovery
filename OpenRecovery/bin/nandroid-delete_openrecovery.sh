#!/sbin/bash

# $1 DIRECTORY (absolute path)

#really want to?
BACKUP_NAME=`basename "$1"`

USER_ACTION=`imenu "确认删除${BACKUP_NAME}?" 取消 确定`

if [ $USER_ACTION -eq 2 ]; then
	echo "正在删除${BACKUP_NAME}..."
	rm -fr "$1"
else
	echo "未执行更改"
fi
