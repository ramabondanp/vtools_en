slot=$(getprop ro.boot.slot_suffix)

if [[ "$1" == 'slot' ]]; then
  echo $slot
elif [[ "$1" == 'verify' ]]; then
  if [[ "$slot" == '_a' || "$slot" == '_b' ]]; then
    echo '1'
  else
    echo '0'
  fi
fi
