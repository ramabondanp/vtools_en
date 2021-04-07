dir=/system/usr/keylayout
file=$dir/gpio-keys.kl

if [[ "$state" != "" ]] && [[ "$state" != "AI" ]]; then
    if [[ "$MAGISK_PATH" != "" ]]; then
        if [[ ! -f $MAGISK_PATH$file ]]; then
            mkdir -p $MAGISK_PATH$dir
            cp $file $MAGISK_PATH$file
        fi
        # busybox sed -i "s/^原内容/替换为/" 文件路径

        busybox sed -i "s/^key 689.*/key 689   $state/" $MAGISK_PATH$file
        echo $state
        echo 'This modification, need to reboot the phone to take effect!' 1>&2
    else
        echo 'No add-on module installed, no changes can be applied~' 1>&2
    fi
else
    if [[ -f $MAGISK_PATH$file ]]; then
        rm $MAGISK_PATH$file
        echo 'This modification, need to reboot the phone to take effect!' 1>&2
    fi
fi