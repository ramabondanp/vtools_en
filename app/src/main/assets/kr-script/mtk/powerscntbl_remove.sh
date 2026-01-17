if [[ -d /data/adb/modules/extreme_gt ]]; then
  echo 'The [Realme Extreme GT] module is installed; no need to use this feature.'
  exit 0
fi

mkdir -p $MAGISK_PATH/system/vendor/etc
echo '<?xml version="1.0" encoding="UTF-8"?>
<SCNTABLE>
</SCNTABLE>' > $MAGISK_PATH/system/vendor/etc/powerscntbl.xml

echo 'You need to reboot the phone for changes to take effect'
