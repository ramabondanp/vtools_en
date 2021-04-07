#!/system/bin/sh

echo 'Compilation mode：' $mode
echo 'Start execution...'
echo ''

for item in `pm list packages $app`
do
	app=${item:8}
	echo "> $app"
	cmd package compile -m $mode $app 1>/dev/null
done
