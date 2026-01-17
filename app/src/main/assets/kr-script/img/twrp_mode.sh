source $PAGE_WORK_DIR/bootdevice.sh

mode="unsupported"
if [[ -e $root_dir/recovery_a ]]; then
  mode="recovery_ab"
elif [[ -e $root_dir/vendor_boot ]]; then
  mode="unsupported"
elif [[ -e $root_dir/boot_a && -e $root_dir/boot_b ]]; then
  # source $PAGE_WORK_DIR/vendor_boot_rec.sh
  # if [[ "$vendor_boot_rec" == 'false' ]]; then
    mode="boot_ab"
  # fi
fi

if [[ "$1" == 'mode' ]]; then
  echo $mode
elif [[ "$1" == 'verify' ]]; then
  if [[ "$mode" == 'unsupported' ]]; then
    echo 0
  else
    echo 1
  fi
fi
