install_dir="${MAGISK_PATH}/system/vendor/etc"
# Plan 2 - replace to /data
install_dir="/data/vendor/thermal/config"

if [[ -f "$install_dir/thermal-engine.current.ini" ]]; then
    # Old version
    mode=`cat "$install_dir/thermal-engine.current.ini"`
elif [[ -f "$install_dir/thermal.current.ini" ]]; then
    # New version
    mode=`cat "$install_dir/thermal.current.ini"`
else
    mode=''
fi

echo $mode
