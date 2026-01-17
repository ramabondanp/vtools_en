if [[ -f $MAGISK_PATH/system/vendor/etc/powerscntbl.xml ]]
then
  rm -f $MAGISK_PATH/system/vendor/etc/powerscntbl.xml
  echo 'You need to reboot the phone for changes to take effect'
else
  if [[ -d /data/adb/modules/extreme_gt ]]; then
    echo 'The [Realme Extreme GT] module is installed; no need to use this feature.'
    exit 0
  else
    echo 'No replacement file found. If you just restored it, reboot for changes to take effect.'
    echo 'If [Scenario Boost] was removed by other tools, Scene cannot restore it.'
  fi
fi
