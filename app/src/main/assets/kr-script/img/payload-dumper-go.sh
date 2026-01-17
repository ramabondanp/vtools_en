if [[ "$1" == 'verify' ]]; then
  if [[ -f /data/adb/modules/payload-dumper-go/system/bin/install-ota ]]; then
    echo 1
  else
    echo 0
  fi
fi