#!/system/bin/sh

source ./kr-script/common/props.sh

if [ "$state" = '1' ];then
    value="true"
else
    value="false"
fi
prop="ro.config.low_ram"

magisk_set_system_prop $prop $value

if [[ "$?" = "1" ]];
then
    echo "Changed $prop via Magisk, need to reboot to take effect!"
else
    set_system_prop $prop $value
fi
