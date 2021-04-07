source ./kr-script/common/props.sh

prop="ro.miui.has_real_blur"

magisk_set_system_prop $prop $state

if [[ "$?" = "1" ]];
then
    echo "Changed $prop via Magisk, need to reboot to take effect!"
else
    set_system_prop $prop $state
fi
