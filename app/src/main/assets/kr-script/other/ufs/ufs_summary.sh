if [[ -f /sys/devices/platform/soc/1d84000.ufshc/health_descriptor/life_time_estimation_a ]]; then
  bDeviceLifeTimeEstA=$(cat /sys/devices/platform/soc/1d84000.ufshc/health_descriptor/life_time_estimation_a)
elif [[ -f /sys/devices/virtual/mi_memory/mi_memory_device/ufshcd0/dump_health_desc ]];then
  bDeviceLifeTimeEstA=$(cat /sys/devices/virtual/mi_memory/mi_memory_device/ufshcd0/dump_health_desc | grep bDeviceLifeTimeEstA | cut -f2 -d '=' | cut -f2 -d ' ')
else
  bDeviceLifeTimeEstA=$(cat /sys/kernel/debug/*.ufshc/dump_health_desc 2>/dev/null | grep bDeviceLifeTimeEstA | cut -f2 -d '=' | cut -f2 -d ' ')
fi

dump_files=$(find /sys -name "dump_*_desc" | grep ufshc)
if [[ "$bDeviceLifeTimeEstA" == "" ]];then
  for line in $dump_files
  do
    str=$(grep 'bDeviceLifeTimeEstA' $line | cut -f2 -d '=' | cut -f2 -d ' ')
    if [[ "$str" != "" ]]; then
      bDeviceLifeTimeEstA="$str"
    fi
  done
fi

if [[ "$bDeviceLifeTimeEstA" == "" ]];then
  files=$(find /sys -name "life_time_estimation_a" | grep ufshc)
  for line in $files
  do
    str=$(cat $line)
    if [[ "$str" != "" ]]; then
      bDeviceLifeTimeEstA="$str"
    fi
  done
fi

# 0x00 No information found about the device's usage lifespan.
# 0x01 Device estimated lifespan: 0% to 10%.
# 0x02 Device estimated lifespan: 10% to 20%.
# 0x03 Device estimated lifespan: 20% to 30%.
# 0x04 Device estimated lifespan: 30% to 40%.
# 0x05 Device estimated lifespan: 40% to 50%.
# 0x06 Device estimated lifespan: 50% to 60%.
# 0x07 Device estimated lifespan: 60% to 70%.
# 0x08 Device estimated lifespan: 70% to 80%.
# 0x09 Device estimated lifespan: 80% to 90%.
# 0x0A Device estimated lifespan: 90% to 100%.
# 0x0B Device has exceeded its estimated lifespan.

[[ -z "$bDeviceLifeTimeEstA" ]] && { echo "This device has not used UFS nor provided health information." ; exit 0; }

case $bDeviceLifeTimeEstA in
"0x00"|"0x0")
  echo 'Used lifespan: Unknown'
  ;;
"0x01"|"0x1")
  echo 'Used lifespan: 0% ~ 10%'
  ;;
"0x02"|"0x2")
  echo 'Used lifespan: 10% ~ 20%'
  ;;
"0x03"|"0x3")
  echo 'Used lifespan: 20% ~ 30%'
  ;;
"0x04"|"0x4")
  echo 'Used lifespan: 30% ~ 40%'
  ;;
"0x05"|"0x5")
  echo 'Used lifespan: 40% ~ 50%'
  ;;
"0x06"|"0x6")
  echo 'Used lifespan: 50% ~ 60%'
  ;;
"0x07"|"0x7")
  echo 'Used lifespan: 60% ~ 70%'
  ;;
"0x08"|"0x8")
  echo 'Used lifespan: 70% ~ 80%'
  ;;
"0x09"|"0x9")
  echo 'Used lifespan: 80% ~ 90%'
  ;;
"0x0A"|"0xA")
  echo 'Used lifespan: 90% ~ 100%'
  ;;
"0x0B"|"0xB")
  echo 'Exceeded estimated lifespan'
  ;;
*)
  echo 'Used lifespan: Unknown'
  ;;
esac