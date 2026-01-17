if [[ "$MAGISK_PATH" == "" ]]; then
  echo 'This feature requires Magisk and the SCENE add-on module!' 1>&2
  return
fi

target_dir="${MAGISK_PATH}/system/product/overlay"
os=$(getprop ro.build.version.sdk)
sdk=sdk$os
dir=$PAGE_WORK_DIR/notch

echo 'Searching for resource folder...' # $dir/$sdk
if [[ -d $dir/$sdk ]]; then
  echo 'Creating directory...'
  mkdir -p $target_dir
  echo 'Copying overlay files...'
  for item in $dir/$sdk/*
  do
    echo '  ' $item
    cp -rf $item $target_dir/
  done
  if [[ "$type" == "hole" ]]; then
    echo 'Now, please reboot the phone first.'
    echo 'Then go to Settings > Developer options > Display cutout and choose "Hole-punch".'
  fi
else
  echo 'No overlay files found for your current device' 1>&2
fi
