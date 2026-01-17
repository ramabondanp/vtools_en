if [[ -f /sys/block/mmcblk0/device/life_time ]]; then
  bDeviceLifeTimeEstA=$(cat /sys/block/mmcblk0/device/life_time | cut -f1 -d ' ')
fi

# 0x00	No information about device life.
# 0x01	Estimated device life: 0% to 10%.
# 0x02	Estimated device life: 10% to 20%.
# 0x03	Estimated device life: 20% to 30%.
# 0x04	Estimated device life: 30% to 40%.
# 0x05	Estimated device life: 40% to 50%.
# 0x06	Estimated device life: 50% to 60%.
# 0x07	Estimated device life: 60% to 70%.
# 0x08	Estimated device life: 70% to 80%.
# 0x09	Estimated device life: 80% to 90%.
# 0x0A	Estimated device life: 90% to 100%.
# 0x0B	Device has exceeded its estimated lifetime.

case $bDeviceLifeTimeEstA in
"0x00"|"0x00")
  echo 'Used lifetime: Unknown'
;;
"0x01"|"0x1")
  echo 'Used lifetime: 0% ~ 10%'
;;
"0x02"|"0x2")
  echo 'Used lifetime: 10% ~ 20%'
;;
"0x03"|"0x3")
  echo 'Used lifetime: 20% ~ 30%'
;;
"0x04"|"0x4")
  echo 'Used lifetime: 30% ~ 40%'
;;
"0x05"|"0x5")
  echo 'Used lifetime: 40% ~ 50%'
;;
"0x06"|"0x6")
  echo 'Used lifetime: 50% ~ 60%'
;;
"0x07"|"0x7")
  echo 'Used lifetime: 60% ~ 70%'
;;
"0x08"|"0x8")
  echo 'Used lifetime: 70% ~ 80%'
;;
"0x09"|"0x9")
  echo 'Used lifetime: 80% ~ 90%'
;;
"0x0A"|"0xA")
  echo 'Used lifetime: 90% ~ 100%'
;;
"0x0B"|"0xB")
  echo 'Exceeded estimated lifetime'
;;
*)
  echo 'Used lifetime: Unknown'
;;
esac
