#!/system/bin/sh

source ./kr-script/common/magisk.sh
source ./kr-script/common/mount.sh

# 替换
function _replace_file() {
    local resource="$1"
    local output="$2"
    module_installed
    mg="$?"

    if [[ "$mg" = 1 ]]
    then
        echo "Replace by Magisk $output"
        magisk_replace_file $resource $output
        success="$?"
        if [[ "$success" = 1 ]]; then
            echo 'Operation successful, please restart your phone!'
        else
            echo 'Operation failure...' 1>&2
        fi
    else
        echo "Replace $output"
        mount_all

        # 备份资源
        if [[ -f "$output" ]] && [[ ! -f "$output.bak" ]]; then
            cp "$output" "$output.bak"
        fi

        cp $resource $output
        chmod 0755 $output
    fi
}

# 还原
function _restore_file() {
    local resource="$1"
    local output="$2"

    module_installed
    mg="$?"

    # 是否安装了magisk模块
    if [[ "$mg" = 1 ]]
    then
        magisk_file_exist "$output"
        local file_in_magisk="$?"

        if [[ "$file_in_magisk" = "1" ]]; then
            echo "Remove from Magisk module $output"
            magisk_cancel_replace $output
            success="$?"
            if [[ "$success" = 1 ]]; then
                if [[ -f $output ]] && [[ -f $resource ]]; then
                    local md5=`busybox md5sum $resource | cut -f1 -d ' '`
                    local verify=`busybox md5sum $output | cut -f1 -d ' '`

                    if [[ "$md5" = "$verify" ]]
                    then
                        echo 'Please restart your phone to make the changes take effect!' 1>&2
                    else
                        echo 'Please restart your phone to make the changes take effect!'
                    fi
                else
                    echo 'Operation completed...'
                fi
            else
                echo 'Operation failure...' 1>&2
            fi
        else
            echo "Restore $output"
            # 物理还原文件
            mount_all
            if [[ -f "$output.bak" ]]
            then
                cp "$output.bak" "$output"
            fi
            rm -f $output
        fi
    else
        echo "Restore $output"
        # 移除副本
        rm -f $output
        # 物理还原文件
        mount_all
        if [[ -f "$output.bak" ]]
        then
            echo "cp $output.bak $output"
            cp "$output.bak" "$output"
        fi
    fi
}

# 混合模式替换文件(如果有magisk就用magisk，否则就用root直接替换系统文件)
# mixture_hook_file "./kr-script/miui/resources/com.android.systemui" "/system/media/theme/default/com.android.systemui" "$mode"
# $mode 可是 1 或者 0，1表示替换，0表示取消替换
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

# 是否已用混合模式替换了文件(如果有magisk就用magisk，否则就用root直接替换系统文件)
# file_mixture_hooked "./kr-script/miui/resources/com.android.systemui" "/system/media/theme/default/com.android.systemui"
# @return 【1】或【0】
function file_mixture_hooked()
{
    local resource="$1"
    local output="$2"
    # 检查用于替换的资源文件是否存在
    if [[ ! -f $resource ]]
    then
        return 0
        exit 0
    fi

    # 是否已经在magisk模块里替换文件
    magisk_file_exist $output
    exist="$?"

    # magisk模块里的替换文件是否和预期相同
    magisk_file_equals $resource $output
    equals="$?"

    # 验证是否已经在Magisk中替换
    if [[ $exist = 1 ]] && [[ $equals = 1 ]]
    then
        return 1
    else
        # 判断是否已经在System里存在替换文件
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
