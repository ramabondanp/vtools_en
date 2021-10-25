bDeviceLifeTimeEstA=$(cat /sys/kernel/debug/*.ufshc/dump_health_desc | grep bDeviceLifeTimeEstA | cut -f2 -d '=' | cut -f2 -d ' ')
# 0x00 No information about the service life of the device was found.
# 0x01 The estimated life of the device is 0% to 10%.
# 0x02 The estimated life of the device is 10% to 20%.
# 0x03 The estimated life of the device is 20% to 30%.
# 0x04 The estimated life of the device is 30% to 40%.
# 0x05 The estimated life of the device is 40% to 50%.
# 0x06 The estimated life of the device is 50% to 60%.
# 0x07 The estimated life of the device is 60% to 70%.
# 0x08 The estimated life of the device is 70% to 80%.
# 0x09 The estimated life of the device is 80% to 90%.
# 0x0A The estimated life of the device is 90% to 100%.
# 0x0B The device has exceeded its estimated useful life.

case $bDeviceLifeTimeEstA in
"0x00"|"0x00")
  echo 'Life span unknown'
;;
"0x01"|"0x1")
  echo 'Life span 0% ~ 10%'
;;
"0x02"|"0x2")
  echo 'Life span 10% ~ 20%'
;;
"0x03"|"0x3")
  echo 'Life span 20% ~ 30%'
;;
"0x04"|"0x4")
  echo 'Life span 30% ~ 40%'
;;
"0x05"|"0x5")
  echo 'Life span 40% ~ 50%'
;;
"0x06"|"0x6")
  echo 'Life span 50% ~ 60%'
;;
"0x07"|"0x7")
  echo 'Life span 60% ~ 70%'
;;
"0x08"|"0x8")
  echo 'Life span 70% ~ 80%'
;;
"0x09"|"0x9")
  echo 'Life span 80% ~ 90%'
;;
"0x0A"|"0xA")
  echo 'Life span 90% ~ 100%'
;;
"0x0B"|"0xB")
  echo 'Estimated life span has been exceeded'
;;
*)
  echo 'Life span unknown'
;;
esac

bPreEOLInfo=$(cat /sys/kernel/debug/*.ufshc/dump_health_desc | grep bPreEOLInfo | cut -f2 -d '=' | cut -f2 -d ' ')
# 0x00 No members are defined.
# 0x01 is normal. Less than 80% of reserved blocks are consumed.
# 0x02 80% of the reserved blocks are consumed.
# 0x03 Critical. 90% of reserved blocks are consumed.
# All other values are reserved for future use.

case $bPreEOLInfo in
"0x00"|"0x00")
  echo 'Reserved block wear unknown'
;;
"0x01"|"0x1")
  echo 'Reserved block wear < 80%'
;;
"0x02"|"0x2")
  echo 'Reserved block wear ≈ 80%'
;;
"0x03"|"0x3")
  echo 'Reserved block wear > 90%'
;;
*)
  echo 'Reserved block wear unknown'
;;
esac