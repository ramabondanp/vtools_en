dir=/system/usr/keylayout
file=$dir/gpio-keys.kl

if [[ "$state" != "" ]] && [[ "$state" != "AI" ]]; then
    if [[ "$MAGISK_PATH" != "" ]]; then
        if [[ ! -f $MAGISK_PATH$file ]]; then
            mkdir -p $MAGISK_PATH$dir
            cp $file $MAGISK_PATH$file
        fi
        # busybox sed -i "s/^original/replace-with/" file path

        busybox sed -i "s/^key 689.*/key 689   $state/" $MAGISK_PATH$file
        echo $state
        echo 'This change requires a reboot to take effect!' 1>&2
    else
        echo 'Add-on module not installed; cannot apply changes.' 1>&2
    fi
else
    if [[ -f $MAGISK_PATH$file ]]; then
        rm $MAGISK_PATH$file
        echo 'This change requires a reboot to take effect!' 1>&2
    fi
fi
