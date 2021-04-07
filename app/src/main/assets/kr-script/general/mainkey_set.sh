source ./kr-script/common/props.sh

if [[ $state = 1 ]]
then
    value=0
else
    value=1
fi
prop="qemu.hw.mainkeys"

magisk_set_system_prop $prop $value

if [[ "$?" = "1" ]];
then
    echo "Changed $prop via Magisk, need to reboot to take effect!"
else
    set_system_prop $prop $value
fi
