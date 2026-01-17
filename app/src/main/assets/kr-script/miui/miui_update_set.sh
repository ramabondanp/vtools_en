file="/system/etc/hosts"

if [[ "$MAGISK_PATH" != "" ]]; then
    # Magisk replacement

    if [[ ! -f $MAGISK_PATH$file ]]; then
        mkdir -p $MAGISK_PATH/system/etc
        cp $file $MAGISK_PATH$file
    fi

    if [[ $state == 1 ]]; then
        # Restore updates: remove rule
        $BUSYBOX sed -i '/127.0.0.1\ \ \ \ \ \ \ update.miui.com/'d $MAGISK_PATH$file
    else
        # Block updates: add rule
        $BUSYBOX sed -i '$a127.0.0.1\ \ \ \ \ \ \ update.miui.com' $MAGISK_PATH$file
    fi
    pm clear com.android.updater 2> /dev/null

    echo 'This action requires a reboot to take effect!'
else
    # Non-Magisk replacement

    source ./kr-script/common/mount.sh
    mount_all

    echo 'Block MIUI online update download address (requires unlocked system partition)...'

    path="/system/etc/hosts"
    $BUSYBOX sed '/127.0.0.1\ \ \ \ \ \ \ update.miui.com/'d $path > /cache/hosts

    if [[ ! $state = 1 ]]; then
        $BUSYBOX sed -i '$a127.0.0.1\ \ \ \ \ \ \ update.miui.com' /cache/hosts
        pm clear com.android.updater 2> /dev/null
        echo 'Added "127.0.0.1        update.miui.com" to hosts'
    fi;

    cp /cache/hosts $path
    chmod 0755 $path
    rm /cache/hosts
    sync

    echo 'A reboot may be required for changes to take effect!'
fi

