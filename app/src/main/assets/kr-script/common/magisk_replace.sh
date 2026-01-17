#!/system/bin/sh

source ./kr-script/common/magisk.sh
source ./kr-script/common/mount.sh

# Replace
function _replace_file() {
    local resource="$1"
    local output="$2"
    module_installed
    mg="$?"

    if [[ "$mg" = 1 ]]
    then
        echo "Replace via Magisk: $output"
        magisk_replace_file $resource $output
        success="$?"
        if [[ "$success" = 1 ]]; then
            echo 'Operation successful. Please reboot the phone!'
        else
            echo 'Operation failed...' 1>&2
        fi
    else
        echo "Replace $output"
        mount_all

        # Backup resource
        if [[ -f "$output" ]] && [[ ! -f "$output.bak" ]]; then
            cp "$output" "$output.bak"
        fi

        cp $resource $output
        chmod 0755 $output
    fi
}

# Restore
function _restore_file() {
    local resource="$1"
    local output="$2"

    module_installed
    mg="$?"

    # Whether a Magisk module is installed
    if [[ "$mg" = 1 ]]
    then
        magisk_file_exist "$output"
        local file_in_magisk="$?"

        if [[ "$file_in_magisk" = "1" ]]; then
            echo "Remove from Magisk module: $output"
            magisk_cancel_replace $output
            success="$?"
            if [[ "$success" = 1 ]]; then
                if [[ -f $output ]] && [[ -f $resource ]]; then
                    local md5=`busybox md5sum $resource | cut -f1 -d ' '`
                    local verify=`busybox md5sum $output | cut -f1 -d ' '`

                    if [[ "$md5" = "$verify" ]]
                    then
                        echo 'Please reboot the phone for changes to take effect!' 1>&2
                    else
                        echo 'Please reboot the phone for changes to take effect!'
                    fi
                else
                    echo 'Operation completed...'
                fi
            else
                echo 'Operation failed...' 1>&2
            fi
        else
            echo "Restore $output"
            # Restore file physically
            mount_all
            if [[ -f "$output.bak" ]]
            then
                cp "$output.bak" "$output"
            fi
            rm -f $output
        fi
    else
        echo "Restore $output"
        # Remove copy
        rm -f $output
        # Restore file physically
        mount_all
        if [[ -f "$output.bak" ]]
        then
            echo "cp $output.bak $output"
            cp "$output.bak" "$output"
        fi
    fi
}

# Replace file in mixed mode (use Magisk if available, otherwise root replaces system file directly)
# mixture_hook_file "./kr-script/miui/resources/com.android.systemui" "/system/media/theme/default/com.android.systemui" "$mode"
# $mode can be 1 or 0: 1 = replace, 0 = cancel replace
function mixture_hook_file()
{
    local resource="$1"
    local output="$2"
    local mode="$3"

    if [[ $mode = '1' ]]
    then
        _replace_file "$resource" "$output"
    else
        _restore_file "$resource" "$output"
    fi
}

# Whether the file has been replaced in mixed mode (use Magisk if available, otherwise root replaces system file directly)
# file_mixture_hooked "./kr-script/miui/resources/com.android.systemui" "/system/media/theme/default/com.android.systemui"
# @return 1 or 0
function file_mixture_hooked()
{
    local resource="$1"
    local output="$2"
    # Check whether the resource file exists
    if [[ ! -f $resource ]]
    then
        return 0
        exit 0
    fi

    # Whether the file has been replaced in the Magisk module
    magisk_file_exist $output
    exist="$?"

    # Whether the Magisk module replacement matches the expected file
    magisk_file_equals $resource $output
    equals="$?"

    # Verify whether it is replaced in Magisk
    if [[ $exist = 1 ]] && [[ $equals = 1 ]]
    then
        return 1
    else
        # Check whether a replacement exists in System
        if [[ -f $output ]]
        then
            local md5=`busybox md5sum $resource | cut -f1 -d ' '`
            local verify=`busybox md5sum $output | cut -f1 -d ' '`

            if [[ "$md5" = "$verify" ]]
            then
                return 1
            fi
        fi
    fi

    return 0
}
