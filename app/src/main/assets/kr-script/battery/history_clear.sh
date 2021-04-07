#!/system/bin/sh

echo 'Delete power consumption records'
echo 'Note: It only clears the power consumption curve and does not restore battery life!!!'
rm -f /data/system/batterystats-checkin.bin 2>/dev/null
rm -f /data/system/batterystats-daily.xml 2>/dev/null
rm -f /data/system/batterystats.bin 2>/dev/null
rm -rf /data/system/battery-history 2>/dev/null
rm -rf /data/vendor/charge_logger 2>/dev/null
rm -rf /data/charge_logger 2>/dev/null

echo 'About to restart the device'
sync
sleep 2
reboot


