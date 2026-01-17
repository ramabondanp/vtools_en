#!/system/bin/sh

# pm query-activities -a android.intent.action.MAIN -c android.intent.category.HOME | grep name=
# pm query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME
# pm set-home-activity com.google.android.apps.nexuslauncher/.NexusLauncherActivity  --user 0

# Stop all running launcher apps
launchers=$(pm query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME | grep '/')
for launcher in $launchers ; do
    packageName=`echo $launcher | cut -f1 -d '/'`
    am force-stop $packageName 2>/dev/null
    killall -9 $packageName 2>/dev/null
done

# Security center and similar apps
security_apps="
com.miui.securitycenter
com.miui.guardprovider
com.lbe.security.miui
"
for app in $security_apps
do
  if [[ "$app" != "" ]]
  then
    am force-stop "$app" 2>/dev/null
    killall -9 "$app" 2>/dev/null
  fi
done


# Switch launcher
activity="$state"
if [[ "$activity" != "" ]]; then
    echo "Switch launcher to [$activity]"
    pm set-home-activity $activity --user ${ANDROID_UID}
fi

# Simulate Home key to return to launcher
input keyevent 3
