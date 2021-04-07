#!/system/bin/sh

echo 'To use this function, you need to unlock the system partition, otherwise the modification is invalid!'
echo 'MIUI comes with ROOT can not use this function'

echo 'Mount/system for rw'
source ./kr-script/common/mount.sh
mount_all

model=`getprop ro.product.device`
for config in `ls "/system/etc/device_features/$model.xml"`
do
    if [ ! -f "$config.bak" ]; then
        echo 'Backup files...'
        cp $config $config.bak
    fi;

    echo 'Modify file...'
    $BUSYBOX sed -i '/.*<!--whether round corner-->/'d "$config"
    $BUSYBOX sed -i '/.*<bool name="support_round_corner">.*<\/bool>/'d "$config"

    if [[ $state = 1 ]]; then
        $BUSYBOX sed -i '2a \ \ \ \ <!--whether round corner-->' $config
        $BUSYBOX sed -i '3a \ \ \ \ <bool name="support_round_corner">true<\/bool>' $config
    else
        $BUSYBOX sed -i '2a \ \ \ \ <!--whether round corner-->' $config
        $BUSYBOX sed -i '3a \ \ \ \ <bool name="support_round_corner">false<\/bool>' $config
    fi;

    sync
    chmod 755 $config

    echo 'Operation completed, please restart your phone!'
    return
done
