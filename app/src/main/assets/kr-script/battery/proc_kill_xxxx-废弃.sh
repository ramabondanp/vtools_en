#!/system/bin/sh

function killproc()
{
    stop "$1" 2> /dev/null
    killall -9 "$1" 2> /dev/null
}

killproc cnss_diag
killproc subsystem_ramdump_system
killproc subsystem_ramdump
killproc tcpdump
killproc logd
killproc adbd
# killproc magiskd


killproc woodpeckerd
killproc debuggerd
killproc debuggerd64
killproc atfwd
killproc perfd
killproc logd

if [[ -e /sys/zte_power_debug/switch ]]; then
    echo 0 > /sys/zte_power_debug/switch
fi
if [[ -e /sys/zte_power_debug/debug_enabled ]]; then
    echo N > /sys/kernel/debug/debug_enabled
fi


#stop thermal-engine 2> /dev/null
#killall -9 magiskd 2> /dev/null

echo 'Execution complete, effective immediately!'

echo 'Note: This operation will not work after restarting your phone!'