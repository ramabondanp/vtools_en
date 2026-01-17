#!/system/bin/sh

pm_cmd=""
if [[ "$state" = "1" ]]; then
    pm_cmd="install-existing"
    echo '√√  Enabled  App security scan'
else
    pm_cmd="uninstall"
    echo '××  Disabled  App security scan'
fi

echo ''
echo ''

pm $pm_cmd --user 0 com.oplus.appdetail 2> /dev/null

