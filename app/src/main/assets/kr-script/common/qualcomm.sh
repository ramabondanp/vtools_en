if [[ -f /sys/devices/soc0/machine ]] && [[ $(cat /sys/devices/soc0/machine | tr a-z A-Z) != MT* ]]; then
  echo 1
else
  echo 0
fi