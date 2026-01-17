if [[ -f /sys/devices/platform/soc/1d84000.ufshc/health_descriptor/life_time_estimation_a ]]; then
  bDeviceLifeTimeEstA=$(cat /sys/devices/platform/soc/1d84000.ufshc/health_descriptor/life_time_estimation_a)
elif [[ -f /sys/devices/virtual/mi_memory/mi_memory_device/ufshcd0/dump_health_desc ]];then
  bDeviceLifeTimeEstA=$(cat /sys/devices/virtual/mi_memory/mi_memory_device/ufshcd0/dump_health_desc | grep bDeviceLifeTimeEstA | cut -f2 -d '=' | cut -f2 -d ' ')
else
  bDeviceLifeTimeEstA=$(cat /sys/kernel/debug/*.ufshc/dump_health_desc 2>/dev/null | grep bDeviceLifeTimeEstA | cut -f2 -d '=' | cut -f2 -d ' ')
fi

dump_files=$(find /sys -name "dump_*_desc" | grep ufshc)
if [[ "$bDeviceLifeTimeEstA" == "" ]];then
  # dump_files=$(find /sys -name "dump_*_desc" | grep ufshc)
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

# Used lifetime
case $bDeviceLifeTimeEstA in
"0x00"|"0x0")
echo '@string:kr_others_ufs_health_used @string:kr_others_ufs_health_unknown'
;;
"0x01"|"0x1")
echo '@string:kr_others_ufs_health_used 0% ~ 10%'
;;
"0x02"|"0x2")
echo '@string:kr_others_ufs_health_used 10% ~ 20%'
;;
"0x03"|"0x3")
echo '@string:kr_others_ufs_health_used 20% ~ 30%'
;;
"0x04"|"0x4")
echo '@string:kr_others_ufs_health_used 30% ~ 40%'
;;
"0x05"|"0x5")
echo '@string:kr_others_ufs_health_used 40% ~ 50%'
;;
"0x06"|"0x6")
echo '@string:kr_others_ufs_health_used 50% ~ 60%'
;;
"0x07"|"0x7")
echo '@string:kr_others_ufs_health_used 60% ~ 70%'
;;
"0x08"|"0x8")
echo '@string:kr_others_ufs_health_used 70% ~ 80%'
;;
"0x09"|"0x9")
echo '@string:kr_others_ufs_health_used 80% ~ 90%'
;;
"0x0A"|"0xA")
echo '@string:kr_others_ufs_health_used 90% ~ 100%'
;;
"0x0B"|"0xB")
echo "@string:kr_others_ufs_health_over" # 'Exceeded estimated lifetime'
;;
*)
echo '@string:kr_others_ufs_health_used @string:kr_others_ufs_health_unknown'
;;
esac
