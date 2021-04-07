#!/system/bin/sh

source ./kr-script/common/props.sh

prop="miui.usb.dialog"

value="1"
if [[ "$state" = "1" ]]; then
    value="0"
fi

magisk_set_system_prop $prop $value
if [[ "$?" = "1" ]];
then
    echo "Changed by Magisk $prop, need to reboot to take effect!"
else
    set_system_prop $prop $value
fi

