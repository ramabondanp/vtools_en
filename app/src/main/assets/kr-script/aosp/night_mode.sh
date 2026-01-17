settings put secure ui_night_mode $state
echo 'May or may not switch successfully on this device'
if [[ $hotreboot = "1" ]]; then
  echo 'Auto reboot in 3 seconds'
  sync
  sleep 3
  # busybox killall system_server
  reboot
else
  echo 'Some systems may require a reboot to take effect'
fi
