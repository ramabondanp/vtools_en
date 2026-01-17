#!/system/bin/sh

source ./kr-script/common/props.sh

ANDROID_SDK=`getprop ro.build.version.sdk`

prop="debug.hwui.renderer"
magisk_set_system_prop $prop $renderer
if [[ "$?" = "1" ]];
then
    echo "Changed $prop via Magisk. A reboot is required to take effect."
else
    set_system_prop $prop $renderer
fi

if [[ "$ANDROID_SDK" = 28 ]]
then
    if [[ "$renderer" = "opengl" ]]
    then
        echo 'On Android P, using OpenGL for HWUI may cause WebView crashes when opening pages.' 1>&2
    elif [[ "$renderer" = "skiavk" ]]
    then
        echo 'On Android P, using Skia Vulkan for HWUI may cause red WebView screens, blue video screens, and disable screenshots.' 1>&2
    fi
fi
