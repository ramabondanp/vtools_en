#!/system/bin/sh

source ./kr-script/common/props.sh

prop="ro.miui.notch"

magisk_set_system_prop $prop $state

if [[ "$?" = "1" ]];
then
    echo "Changed $prop via Magisk, need to reboot to take effect!"
else
    set_system_prop $prop $state
fi
