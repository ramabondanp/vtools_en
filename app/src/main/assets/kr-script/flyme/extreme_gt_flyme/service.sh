set_value() {
  if [[ -f $2 ]]; then
    echo $1 > $2
  fi
}
lock_value() {
  if [[ -f $2 ]]; then
    echo $1 > $2
    chmod 444 $2
  fi
}

# old
lock_value 10 /sys/class/meizu/charger/wired_level
lock_value 10 /sys/class/meizu/wireless/wls_level

# new
lock_value 10 /sys/class/meizu/charger/wired/wired_level
lock_value 10 /sys/class/meizu/charger/wireless/wls_level

stop thermal-engine
# killall vendor.meizu.hardware.meizu_charging@1.0-service
