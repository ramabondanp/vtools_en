# Follow magisk
flash_image() {
  case "$1" in
    *.gz) CMD1="gzip -d < '$1' 2>/dev/null";;
    *)    CMD1="cat '$1'";;
  esac
  # if $BOOTSIGNED; then
  #   CMD2="$BOOTSIGNER -sign"
  #   echo "- Sign image with verity keys"
  # else
  #   CMD2="cat -"
  # fi
  CMD2="cat -"
  if [ -b "$2" ]; then
    local img_sz=$(stat -c '%s' "$1")
    local blk_sz=$(blockdev --getsize64 "$2")
    [ "$img_sz" -gt "$blk_sz" ] && return 1
    blockdev --setrw "$2"
    local blk_ro=$(blockdev --getro "$2")
    [ "$blk_ro" -eq 1 ] && return 2
    eval "$CMD1" | eval "$CMD2" | cat - /dev/zero > "$2" 2>/dev/null
  elif [ -c "$2" ]; then
    flash_eraseall "$2" >&2
    eval "$CMD1" | eval "$CMD2" | nandwrite -p "$2" - >&2
  else
    echo "- Not block or char device, storing image"
    eval "$CMD1" | eval "$CMD2" > "$2" 2>/dev/null
  fi
  return 0
}

boot_repack(){
  echo "######### Target:$1 #########"
  magiskboot='/data/adb/magisk/magiskboot'

  if [[ -f $magiakboot ]]; then
    echo 'Please install Magisk first' 1>&2
    echo 'Please install magisk first.' 1>&2
    exit
  fi

  boot=$1
  blk=$root_dir/$boot
  twrp="$2"

  # mk worker directory
  wd=$TEMP_DIR/boot-patch
  if [[ -d $wd ]]; then
    rm -rf $wd 2>/dev/null
  fi
  mkdir -p $wd/$boot
  mkdir -p $wd/twrp

  echo "Copy $twrp > twrp.img"
  echo "Copy $twrp > twrp.img"
  cp "$twrp" $wd/twrp/twrp.img

  echo "Dump $boot > boot.img"
  echo "dump $boot > boot.img"
  cat $blk > $wd/$boot/$boot.img

  echo "Unpack twrp.img"
  echo 'unpack twrp.img'
  cd $wd/twrp
  $magiskboot unpack twrp.img
  if [[ "$?" != '0' ]]; then
    return
  fi

  echo "Unpack $boot.img"
  echo "unpack $boot.img"
  cd $wd/$boot
  $magiskboot unpack $boot.img
  if [[ "$?" != '0' ]]; then
    return
  fi

  # mv twrp_ramdisk  boot_a_ramdisk
  # $magiskboot repack twrp.img target_a.img

  cd $wd
  boot_ramdisk=$(ls $boot | grep ramdisk)
  twrp_ramdisk=$(ls twrp | grep ramdisk)
  echo 'Find ramdisk: ' twrp:$twrp_ramdisk boot:$boot_ramdisk
  if [[ -f "$boot/$boot_ramdisk" && -f "twrp/$twrp_ramdisk" ]]; then
    echo 'Copy ramdisk: ' $twrp_ramdisk > $boot_ramdisk
    cp twrp/ramdisk* $boot/
  else
    echo 'Error: ramdisk not found!' 1>&2
    echo 'Error: ramdisk Not Found!' 1>&2
    return
  fi

  cd $wd/$boot
  $magiskboot repack $boot.img ${boot}_twrp.img
  if [[ "$?" == 0 ]]; then
    flash_image $wd/$boot/${boot}_twrp.img $root_dir/$boot
    r="$?"
    if [[ "$r" == "0" ]]; then
      echo "flash "$boot" success."
    elif [[ "$r" == 1 ]]; then
      echo 'Image too large to write to partition' 1>&2
      echo 'A large .img cannot be written to a partition' 1>&2
      return
    elif [[ "$r" == 2 ]]; then
      echo 'Target partition is read-only' 1>&2
      echo 'block is readonly!' 1>&2
      return
    fi
  else
    return 2
  fi

  echo
  echo
  echo
}

boot_ab() {
  source $PAGE_WORK_DIR/bootdevice.sh
  boot_a=$root_dir/boot_a
  boot_b=$root_dir/boot_b
  # boot partition size
  p_size=$(blockdev --getsize64 $boot_a)
  # img size
  f_size=$(stat --format=%s "$file")
  if [[ "$f_size" -gt "$p_size" ]]; then
    echo 'Image too large to write to partition' 1>&2
    echo 'A large .img cannot be written to a partition' 1>&2
    exit
  fi

  boot_repack boot_a "$file"
  if [[ "$r" == '0' ]]; then
    boot_repack boot_b "$file"
    if [[ "$r" == '0' ]]; then
      echo 'Nice, looks pretty smooth ^_^' 1>&2
      echo "Nice. It looks like it's going well ^_^" 1>&2
    else
      echo 'Installation failed >_<' 1>&2
      echo 'Failed to install >_<' 1>&2
    fi
  else
    echo 'Installation failed' 1>&2
    echo 'Failed to install' 1>&2
  fi

  echo 'Clean cache files...'
  echo 'clear caches...'
  rm -rf $TEMP_DIR/boot-patch 2>/dev/null

  echo ''
}

recovery_ab() {
  source $PAGE_WORK_DIR/bootdevice.sh
  recovery_a=$root_dir/recovery_a
  recovery_b=$root_dir/recovery_b

  echo 'Install twrp to' $root_dir/recovery_a
  flash_image "$file" "$root_dir/recovery_a"
  r="$?"
  if [[ "$r" == '0' ]]; then
    echo 'flash recovery_a success.'
  elif [[ "$r" == 1 ]]; then
    echo 'Image too large to write to partition' 1>&2
    echo 'A large .img cannot be written to a partition' 1>&2
    exit
  elif [[ "$r" == 2 ]]; then
    echo 'Target partition is read-only' 1>&2
    echo 'block is readonly!' 1>&2
    exit
  fi

  echo 'Install twrp to' $root_dir/recovery_b
  if [[ "$r" == '0' ]]; then
    echo 'flash recovery_b success.'
  elif [[ "$r" == 1 ]]; then
    echo 'Image too large to write to partition' 1>&2
    echo 'A large .img cannot be written to a partition' 1>&2
    exit
  elif [[ "$r" == 2 ]]; then
    echo 'Target partition is read-only' 1>&2
    echo 'block is readonly!' 1>&2
    exit
  fi
}

if [[ ! -f "$file" ]]; then
  echo 'Selected file not found!' 1>&2
  echo "$file" 'Not Found!' 1>&2
  exit
fi

if [[ "$mode" == 'boot_ab' ]]; then
  boot_ab
elif [[ "$mode" == 'recovery_ab' ]]; then
  recovery_ab
else
  echo 'unsupported'
  exit
fi
