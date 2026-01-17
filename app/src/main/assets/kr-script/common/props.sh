#!/system/bin/sh
source ./kr-script/common/mount.sh

# Read whether the prop value is 1 from build.prop
cat_prop_is_1()
{
    prop="$1"
    g="^$prop="
    if [[ -d "$MAGISK_PATH" ]] && [[ -f "$MAGISK_PATH/system.prop" ]]
    then
        status=`grep "$g" $MAGISK_PATH/system.prop | cut -d '=' -f2`
    fi
    if [ "$status" = "1" ] || [ "$status" = "true" ]; then
        echo 1;
        exit 0
    elif [ "$status" = "0" ] || [ "$status" = "false" ]; then
        echo 0;
        exit 0
    fi

    status=`grep "$g" /system/build.prop|cut -d '=' -f2`
    if [ "$status" = "1" ] || [ "$status" = "true" ]; then
        echo 1;
        exit 0
    fi


    if [[ -f "/vendor/build.prop" ]]
    then
        status=`grep "$g" /vendor/build.prop | cut -d '=' -f2`
    fi
    if [ "$status" = "1" ] || [ "$status" = "true" ]; then
        echo 1;
        exit 0
    fi

    echo 0
}

# Read whether the prop value is 0 from build.prop
cat_prop_is_0()
{
    prop="$1"
    g="^$prop="
    if [[ -d "$MAGISK_PATH" ]] && [[ -f "$MAGISK_PATH/system.prop" ]]
    then
        status=`grep "$g" $MAGISK_PATH/system.prop | cut -d '=' -f2`
    fi
    if [ "$status" = "0" ] || [ "$status" = "false" ]; then
        echo 1;
        exit 0
    elif [ "$status" = "1" ] || [ "$status" = "true" ]; then
        echo 0;
        exit 0
    fi

    status=`grep "$g" /system/build.prop|cut -d '=' -f2`
    if [ "$status" = "0" ] || [ "$status" = "false" ]; then
        echo 1;
        exit 0
    fi

    if [[ -f "/vendor/build.prop" ]]
    then
        status=`grep "$g" /vendor/build.prop | cut -d '=' -f2`
    fi
    if [ "$status" = "0" ] || [ "$status" = "false" ]; then
        echo 1;
        exit 0
    fi

    echo 0
}

magisk_set_system_prop() {
    if [[ -d "$MAGISK_PATH" ]];
    then
        echo "Magisk detected; this change will be applied through Magisk"
        $BUSYBOX sed -i "/$1=/"d "$MAGISK_PATH/system.prop"
        $BUSYBOX echo -e "\n$1=$2" >> "$MAGISK_PATH/system.prop"
        setprop "$1" "$2" 2> /dev/null
        return 1
    fi;
    return 0
}

set_system_prop() {
    local prop=$1
    local state=$2

    local path="/system/build.prop"
    if [[ -f /vendor/build.prop ]] && [[ -n `cat /vendor/build.prop | grep $prop=` ]]
    then
        local path="/vendor/build.prop"
    fi

    echo 'To use this feature, the system partition must be unlocked, otherwise changes will be ineffective.'
    echo 'The built-in system root may not support this feature.'

    echo 'Step1. Mount /system as read-write'
    mount_all

    $BUSYBOX sed "/$prop=/"d $path > /cache/build.prop
    $BUSYBOX echo  -e "\n$prop=$state" >> /cache/build.prop
    echo "Step2. Update $prop=$state"

    echo 'Step3. Write file'
    cp /cache/build.prop $path
    chmod 0755 $path

    echo 'Step4. Remove temporary file'
    rm /cache/build.prop
    sync

    echo ''
    echo 'Takes effect after reboot!'
}
