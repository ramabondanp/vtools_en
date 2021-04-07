echo 'This operation does not improve performance' 1>&2
echo 'If you don't know what it is, tap the [Exit] button on the interface!' 1>&2
echo ''
echo 'Otherwise, the operation starts after 25 seconds' 1>&2
echo 'It takes a long time to turn on the computer next time...' 1>&2

echo ''
sleep 25
sync
echo ''
rm -rf /cache/dalvik-cache
reboot