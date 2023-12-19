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

echo "
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
"

[[ -z "$bDeviceLifeTimeEstA" ]] && { echo "This device has not used UFS nor provided health information." ; exit 0; }

case $bDeviceLifeTimeEstA in
"0x00"|"0x0")
  echo 'Used lifespan: Unknown'
  echo "Value: $bDeviceLifeTimeEstA"
  ;;
"0x01"|"0x1")
  echo 'Used lifespan: 0% ~ 10%'
  echo "Value: $bDeviceLifeTimeEstA"
  ;;
"0x02"|"0x2")
  echo 'Used lifespan: 10% ~ 20%'
  echo "Value: $bDeviceLifeTimeEstA"
  ;;
"0x03"|"0x3")
  echo 'Used lifespan: 20% ~ 30%'
  echo "Value: $bDeviceLifeTimeEstA"
  ;;
"0x04"|"0x4")
  echo 'Used lifespan: 30% ~ 40%'
  echo "Value: $bDeviceLifeTimeEstA"
  ;;
"0x05"|"0x5")
  echo 'Used lifespan: 40% ~ 50%'
  echo "Value: $bDeviceLifeTimeEstA"
  ;;
"0x06"|"0x6")
  echo 'Used lifespan: 50% ~ 60%'
  echo "Value: $bDeviceLifeTimeEstA"
  ;;
"0x07"|"0x7")
  echo 'Used lifespan: 60% ~ 70%'
  echo "Value: $bDeviceLifeTimeEstA"
  ;;
"0x08"|"0x8")
  echo 'Used lifespan: 70% ~ 80%'
  echo "Value: $bDeviceLifeTimeEstA"
  ;;
"0x09"|"0x9")
  echo 'Used lifespan: 80% ~ 90%'
  echo "Value: $bDeviceLifeTimeEstA"
  ;;
"0x0A"|"0xA")
  echo 'Used lifespan: 90% ~ 100%'
  echo "Value: $bDeviceLifeTimeEstA"
  ;;
"0x0B"|"0xB")
  echo 'Exceeded estimated lifespan'
  echo "Value: $bDeviceLifeTimeEstA"
  ;;
*)
  echo 'Used lifespan: Unknown'
  ;;
esac

if [[ -f /sys/devices/platform/soc/1d84000.ufshc/health_descriptor/eol_info ]]; then
  bPreEOLInfo=$(cat /sys/devices/platform/soc/1d84000.ufshc/health_descriptor/eol_info)
elif [[ -f /sys/devices/virtual/mi_memory/mi_memory_device/ufshcd0/dump_health_desc ]];then
  bPreEOLInfo=$(cat /sys/devices/virtual/mi_memory/mi_memory_device/ufshcd0/dump_health_desc | grep bPreEOLInfo | cut -f2 -d '=' | cut -f2 -d ' ')
else
  bPreEOLInfo=$(cat /sys/kernel/debug/*.ufshc/dump_health_desc 2>/dev/null | grep bPreEOLInfo | cut -f2 -d '=' | cut -f2 -d ' ')
fi

if [[ "$bPreEOLInfo" == "" ]];then
  for line in $dump_files
  do
    str=$(grep 'bPreEOLInfo' $line | cut -f2 -d '=' | cut -f2 -d ' ')
    if [[ "$str" != "" ]]; then
      bPreEOLInfo="$str"
    fi
  done
fi

if [[ "$bPreEOLInfo" == "" ]];then
  files=$(find /sys -name "eol_info" | grep ufshc)
  for line in $files
  do
    str=$(cat $line)
    if [[ "$str" != "" ]]; then
      bPreEOLInfo="$str"
    fi
  done
fi

echo "
# 0x00 Undefined member.
# 0x01 Normal. Consumes less than 80% of reserved blocks.
# 0x02 Consumes 80% of reserved blocks.
# 0x03 Critical. Consumes 90% of reserved blocks.
# All other values Reserved for future use.
"

case $bPreEOLInfo in
"0x00"|"0x0")
  echo 'Reserved block wear: Unknown'
  echo "Value: $bPreEOLInfo"
  ;;
"0x01"|"0x1")
  echo 'Reserved block wear: < 80%'
  echo "Value: $bPreEOLInfo"
  ;;
"0x02"|"0x2")
  echo 'Reserved block wear: ≈ 80%'
  echo "Value: $bPreEOLInfo"
  ;;
"0x03"|"0x3")
  echo 'Reserved block wear: > 90%'
  echo "Value: $bPreEOLInfo"
  ;;
*)
  echo 'Reserved block wear: Unknown'
  echo "Value: $bPreEOLInfo"
  ;;
esac