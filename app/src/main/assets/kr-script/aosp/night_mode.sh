settings put secure ui_night_mode $state
echo 'It depends on the person's character, may not be able to switch successfully'
if [[ $hotreboot = "1" ]]; then
  echo 'Automatic restart after 3 seconds'
  sync
  sleep 3
  # busybox killall system_server
  reboot
else
  echo 'Some systems may require a reboot of the phone to take effect'
fi