prop="persist.vtools.suspend"
status=`getprop $prop`

function on() {
apps=`pm list package -3 | grep -v com.omarea | grep -v launcher | grep -v xposed | grep -v magisk | cut -f2 -d ':'`
system_apps="
com.xiaomi.market
com.miui.player
com.miui.video
com.xiaomi.ab
com.miui.gallery
com.android.fileexplorer
com.android.browser
com.google.android.gsf
com.google.android.gsf.login
com.google.android.gms
com.android.vending
com.google.android.play.games
com.google.android.syncadapters.contacts
"

    echo 'Enter standby mode'
    echo ''
    echo 'This process may require 10~60 seconds'
    echo ''
    echo 'Freeze all third-party applications'
    echo ''

    for app in $apps; do
      am force-stop $app 1 > /dev/null
      pm suspend $app 1 > /dev/null
    done
    for app in $system_apps; do
      am force-stop $app 1 > /dev/null
      pm suspend $app 1 > /dev/null
    done

    setprop $prop 1

    svc wifi disable
    svc data disable

    settings put global low_power 1;

    echo "Enabling automatic application restrictions may require Android Pie"
    settings put global app_auto_restriction_enabled true

    echo "Turn on the application to force standby"
    settings put global forced_app_standby_enabled 1

    echo "Turn on the application standby"
    settings put global app_standby_enabled 1

    echo "Turn on Android's native power saving mode"
    settings put global low_power 1

    sync

    echo 3 > /proc/sys/vm/drop_caches

    # 电源键 息屏
    input keyevent 26
    sleep 5

    echo "Enter idle status"
    dumpsys deviceidle step
    dumpsys deviceidle step
    dumpsys deviceidle step
    dumpsys deviceidle step
}

function off() {
    echo 'Exit standby mode'
    echo 'This process may require 10~60 seconds'
    echo ''

    for app in `pm list package | cut -f2 -d ':'`; do
      pm unsuspend $app 1 > /dev/null
    done

    # svc wifi enable
    # svc data enable

    settings put global low_power 0;

    echo "Turning off automatic app restrictions may require Android Pie"
    settings put global app_auto_restriction_enabled false

    echo "Close the application to force standby"
    settings put global forced_app_standby_enabled 0

    echo "Turn on the application standby"
    settings put global app_standby_enabled 1

    echo "Turn off Android's native power saving mode"
    settings put global low_power 0

    setprop $prop 0
}

if [[ "$status" = "1" ]]; then
    off
else
    on
fi
