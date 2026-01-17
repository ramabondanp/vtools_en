#!/system/bin/sh

echo 'Disable network'
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
    echo 'Network validation parameters reset'
elif [[ "$state" == "disable" ]]; then
    settings put global captive_portal_mode 0
    echo 'Network status monitoring disabled'
    echo 'Note: This prevents captive portal login prompts on public Wi-Fi!' 1>&2
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
    echo "Network check server changed to https:$server_url"
fi

echo 'Restart network'
settings put global airplane_mode_on 0 > /dev/null 2>&1
am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false > /dev/null 2>&1
