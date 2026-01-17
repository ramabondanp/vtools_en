if [[ $(getprop sys.extreme_gt.uninstall) == 1 ]];then
  echo '@string:dialog_addin_by_magisk' 1>&2
  return
fi

# module='extreme_gt_flyme'
module='/data/adb/modules/extreme_gt_flyme'
mkdir -p $module
cat $PAGE_WORK_DIR/extreme_gt_flyme/module.prop > $module/module.prop
cat $PAGE_WORK_DIR/extreme_gt_flyme/module_uninstall.sh > $module/uninstall.sh
cat $PAGE_WORK_DIR/extreme_gt_flyme/service.sh > $module/service.sh
cat $PAGE_WORK_DIR/extreme_gt_flyme/post-fs-data.sh > $module/post-fs-data.sh
if [[ -f $module/disable ]]; then
  rm $module/disable
fi


mkdir -p $module/system/vendor/etc
ls /system/vendor/etc/thermal*.conf | while read file
do
  echo '# File empty by default.
# Replace contents of this file with custom configuration.
[MONITOR-THERM-CHARGER]
algo_type monitor
sampling 2000
sensor virtual-sensor-0
thresholds     40000 42000 44000 45000 46000 47000 48000
thresholds_clr 39000 40000 42000 44000 45000 46000 47000
actions mz_chg mz_chg mz_chg mz_chg mz_chg mz_chg mz_chg
action_info    8000 7000 6000 5000 4000 3000 2000' > $module$file
done

chg='/system/vendor/etc/meizu_charging.ini'
if [[ -e $chg ]]; then
  if [[ -d /sys/class/meizu/charger/wired ]]; then
    wired="/sys/class/meizu/charger/wired"
    wireless="/sys/class/meizu/charger/wireless"
  else
    wired="/sys/class/meizu/charger"
    wireless="/sys/class/meizu/wireless"
  fi
  wired_level="$wired/wired_level"
  wls_level="$wireless/wls_level"

  echo '[setting]

[wired_charging.level0]
path = '$wired_level'
value = 1

[wired_charging.level1]
path = '$wired_level'
value = 4

[wired_charging.level2]
path = '$wired_level'
value = 6

[wired_charging.level3]
path = '$wired_level'
value = 8

[wired_charging.level4]
path = '$wired_level'
value = 8

[wired_charging.level5]
path = '$wired_level'
value = 9

[wired_charging.level6]
path = '$wired_level'
value = 9

[wired_charging.level7]
path = '$wired_level'
value = 9

[wired_charging.level8]
path = '$wired_level'
value = 10

[wired_charging.level9]
path = '$wired_level'
value = 10

[wired_charging.level10]
path = '$wired_level'
value = 10

[reverse_wireless_charging.enable]
path = '$wireless'/reverse_chg_enable
value = 1

[reverse_wireless_charging.disable]
path = '$wireless'/reverse_chg_enable
value = 0

[wireless_tx_fan.mode0]
path = '$wireless'/tx_fan_mode
value = 0

[wireless_tx_fan.mode1]
path = '$wireless'/tx_fan_mode
value = 1

[wireless_charging.level0]
path = '$wls_level'
value = 0

[wireless_charging.level1]
path = '$wls_level'
value = 4

[wireless_charging.level2]
path = '$wls_level'
value = 6

[wireless_charging.level3]
path = '$wls_level'
value = 8

[wireless_charging.level4]
path = '$wls_level'
value = 8

[wireless_charging.level5]
path = '$wls_level'
value = 8

[wireless_charging.level6]
path = '$wls_level'
value = 8

[wireless_charging.level7]
path = '$wls_level'
value = 9

[wireless_charging.level8]
path = '$wls_level'
value = 9

[wireless_charging.level9]
path = '$wls_level'
value = 10

[wireless_charging.level10]
path = '$wls_level'
value = 10

[wireless_tx_model]
path = '$wireless'/txid
' > $module$chg
fi

rr=/system/vendor/etc/display/thermallevel_to_fps.xml
if [[ -e $rr ]]; then
  mkdir -p $module/system/vendor/etc/display
  echo '<?xml version="1.0" ?>
<!--
Copyright (c) 2021 Qualcomm Technologies, Inc.
All Rights Reserved.
Confidential and Proprietary - Qualcomm Technologies, Inc.
-->
<ThermalLevelToFPSMap>
    <DeviceSettingList>
        <DefaultDevice version="1"/>
        <Device version="1">
            <ThermalLevelMap level="1" fps="144"/>
            <ThermalLevelMap level="2" fps="144"/>
            <ThermalLevelMap level="3" fps="144"/>
            <ThermalLevelMap level="4" fps="144"/>
            <ThermalLevelMap level="5" fps="144"/>
            <ThermalLevelMap level="6" fps="144"/>
            <ThermalLevelMap level="7" fps="144"/>
            <ThermalLevelMap level="8" fps="144"/>
            <ThermalLevelMap level="9" fps="144"/>
            <ThermalLevelMap level="10" fps="144"/>
        </Device>
    </DeviceSettingList>
</ThermalLevelToFPSMap>' > $module$rr
fi

# Disable LTPO to reduce inexplicable frame drops
echo 'ro.surface_flinger.use_content_detection_for_refresh_rate=0' > $module/system.prop
settings put global disable_dynamic_refresh_rate 1
if [[ $(getprop ro.product.odm.device) == 'meizu20Pro' ]]; then
  settings put global flyme_force_rate 120
fi

handle_partition() {
    # if /system/vendor is a symlink, we need to move it out of $MODPATH/system, otherwise it will be overlayed
    # if /system/vendor is a normal directory, it is ok to overlay it and we don't need to overlay it separately.
    if [ ! -e $module/system/$1 ]; then
        # no partition found
        return;
    fi

    if [ -L "/system/$1" ] && [ "$(readlink -f /system/$1)" = "/$1" ]; then
        # we create a symlink if module want to access $module/system/$1
        # but it doesn't always work(ie. write it in post-fs-data.sh would fail because it is readonly)
        mv -f $module/system/$1 $module/$1 && ln -sf ../$1 $module/system/$1
    fi
}

if [[ "$KSU" == "true" ]] || [[ $(which ksud) != "" ]]; then
  handle_partition 'vendor'
  handle_partition 'system_ext'
  handle_partition 'product'
fi

echo '@string:dialog_addin_by_magisk' 1>&2
