platform=`getprop ro.board.platform | tr 'A-Z' 'a-z'`
mode="$state"

if [[ "$MAGISK_PATH" == "" ]]; then
  MAGISK_PATH="/data/adb/modules/scene_systemless"
fi

# Plan 2 - replace to /data
thermal_dir="/data/vendor/thermal"
install_dir="$thermal_dir/config"
mode_state_save="$install_dir/thermal.current.ini"
source="$1"

thermal_files=(
)
if [[ "$mode" != "default" ]] && [[ "$mode" != "" ]]; then
  if [[ "$source" == "local" ]];then
    echo 'Generate target config based on this device...'
    mode_code=$(echo $mode | cut -f2 -d '_')
    resource_dir="$START_DIR/miui-thermal/$mode_code"
    if [[ ! -f $resource_dir/files.ini ]]; then
      echo 'No usable thermal files found; this device may be unsupported' 1>&2
      return
    fi
    thermal_files=$(cat $resource_dir/files.ini)
    all_file_names=$(cat $resource_dir/files.ini)
  else
    resource_dir="./kr-script/miui/thermal_conf3/$platform/$mode"
    # Override thermal_files
    # source ./kr-script/miui/thermal_conf3/$platform/thermal_files.sh
    source ./kr-script/miui/thermal_conf3/download.sh
  fi
fi

clear_old() {
  old_dir="${MAGISK_PATH}/system/vendor/etc"
  old_state_save="$old_dir/thermal.current.ini"
  if [[ -f $old_state_save ]]; then
    echo 'Clean old files'
    for thermal in ${thermal_files[@]}; do
      if [[ -f $old_dir/$thermal ]]; then
        rm -f $old_dir/$thermal
      fi
    done
    rm -f "$old_state_save" 2> /dev/null

    echo 'A reboot is recommended later' 1>&2
    echo '#################################'
  fi
}

reset_permissions(){
  chmod -R 0771 $thermal_dir
  chown -R root:system $thermal_dir/config 2>/dev/null
  chown root:system $thermal_dir/decrypt.txt 2>/dev/null
  chown system:system $thermal_dir/report.dump 2>/dev/null
  chown system:system $thermal_dir/thermal-global-mode 2>/dev/null
  chown system:system $thermal_dir/thermal.dump 2>/dev/null
  restorecon -DFR $thermal_dir 2> /dev/null
}

# Rebuild directories based on the method from user @code10007
clear_thermal_dir() {
  r=0
  for dir in $thermal_dir $install_dir
  do
    if [[ -f $dir ]]; then
      chattr -R -i $dir
      rm -f $dir
      r=1
    fi

    if [[ -e $dir ]]; then
      chattr -R -i $dir
    else
      mkdir -p $dir
    fi
  done

  rm $install_dir/* 2>/dev/null
  rm -f "$mode_state_save" 2> /dev/null

  return $r
}

uninstall_thermal() {
  clear_old

  echo "From $install_dir directory"
  echo 'Uninstall installed custom configuration...'
  echo ''

  clear_thermal_dir
  if [[ "$?" != '0' ]]; then
     echo "Detected $thermal_dir directory corruption" 1>&2
     echo 'Scene attempted to restore it by rebuilding' 1>&2
     echo 'Please check and remove modules that may override/modify thermal configs' 1>&2
     echo "To avoid $thermal_dir being damaged again"
  fi

  echo ''
}

install_thermal() {
  uninstall_thermal

  echo 'Checking for conflicts between modules...'
  echo ''

  # Check whether other modules modify thermal configs
  magisk_dir=`echo $MAGISK_PATH | awk -F '/[^/]*$' '{print $1}'`
  modules=`ls $magisk_dir`
  for module in ${modules[@]}; do
    if [[ "$magisk_dir/$module" != "$MAGISK_PATH" ]] && [[ -d "$magisk_dir/$module" ]] && [[ ! -f "$magisk_dir/$module/disable" ]]; then
      if [[ "$module" != "uperf" ]] && [[ "$module" != "extreme_gt" ]] && [[ -d "$magisk_dir/$module/system" ]]; then
        find_result=`find "$magisk_dir/$module/system" -name "*thermal*" -type f`
        if [[ -n "$find_result" ]]; then
          echo 'Found other modules modifying thermal configs:' $module 1>&2
          echo "$find_result" 1>&2
          echo 'Delete the files above or disable the related modules!' 1>&2
          echo 'Otherwise, Scene cannot replace system thermal configs properly!' 1>&2
          exit 5
        fi
      fi
    fi
  done
  # c_dir=$(getprop vendor.sys.thermal.data.path)
  # if [[ "$c_dir" != "$thermal_dir" && "$c_dir" != "$thermal_dir/" ]];then
  #   echo 'vendor.sys.thermal.data.path does not match expected value' 1>&2
  #   echo 'Currently set to:' $(getprop vendor.sys.thermal.data.path) 1>&2
  #   echo 'This may cause thermal configs to not take effect!' 1>&2
  #   # exit 5
  # fi

  if [[ "$source" != "local" ]];then
    download_files
  fi

  if [[ -f $resource_dir/info.txt ]]; then
    echo ''
    echo '#################################'
    cat $resource_dir/info.txt
    echo ''
    echo '#################################'
    echo ''
    echo ''
  fi

  if [[ ! -d "$install_dir" ]]; then
    mkdir -p "$install_dir"
  fi

  # for thermal in ${thermal_files[@]}; do
  #   if [[ -f "$resource_dir/$thermal" ]]; then
  #     echo 'Copy' $thermal
  #     cp "$resource_dir/$thermal" "$install_dir/$thermal"
  #     chmod 644 "$install_dir/$thermal"
  #   elif [[ -f "$resource_dir/general.conf" ]]; then
  #     echo 'Copy' $thermal
  #     cp "$resource_dir/general.conf" "$install_dir/$thermal"
  #     chmod 644 "$install_dir/$thermal"
  #   fi
  #   dos2unix "$install_dir/$thermal" 2> /dev/null
  # done

  # ls $resource_dir | while read thermal; do
  echo "$all_file_names" | dos2unix | while read thermal; do
    if [[ -f "$resource_dir/$thermal" ]]; then
      echo 'Copy' $thermal
      cp "$resource_dir/$thermal" "$install_dir/$thermal"
      chmod 444 "$install_dir/$thermal"
    elif [[ -f "$resource_dir/general.conf" ]]; then
      echo 'Copy' $thermal
      cp "$resource_dir/general.conf" "$install_dir/$thermal"
      chmod 444 "$install_dir/$thermal"
    else
      echo 'Skip' $thermal
    fi
  done

  echo "$mode" > "$mode_state_save"

  echo 'OK~'
  echo ''
  echo 'Note: if you are not using the official stock system, or have modified thermal via other tools/modules, this may not take effect'
  echo 'If switching thermal configs does not take effect, try rebooting; if it still fails after reboot, then...' 1>&2
}

if [[ "$mode" == "default" || "$mode" == "" ]]; then
  uninstall_thermal
else
  install_thermal
fi

# Restart thermal-related processes
for p in 'mi_thermald' 'thermal-engine'; do
if [[ $(which -a $p) != "" ]]; then
  stop $p 2>/dev/null
  start $p 2>/dev/null
fi
done

reset_permissions
