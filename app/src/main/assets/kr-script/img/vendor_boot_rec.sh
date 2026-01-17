magiskboot='/data/adb/magisk/magiskboot'

prop=persist.vendor_boot.rec
p_value=$(getprop $prop)
if [[ "$p_value" != '' ]]; then
  vendor_boot_rec="$p_value"
else
  wd=$TEMP_DIR/rec-verify
  if [[ -e "$wd" ]]; then
    rm -rf "$wd"
  fi
  mkdir -p "$wd"

  blk_a=$root_dir/vendor_boot_a
  blk_b=$root_dir/vendor_boot_b
  if [[ -e "$blk_a" && -e "$blk_b" ]]; then
    if [[ -f "$magiskboot" ]]; then
      cat $blk_a > $wd/vendor_boot_a.img
      cat $blk_b > $wd/vendor_boot_b.img

      cd $wd
      $magiskboot unpack vendor_boot_a.img
      $magiskboot unpack vendor_boot_b.img
      found_ramdisk=$(ls ./ | grep ramdisk)
      if [[ "$wd" == '' ]]; then
        vendor_boot_rec='false'
      else
        vendor_boot_rec='true'
      fi
      # rm -rf "$wd"
    fi
  else
    vendor_boot_rec='false'
  fi

  setprop $prop "$p_value"
fi
