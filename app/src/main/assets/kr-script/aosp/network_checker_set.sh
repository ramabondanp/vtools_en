#!/system/bin/sh

echo 'Turn off the network'
settings put global airplane_mode_on 1 > /dev/null 2>&1
am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true > /dev/null 2>&1

if [[ "$state" == "" ]] || [[ "$state" == "default" ]]; then
    settings delete global captive_portal_server
    settings reset global captive_portal_server
    settings delete global captive_portal_http_url
    settings reset global captive_portal_http_url
    settings delete global captive_portal_https_url
    settings reset global captive_portal_https_url
    settings delete global captive_portal_use_https
    settings reset global captive_portal_use_https
    settings delete global captive_portal_mode
    settings reset global captive_portal_mode
    settings delete global captive_portal_detection_enabled
    settings reset global captive_portal_detection_enabled
    echo 'Network auth parameters have been reset'
elif [[ "$state" == "disable" ]]; then
    settings put global captive_portal_mode 0
    echo 'Network status monitoring is disabled'
    echo 'Note: This will cause you to not automatically pop up the login verification when you connect to the public WIFI!' 1>&2
else
    server_url=""
    if [[ "$state" == "miui" ]]; then
      server_url="//connect.rom.miui.com/generate_204"
    elif [[ "$state" == "google" ]]; then
      server_url="//www.google.cn/generate_204"
    elif [[ "$state" == "v2ex" ]]; then
      server_url="//captive.v2ex.co/generate_204"
    fi
    settings put global captive_portal_server https:$server_url
    settings put global captive_portal_http_url http:$server_url
    settings put global captive_portal_https_url https:$server_url
    settings put global captive_portal_use_https 1
    settings put global captive_portal_mode 1
    settings put global captive_portal_detection_enabled 1
    echo "Changed the network detection server to https:$server_url"
fi

echo 'Restart network'
settings put global airplane_mode_on 0 > /dev/null 2>&1
am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false > /dev/null 2>&1
