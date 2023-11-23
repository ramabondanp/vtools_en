enablesc=/sys/devices/platform/charger/enable_sc
tuisoc=/sys/devices/platform/charger/sc_tuisoc
usbotg=/sys/devices/platform/odm/odm:tran_battery/OTG_CTL
transchg=/sys/devices/platform/charger/tran_aichg_disable_charger

lock_value () {
  chmod 644 "$2"
  echo "$1" > "$2"
  chmod 444 "$2"
}

set_bypasschg(){
  lock_value "$state" $transchg
}

set_limitchg(){
  lock_value "$state" $enablesc
}

set_maxchg(){
  lock_value "$state" $tuisoc
}

set_usbotg(){
  lock_value "$state" $usbotg
}

get_maxchg(){
  value=$(cat $tuisoc)
  value=$((value + 1))
  echo $value
}