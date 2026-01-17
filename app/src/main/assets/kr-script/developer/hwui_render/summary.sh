#!/system/bin/sh

render=`getprop debug.hwui.renderer`

if [[ "$render" = "opengl" ]]
then
    mode="OpenGL"
elif [[ "$render" = "skiagl" ]]
then
    mode="Skia (OpenGL)"
elif [[ "$render" = "skiavk" ]]
then
    mode="Skia (Vulkan)"
elif [[ "$render" = "" ]]
then
    mode=`dumpsys gfxinfo $PACKAGE_NAME | grep Pipeline | cut -f2 -d '='`
else
    mode="Unknown"
fi

echo "Current: $mode"
