#!/system/bin/sh

#[dalvik.vm.boot-dex2oat-threads]: [8]
#[dalvik.vm.dex2oat-threads]: [4]
#[dalvik.vm.image-dex2oat-threads]: [4]
#[ro.sys.fw.dex2oat_thread_count]: [4]

filepath=""
if [[ -n "$MAGISK_PATH" ]];
then
    filepath="${MAGISK_PATH}/system.prop"
    echo "You have already installed Magisk, this modification will be done through the operation"
    echo 'Step1.Mount System as Read/Write (skip)...'
else
    filepath="/system/build.prop"

    echo 'Step1.Mount System as Read/Write...'

    source ./kr-script/common/mount.sh
    mount_all

    if [[ ! -e "/system/build.prop.bak" ]]; then
        cp /system/build.prop /system/build.prop.bak
        chmod 0755 /system/build.prop.bak
    fi;
fi;

echo 'Step2.Remove existing configuration'
$BUSYBOX sed '/dalvik.vm.boot-dex2oat-threads=.*/'d $filepath > "/data/build.prop"
$BUSYBOX sed -i '/dalvik.vm.dex2oat-threads=.*/'d "/data/build.prop"
$BUSYBOX sed -i '/dalvik.vm.image-dex2oat-threads=.*/'d "/data/build.prop"
$BUSYBOX sed -i '/ro.sys.fw.dex2oat_thread_count=.*/'d "/data/build.prop"


echo 'Step2.Update configuration'
if [[ -n $boot ]]; then
    $BUSYBOX sed -i "\$adalvik.vm.boot-dex2oat-threads=$boot" /data/build.prop;
    $BUSYBOX sed -i "\$aro.sys.fw.dex2oat_thread_count=$boot" /data/build.prop;
    setprop dalvik.vm.boot-dex2oat-threads $boot 2> /dev/null
    setprop ro.sys.fw.dex2oat_thread_count $boot 2> /dev/null
fi;

if [[ -n $dex2oat ]]; then
    $BUSYBOX sed -i "\$adalvik.vm.dex2oat-threads=$dex2oat" /data/build.prop;
    setprop dalvik.vm.dex2oat-threads $dex2oat 2> /dev/null
fi;

if [[ -n $image ]]; then
    $BUSYBOX sed -i "\$adalvik.vm.image-dex2oat-threads=$image" /data/build.prop;
    setprop dalvik.vm.image-dex2oat-threads $image 2> /dev/null
fi;

echo 'Step3.Write to file'
cp /data/build.prop $filepath
chmod 0755 $filepath
rm /data/build.prop

echo 'Operation completed...'
echo 'Now, please reboot your phone to make the changes take effect!'
