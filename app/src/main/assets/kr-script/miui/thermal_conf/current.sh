dir="${MAGISK_PATH}/system/vendor/etc"

if [[ -f "$dir/thermal-engine.current.ini" ]]; then
    # Old version
    mode=`cat "$dir/thermal-engine.current.ini"`
elif [[ -f "$dir/thermal.current.ini" ]]; then
    # New edition
    mode=`cat "$dir/thermal.current.ini"`
else
    mode=''
fi

echo $mode