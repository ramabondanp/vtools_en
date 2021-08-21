platform=`getprop ro.board.platform`
mode="$state"

if [[ ! -n "$MAGISK_PATH" ]]; then
    echo 'Scene add-on module is not enabled, please go to Magisk assistant to initialize the module' 1>&2
    exit 4
fi

install_dir="${MAGISK_PATH}/system/vendor/etc"
mode_state_save="$install_dir/thermal.current.ini"
resource_dir="./kr-script/miui/thermal_conf/$platform/$mode"

thermal_files=(
)

# 覆盖 thermal_files
source ./kr-script/miui/thermal_conf/$platform/thermal_files.sh

function ulock_dir() {
  local dir="$1"
  chattr -R -i "$dir" 2> /dev/null
  rm -rf "$dir" 2> /dev/null
}

function uninstall_thermal() {
    echo 'From' $install_dir Catalogue
    echo 'Uninstall installed custom configuration……'
    echo ''

    ulock_dir /data/thermal
    ulock_dir /data/vendor/thermal

    for thermal in ${thermal_files[@]}; do
        if [[ -f $install_dir/$thermal ]]; then
            echo '移除' $thermal
            rm -f $install_dir/$thermal
        fi
    done
    rm -f "$mode_state_save" 2> /dev/null

    # The previous version is used to store the file of the current configuration mode state
    rm -f "$install_dir/thermal-engine.current.ini" 2> /dev/null

    echo ''
}

function install_thermal() {
    uninstall_thermal

    echo 'Check whether there are conflicts between modules……'
    echo ''

    # Check whether other modules change the temperature control
    local magisk_dir=`echo $MAGISK_PATH | awk -F '/[^/]*$' '{print $1}'`
    local modules=`ls $magisk_dir`
    for module in ${modules[@]}; do
        if [[ ! "$magisk_dir/$module" = "$MAGISK_PATH" ]] && [[ -d "$magisk_dir/$module" ]] && [[ ! -f "$magisk_dir/$module/disable" ]]; then
            local result=`find "$magisk_dir/$module" -name "*thermal*" -type f`
            if [[ -n "$result" ]]; then
                echo 'Found other modules that modify the temperature control：' 1>&2
                echo "$result" 1>&2
                echo 'Please delete the files in the above locations, or disable related modules!' 1>&2
                echo 'Otherwise, Scene cannot replace the system temperature control normally!' 1>&2
                exit 5
            fi
        fi
    done

    echo ''
    echo '#################################'
    cat $resource_dir/info.txt
    echo ''
    echo '#################################'
    echo ''
    echo ''

    if [[ ! -d "$install_dir" ]]; then
        mkdir -p "$install_dir"
    fi

    for thermal in ${thermal_files[@]}; do
        if [[ -f "$resource_dir/$thermal" ]]; then
            echo 'Copy' $thermal
            cp "$resource_dir/$thermal" "$install_dir/$thermal"
        elif [[ -f "$resource_dir/general.conf" ]]; then
            echo 'Copy' $thermal
            cp "$resource_dir/general.conf" "$install_dir/$thermal"
        fi
        dos2unix "$install_dir/$thermal" 2> /dev/null
    done
    echo "$mode" > "$mode_state_save"
}


case "$mode" in
    "default")
        uninstall_thermal
     ;;
    *)
        if [[ -d $resource_dir ]]; then
            install_thermal
        else
            echo 'Error, the selected mode'$mode' is invalid' 1>&2
            exit 1
        fi
    ;;
esac

echo ''
echo 'Please restart your phone for the configuration to take effect!' 1>&2
echo ''
