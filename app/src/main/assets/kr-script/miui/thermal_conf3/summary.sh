install_dir="${MAGISK_PATH}/system/vendor/etc"
# Plan 2 - replace to /data
install_dir="/data/vendor/thermal/config"
mode_state_save="$install_dir/thermal.current.ini"

if [[ -f "$mode_state_save" ]]; then
  if [[ $(cat $mode_state_save | grep "local_") == "" ]]; then
    mode=`cat $mode_state_save | cut -f1 -d '_'`
  else
    mode=`cat $mode_state_save | cut -f2 -d '_'`
  fi
else
    mode=''
fi

modename=""
case "$mode" in
  "default")
    modename="@string:kr_system_default"
   ;;
  "original")
    modename="Factory config (original)"
   ;;
  "cool")
    modename="Cool and fresh (cool)"
   ;;
  "powerfrugal")
    modename="Power saving & cooling (powerfrugal)"
   ;;
  "performance")
    modename="Higher thresholds (performance)"
  ;;
  "slight")
    modename="Slight tweaks (slight)"
  ;;
  "pro")
    modename="Deep customization (pro)"
  ;;
  "author")
    modename="Dudu's daily gaming (author)"
  ;;
  *"extreme")
    modename="Extreme performance (extreme)"
  ;;
  *"danger")
    modename="Overkill (danger)"
  ;;
  "game")
    modename="Game mode (game)"
  ;;
  "")
    modename="Not replaced"
  ;;
  *)
    # modename="Not replaced"
  ;;
esac

echo "Current: $modename"
