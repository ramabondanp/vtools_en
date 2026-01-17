#!/system/bin/sh

pm_cmd=""
if [[ "$state" = "1" ]]; then
    pm_cmd="enable"
    echo '√√  Enabled  Google Play services suite'
else
    pm_cmd="disable"
    echo '××  Disabled  Google Play services suite'
fi

echo ''
echo ''

pm $pm_cmd com.google.android.gsf 2> /dev/null
pm $pm_cmd com.google.android.gsf.login 2> /dev/null
pm $pm_cmd com.google.android.gms 2> /dev/null
pm $pm_cmd com.android.vending 2> /dev/null
pm $pm_cmd com.google.android.play.games 2> /dev/null
pm $pm_cmd com.google.android.syncadapters.contacts 2> /dev/null
