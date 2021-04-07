#!/system/bin/sh


if [[ $dirty_background_ratio -gt 30 ]]
then
    echo 'Note: The "minimum buffer size" seems to have been adjusted a bit too large'
fi

if [[ $dirty_background_ratio -gt $dirty_ratio ]]
then
    echo 'Note: Performance problems may occur if the "minimum buffer size" is larger than the "maximum buffer size".' 1>&2
fi

if [[ $dirty_writeback_centisecs -gt $dirty_expire_centisecs ]]
then
    echo 'Note: Performance problems may occur if the "cache flush frequency" is greater than the "cache expiration time".' 1>&2
fi

function update_kernel_prop() {
    local value=$1
    local kernel_prop=$2
    if [[ -f "$kernel_prop" ]]
    then
        echo "echo $value > $kernel_prop"
        echo "$value" > "$kernel_prop"
        chmod 644 "$kernel_prop"
    fi
}

#if [[ -f /proc/sys/vm/laptop_mode ]]
#then
#    echo 1 > /proc/sys/vm/laptop_mode
#fi
update_kernel_prop $dirty_background_ratio /proc/sys/vm/dirty_background_ratio
update_kernel_prop $dirty_ratio /proc/sys/vm/dirty_ratio
update_kernel_prop $dirty_expire_centisecs /proc/sys/vm/dirty_expire_centisecs
update_kernel_prop $dirty_writeback_centisecs /proc/sys/vm/dirty_writeback_centisecs

if [[ -f /sys/block/sda/queue/read_ahead_kb ]]
then
    echo "echo $read_ahead_kb > /sys/block/sda/queue/read_ahead_kb"
    echo $read_ahead_kb > /sys/block/sda/queue/read_ahead_kb
    if [[ $read_ahead_kb -gt 512 ]]
    then
        echo 'Note: Read buffer tuning is too large, which may reduce 4K random read performance' 1>&2
    fi
elif [[ -f /sys/block/mmcblk0/queue/read_ahead_kb ]]
then
    echo "echo $read_ahead_kb > /sys/block/mmcblk0/queue/read_ahead_kb"
    echo $read_ahead_kb > /sys/block/mmcblk0/queue/read_ahead_kb
    if [[ $read_ahead_kb -gt 512 ]]
    then
        echo 'Note: Read buffer tuning is too large, which may reduce 4K random read performance' 1>&2
    fi
fi
