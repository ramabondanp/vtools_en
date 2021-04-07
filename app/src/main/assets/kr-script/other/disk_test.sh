#!/system/bin/sh

cache=/data/testtmp


function backup_vm_params() {
    if [[ -f /proc/sys/vm/laptop_mode ]]
    then
        laptop_mode=`cat /proc/sys/vm/laptop_mode`
    fi
    if [[ -f /proc/sys/vm/dirty_background_ratio ]]
    then
        dirty_background_ratio=`cat /proc/sys/vm/dirty_background_ratio`
    fi
    if [[ -f /proc/sys/vm/dirty_ratio ]]
    then
        dirty_ratio=`cat /proc/sys/vm/dirty_ratio`
    fi
    if [[ -f /proc/sys/vm/dirty_expire_centisecs ]]
    then
        dirty_expire_centisecs=`cat /proc/sys/vm/dirty_expire_centisecs`
    fi
    if [[ -f /proc/sys/vm/dirty_writeback_centisecs ]]
    then
        dirty_writeback_centisecs=`cat /proc/sys/vm/dirty_writeback_centisecs`
    fi
}

function restore_vm_params()
{
    if [[ -f /proc/sys/vm/laptop_mode ]]
    then
        echo $laptop_mode > /proc/sys/vm/laptop_mode
    fi
    if [[ -f /proc/sys/vm/dirty_background_ratio ]]
    then
        echo $dirty_background_ratio > /proc/sys/vm/dirty_background_ratio
    fi
    if [[ -f /proc/sys/vm/dirty_ratio ]]
    then
        echo $dirty_ratio > /proc/sys/vm/dirty_ratio
    fi
    if [[ -f /proc/sys/vm/dirty_expire_centisecs ]]
    then
        echo $dirty_expire_centisecs > /proc/sys/vm/dirty_expire_centisecs
    fi
    if [[ -f /proc/sys/vm/dirty_writeback_centisecs ]]
    then
        echo $dirty_writeback_centisecs > /proc/sys/vm/dirty_writeback_centisecs
    fi
}

function modify_vm_params()
{
    if [[ -f /proc/sys/vm/laptop_mode ]]
    then
        echo 1 > /proc/sys/vm/laptop_mode
    fi
    if [[ -f /proc/sys/vm/dirty_background_ratio ]]
    then
        echo 75 > /proc/sys/vm/dirty_background_ratio
    fi
    if [[ -f /proc/sys/vm/dirty_ratio ]]
    then
        echo 75 > /proc/sys/vm/dirty_ratio
    fi
    if [[ -f /proc/sys/vm/dirty_expire_centisecs ]]
    then
        echo 60000 > /proc/sys/vm/dirty_expire_centisecs
    fi
    if [[ -f /proc/sys/vm/dirty_writeback_centisecs ]]
    then
        echo 60000 > /proc/sys/vm/dirty_writeback_centisecs
    fi
}

function modify_vm_params2()
{
    if [[ -f /proc/sys/vm/laptop_mode ]]
    then
        echo 1 > /proc/sys/vm/laptop_mode
    fi
    if [[ -f /proc/sys/vm/dirty_background_ratio ]]
    then
        echo 10 > /proc/sys/vm/dirty_background_ratio
    fi
    if [[ -f /proc/sys/vm/dirty_ratio ]]
    then
        echo 20 > /proc/sys/vm/dirty_ratio
    fi
    if [[ -f /proc/sys/vm/dirty_expire_centisecs ]]
    then
        echo 5000 > /proc/sys/vm/dirty_expire_centisecs
    fi
    if [[ -f /proc/sys/vm/dirty_writeback_centisecs ]]
    then
        echo 2000 > /proc/sys/vm/dirty_writeback_centisecs
    fi
}

echo 'Testing requires more than 2G of available storage space'
echo 'It is recommended to open the CPU to the highest performance and then test it!'
echo 'A synchronous write will invalidate the cache gain and better reflect the true performance of the memory chip!'
echo ''

rm -f $cache 2> /dev/null
echo '\nCache write test...'
sync
echo 3 > /proc/sys/vm/drop_caches
echo "progress:[-1/5]"
backup_vm_params
modify_vm_params
$BUSYBOX dd if=/dev/zero of=$cache bs=1048576 count=1024 conv=sync 1>&2
sync
echo 3 > /proc/sys/vm/drop_caches

modify_vm_params2
rm -f $cache 2> /dev/null
echo '\nRegular write test...'
sync
echo 3 > /proc/sys/vm/drop_caches
echo "progress:[-1/5]"

$BUSYBOX dd if=/dev/zero of=$cache bs=1048576 count=1024 conv=sync 1>&2
rm -f $cache 2> /dev/null
sync
echo 3 > /proc/sys/vm/drop_caches
echo "progress:[1/5]"

echo '\nSync Write Test...'
$BUSYBOX dd if=/dev/zero of=$cache bs=1048576 count=1024 conv=fsync 1>&2
sync
echo 3 > /proc/sys/vm/drop_caches
echo "progress:[2/5]"
restore_vm_params

if [[ -e /dev/block/sda ]];
then
    echo '\nCache Read Test...'
    $BUSYBOX hdparm -T /dev/block/sda 1>&2
    echo "progress:[3/5]"

    echo '\nGeneral Read Test...'
    $BUSYBOX hdparm -t /dev/block/sda 1>&2
    echo "progress:[4/5]"
elif [[ -e /dev/block/mmcblk0 ]]
then
    echo '\nGeneral Read Test...'
    $BUSYBOX dd if=/dev/block/mmcblk0 of=/dev/null bs=1048576 count=2048 1>&2
    echo "progress:[4/5]"
fi

echo ''
echo 'End, recycle cache'
rm -f $cache 2> /dev/null
sync
echo 3 > /proc/sys/vm/drop_caches
echo ''
echo "progress:[5/5]"