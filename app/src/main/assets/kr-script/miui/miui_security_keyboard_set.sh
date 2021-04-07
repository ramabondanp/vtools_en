#!/system/bin/sh

source ./kr-script/common/props.sh

prop="ro.miui.has_security_keyboard"

magisk_set_system_prop $prop $state

if [[ "$?" = "1" ]];
then
    echo "Changed by Magisk $prop，A reboot is required to take effect!"
else
    set_system_prop $prop $state
fi

