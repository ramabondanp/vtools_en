#!/system/bin/sh

settings put global low_power $state;
settings put global low_power_sticky $state;

# Whether or not app auto restriction is enabled. When it is enabled, settings app will  auto restrict the app if it has bad behavior(e.g. hold wakelock for long time).
# [app_auto_restriction_enabled]

#Whether or not to enable Forced App Standby on small battery devices.         * Type: int (0 for false, 1 for true)
# forced_app_standby_for_small_battery_enabled

# Feature flag to enable or disable the Forced App Standby feature.         * Type: int (0 for false, 1 for true)
# forced_app_standby_enabled

# Whether or not to enable the User Absent, Radios Off feature on small battery devices.         * Type: int (0 for false, 1 for true)
# user_absent_radios_off_for_small_battery_enabled

function killproc()
{
    stop "$1" 2> /dev/null
    killall -9 "$1" 2> /dev/null
}

echo 'Power saving mode may not be available during charging'
echo '-'

if [[ $state = "1" ]]
then
    echo "Enabling automatic app restrictions may require Android Pie"
    settings put global app_auto_restriction_enabled true

    echo "Turn on the application to force standby"
    settings put global forced_app_standby_enabled 1

    echo "Turn on the application standby"
    settings put global app_standby_enabled 1

    echo "Turn on mandatory standby for small capacity battery device applications"
    settings put global forced_app_standby_for_small_battery_enabled 1

    ai=`settings get system ai_preload_user_state`
    if [[ ! "$ai" = "null" ]]
    then
      echo "Turn off ai preload in MIUI10"
      settings put system ai_preload_user_state 0
    fi

    echo "Turn on Android's native power saving mode"
    settings put global low_power 1
    settings put global low_power_sticky 1

    echo "Close debugging services and logging processes"
    killproc woodpeckerd
    # killproc debuggerd
    # killproc debuggerd64
    killproc atfwd
    killproc perfd

    if [[ -e /sys/zte_power_debug/switch ]]; then
        echo 0 > /sys/zte_power_debug/switch
    fi
    if [[ -e /sys/zte_power_debug/debug_enabled ]]; then
        echo N > /sys/kernel/debug/debug_enabled
    fi
    stop cnss_diag 2> /dev/null
    killall -9 cnss_diag 2> /dev/null
    stop subsystem_ramdump 2> /dev/null
    #stop thermal-engine 2> /dev/null
    stop tcpdump 2> /dev/null
    # killproc logd
    # killproc adbd
    # killproc magiskd
    killproc magisklogd

    echo "Clean up background dormant whitelist"
    echo "Please wait..."
    for item in `dumpsys deviceidle whitelist`
    do
        app=`echo "$item" | cut -f2 -d ','`
        #echo "deviceidle whitelist -$app"
        dumpsys deviceidle whitelist -$app
        # r=`dumpsys deviceidle whitelist -$app | grep Removed`
        # if [[ -n "$r" ]]; then
            am set-inactive $app true > /dev/null 2>&1
            am set-idle $app true > /dev/null 2>&1
            # 9.0 让后台应用立即进入闲置状态
            am make-uid-idle --user current $app > /dev/null 2>&1
        # fi
    done
    for app in `pm list packages -3  | cut -f2 -d ':'`
    do
        am set-inactive $app true > /dev/null 2>&1
        am set-idle $app true > /dev/null 2>&1
        am make-uid-idle --user current $app > /dev/null 2>&1
    done
    dumpsys deviceidle step
    dumpsys deviceidle step
    dumpsys deviceidle step
    dumpsys deviceidle step

    echo 'Note: Scene may not be able to keep the background after power saving mode is turned on.'
    echo 'And, you may not receive the background message push!'
    echo ''
else
    echo "Turning off automatic app restrictions may require Android Pie"
    settings put global app_auto_restriction_enabled false

    echo "Close the application to force standby"
    settings put global forced_app_standby_enabled 0

    echo "Turn on the application standby"
    settings put global app_standby_enabled 1

    echo "Close the small capacity battery device application forced standby"
    settings put global forced_app_standby_for_small_battery_enabled 0

    echo "Turn off Android's native power saving mode"
    settings put global low_power 0
    settings put global low_power_sticky 0
fi

echo 'Status has been switched, some deeply customized systems this operation may not work!'
echo '-'


