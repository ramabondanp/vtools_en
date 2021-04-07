#!/system/bin/sh

am broadcast --user 0 -a update_profile com.miui.powerkeeper/com.miui.powerkeeper.cloudcontrol.CloudUpdateReceiver

services=`settings get secure enabled_accessibility_services`
service='com.qualcomm.qti.perfdump/com.qualcomm.qti.perfdump.AutoDetectService'
include=$(echo "$services" | grep "$service")

if [ ! -n "$services" ]
then
    settings put secure enabled_accessibility_services "$service";
elif [ ! -n "$include" ]
then
    settings put secure enabled_accessibility_services "$services:$service"
else
    settings put secure enabled_accessibility_services "$services"
fi
settings put secure accessibility_enabled 1;

echo 'If no error is reported (red font), then now go to "Settings - Battery and Performance" to see if there is already a temperature control mode option!'

sleep 1
