transchg=/sys/devices/platform/charger/tran_aichg_disable_charger
usbotg=/sys/devices/platform/odm/odm:tran_battery/OTG_CTL

lock_value () {
  chmod 644 "$2"
  echo "$1" > "$2"
  chmod 444 "$2"
}

set_transchg(){
  lock_value "$state" $transchg
}

set_usbotg(){
  lock_value "$state" $usbotg
}