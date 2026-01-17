SRC=$PAGE_WORK_DIR
module='/data/adb/modules/extreme_gt'

if [[ $(getprop sys.extreme_gt.uninstall) == 1 ]];then
  echo '@string:dialog_addin_by_magisk' 1>&2
  return
fi

setprop persist.sys.oplus.wifi.sla.game_high_temperature 50
# setprop persist.oplus.display.vrr 0
setprop persist.sys.environment.temp 25
# setprop persist.sys.horae.enable 0

mkdir -p $module
cat $SRC/extreme_gt/module.prop > $module/module.prop
cat $SRC/extreme_gt/post-fs-data.sh > $module/post-fs-data.sh
if [[ -f $module/disable ]]; then
  rm $module/disable
fi

dirs="/odm /my_product /my_stock /vendor /system/vendor /product /system"

xml_override() {
  mkdir -p $(dirname $module$1)
  overrides="$2"

  for file in $(find $dirs -name "$1")
  do
    mkdir -p $(dirname $module$file)
    rows=$(cat $file)
    for override in $overrides; do
      key=$(echo $override | cut -f1 -d '=')
      value=$(echo $override | cut -f2 -d '=')
      rows=$(echo "$rows" | sed "s/<$key>.*</<$key>$value</")
    done
    echo "$rows" > $module$file
  done
}

# sys_thermal_control_config.xml sys_thermal_control_config_gt.xml
boolValues="feature_enable_item feature_safety_test_enable_item aging_thermal_control_enable_item"
intValues="aging_cpu_level_item high_temp_safety_level_item game_high_perf_mode_item normal_mode_item ota_mode_item racing_mode_item"
for file in $(find $dirs -name "sys_thermal_control_config*.xml")
do
  mkdir -p $(dirname $module$file)
  rows=$(cat $file | grep -v -E '(<gear_config|cpu=|fps=|<scene_|</scene_|<category_|</category_|<subitem|<level|\.)')

  for key in $boolValues; do
    rows=$(echo "$rows" | sed "s/<$key.*\/>/<$key booleanVal=\"false\" \/>/")
  done

  for key in $intValues; do
    rows=$(echo "$rows" | sed "s/<$key.*\/>/<$key intVal=\"-1\" \/>/")
  done

  echo "$rows" | tr -s '\n' > $module$file
done

# sys_thermal_config.xml
xml_override 'sys_thermal_config.xml' "isOpen=0
more_heat_threshold=550
heat_threshold=530
less_heat_threshold=500
preheat_threshold=480
preheat_dex_oat_threshold=460
thermal_battery_temp=0
is_feature_on=0
is_upload_log=0
is_upload_errlog=0"

# sys_high_temp_protect_*。xml
xml_override 'sys_high_temp_protect*xml' "isOpen=0
HighTemperatureProtectSwitch=false
HighTemperatureShutdownSwitch=false
HighTemperatureFirstStepSwitch=false
HighTemperatureProtectFirstStepIn=550
HighTemperatureProtectFirstStepOut=530
HighTemperatureProtectThresholdIn=570
HighTemperatureProtectThresholdOut=550
HighTemperatureProtectShutDown=750
MediumTemperatureProtectThreshold=10000
HighTemperatureDisableFlashSwitch=false
HighTemperatureDisableFlashLimit=480
HighTemperatureEnableFlashLimit=470
HighTemperatureDisableFlashChargeSwitch=false
HighTemperatureDisableFlashChargeLimit=480
HighTemperatureEnableFlashChargeLimit=470
camera_temperature_limit=520
HighTemperatureControlVideoRecordSwitch=false
HighTemperatureDisableVideoRecordLimit=550
HighTemperatureEnableVideoRecordLimit=520
ToleranceThreshold=50
ToleranceStart=480
ToleranceStop=460"

# refresh_rate_config.xml
for file in $(find $dirs -name "refresh_rate_config.xml"); do
  mkdir -p $(dirname $module$file)
  # Some models (e.g., 9RT) have game FPS locks; clearing refresh-rate configs may be unsafe
  # cat $file | grep -v -E '(<tpitem|<item|<record)' | tr -s '\n' > $module$file

  # Some configs break if they contain newlines, for example:
  # <item package="com.mf.xxyzgame.wpp.game.hlqsgdzz.nearme.gamecenter"
  #        rateId="2-2-2-2" /><!--Happy Fruit Slice Battle-->
  # cat $file | grep -v -E '(2-2-2-2|<record)' | tr -s '\n' > $module$file

  # This ignores newlines, but the generated config is very bloated
  sed 's/<!--.*-->//' "$file" | grep -v -E '<item.*2-2-2-2.*/>' | sed 's/2-2-2-2/0-0-0-0/' | grep -v -E '<record' > $module$file

  # echo -n '' > $module$file
  # while read line
  # do
  #   case "$line" in
  #     *"<item"*|*"<tpitem"*|*"<record"*)
  #       case "$line" in
  #         *"0-0-0-0"*|*"activity"*)
  #           echo "  $line" >> $module$file
  #         ;;
  #         *"2-2-2-2"*)
  #           continue
  #         ;;
  #       esac
  #     ;;
  #     *)
  #       echo "$line" >> $module$file
  #     ;;
  #   esac
  # done < $file
done

# thermallevel_to_fps.xml
for file in $(find $dirs -name "thermallevel_to_fps.xml")
do
  mkdir -p $(dirname $module$file)
  cat $file | sed "s/fps=\".*\"/fps=\"144\"/" > $module$file
done

# oppo_display_perf_list.xml
# multimedia_display_perf_list.xml
for file in $(find $dirs -name "oppo_display_perf_list.xml")
do
  mkdir -p $(dirname $module$file)
  echo -n '' > $module$file
  skip=0
  while read line; do
    case "$line" in
     *"<name>"*)
       skip=0
       case "$line" in
        *"sf.dps.feature"*|*"com.android"*|*"system_server"*|*"/system"*|*"com.color"*|*"com.oppo"*|*"com.oplus"**"SmartVolume"*)
          skip=0
          echo "  $line" >> $module$file
        ;;
        *)
          skip=1
        ;;
       esac
     ;;
     '<?xml version="1.0" encoding="UTF-8"?>'|'<filter-conf>'|'</filter-conf>')
         echo "$line" >> $module$file
     ;;
     *)
       if [[ $skip == 0 ]]; then
         echo "  $line" >> $module$file
       fi
     ;;
    esac
  done < $file
done

# sys_resolution_switch_config.xml
for file in $(find $dirs -name "sys_resolution_switch_config.xml")
do
  mkdir -p $(dirname $module$file)
  echo -n '' > $module$file
  skip=0
  while read line; do
    case "$line" in
     *"<item package="*|*"<switchop package="*)
       echo "$line" > /dev/null
     ;;
     *)
       echo "$line" >> $module$file
     ;;
    esac
  done < $file
done

# game_thermal_config.xml
for file in $(find $dirs -name "game_thermal_config.xml")
do
  mkdir -p $(dirname $module$file)
  echo -n '' > $module$file
  if [[ $(grep cluster3 $file) != '' ]];then
  echo '<?xml version="1.0" encoding="utf-8"?>
<game_thermal_config>
    <version>20230829</version>
    <filter-name>game_thermal_config</filter-name>
    <heavy_policy>
        <game_control temp="520" cluster0="-1" cluster1="-1" cluster2="-1" cluster3="-1" fps="60"/>
    </heavy_policy>
    <default_policy>
        <game_control temp="430" cluster0="-1" cluster1="-1" cluster2="-1" cluster3="-1" fps="0"/>
        <game_control temp="440" cluster0="-1" cluster1="-1" cluster2="-1" cluster3="-1" fps="0"/>
        <game_control temp="450" cluster0="-1" cluster1="-1" cluster2="-1" cluster3="-1" fps="0"/>
        <game_control temp="460" cluster0="-1" cluster1="-1" cluster2="-1" cluster3="-1" fps="0"/>
        <game_control temp="470" cluster0="-1" cluster1="-1" cluster2="-1" cluster3="-1" fps="0"/>
        <game_control temp="480" cluster0="-1" cluster1="-1" cluster2="-1" cluster3="-1" fps="0"/>
        <game_control temp="490" cluster0="-1" cluster1="-1" cluster2="-1" cluster3="-1" fps="0"/>
        <game_control temp="510" cluster0="-1" cluster1="-1" cluster2="-1" cluster3="-1" fps="0"/>
    </default_policy>
</game_thermal_config>' > $module$file
  else
  echo '<?xml version="1.0" encoding="utf-8"?>
<game_thermal_config>
    <version>20230829</version>
    <filter-name>game_thermal_config</filter-name>
    <heavy_policy>
        <game_control temp="520" cluster0="-1" cluster1="-1" cluster2="-1" fps="60"/>
    </heavy_policy>
    <default_policy>
        <game_control temp="430" cluster0="-1" cluster1="-1" cluster2="-1" fps="0"/>
        <game_control temp="440" cluster0="-1" cluster1="-1" cluster2="-1" fps="0"/>
        <game_control temp="450" cluster0="-1" cluster1="-1" cluster2="-1" fps="0"/>
        <game_control temp="460" cluster0="-1" cluster1="-1" cluster2="-1" fps="0"/>
        <game_control temp="470" cluster0="-1" cluster1="-1" cluster2="-1" fps="0"/>
        <game_control temp="480" cluster0="-1" cluster1="-1" cluster2="-1" fps="0"/>
        <game_control temp="490" cluster0="-1" cluster1="-1" cluster2="-1" fps="0"/>
        <game_control temp="510" cluster0="-1" cluster1="-1" cluster2="-1" fps="0"/>
    </default_policy>
</game_thermal_config>' > $module$file
  fi
done

# devices_config.json
for file in $(find $dirs -name "devices_config.json")
do
  mkdir -p $(dirname $module$file)
  echo -n '' > $module$file
  while read line; do
    case "$line" in
     *'"high.capacity.threshold": 100'*)
       echo "$line" >> $module$file
     ;;
     *'"battery.temperate.range":'*)
       echo '"battery.temperate.range": "[100,500]",' >> $module$file
     ;;
     *'"high.capacity.battery.temperate.range":'*)
       echo '"high.capacity.battery.temperate.range": "[100,500]",' >> $module$file
     ;;
     *'"high.capacity.threshold":'*)
       echo '"high.capacity.threshold": 85' >> $module$file
     ;;
     *)
       echo "$line" >> $module$file
     ;;
    esac
  done < $file
done

# charging_thermal_config_default.txt charging_hyper_mode_config.txt
for file in $(find $dirs -name "charging_*txt")
do
  mkdir -p $(dirname $module$file)
  echo -n '' > $module$file
  while read line; do
    case "$line" in
     *:=*)
       echo "$line" >> $module$file
     ;;
     *,*,*)
       temp=$(echo "$line" | awk -F, '{print $1}')
       current=$(echo "$line" | awk -F, '{print $2}')
       t=$(echo "$line" | awk -F, '{print $3}')
       temp=$((temp+50)) # + 5°C
       echo "$temp,$current,$t" >> $module$file
     ;;
     *)
       echo "$line" >> $module$file
     ;;
    esac
  done < $file
done

# D1100/1200
soc=$(getprop ro.board.platform)
if [[ "$soc" == 'mt6891' ]] || [[ "$soc" == 'mt6893' ]] || [[ "$soc" == 'mt6889' ]]; then
  mkdir -p $module/system/vendor/etc
  mkdir -p $module/system/vendor/etc/.tp
  if [[ -d /odm/etc/powerhal ]]; then
    mkdir -p $module/odm/etc/powerhal
  fi

  for file in power_app_cfg.xml powercontable.xml powerscntbl.xml
  do
    cp -f $SRC/extreme_gt/d1x00/$file $module/system/vendor/etc/$file
    if [[ -d /odm/etc/powerhal ]]; then
      cp -f $SRC/extreme_gt/d1x00/$file $module/odm/etc/powerhal/$file
    fi
  done
  cp -f $SRC/extreme_gt/d1x00/tp/ht120.mtc $module/system/vendor/etc/.tp/.ht120.mtc
  cp -f $SRC/extreme_gt/d1x00/tp/thermal_policy_08 $module/system/vendor/etc/.tp/.thermal_policy_08
  cp -f $SRC/extreme_gt/d1x00/tp/thermal.conf $module/system/vendor/etc/.tp/thermal.conf
  cp -f $SRC/extreme_gt/d1x00/tp/thermal.off.conf $module/system/vendor/etc/.tp/thermal.off.conf
  cat $SRC/extreme_gt/d1x00/service.sh > $module/service.sh
else
  cat $SRC/extreme_gt/service.sh > $module/service.sh
fi

manufacturer=$(getprop ro.product.odm.manufacturer)
soc=$(getprop ro.soc.model | tr 'a-z' 'A-Z')

echo 'persist.sys.horae.enable=0' > $module/system.prop
if [[ -f $START_DIR/orms_core_config.xml ]]; then
  mkdir -p $module/odm/etc/orms
  cp -f $START_DIR/orms_core_config.xml $module/odm/etc/orms/orms_core_config.xml
fi

# Mediatek thermal config
mtk_t=/vendor/etc/thermal
if [[ -d $mtk_t ]]; then
  mkdir -p $module/system$mtk_t
  for file in `ls $mtk_t`
  do
    case $file in
      "disable_"*|"fix_ttj_95.conf")
        cp $mtk_t/$file $module/system$mtk_t/
      ;;
      "fix_ttj_85.conf")
        cp $mtk_t/fix_ttj_95.conf $module/system$mtk_t/
      ;;
      *)
        echo $file
        if [[ -f $mtk_t/disable_skin_control.conf ]]; then
         cp $mtk_t/disable_skin_control.conf $module/system$mtk_t/$file
        else
         cp $mtk_t/fix_ttj_95.conf $module/system$mtk_t/$file
        fi
      ;;
    esac
  done
fi

handle_partition() {
  # if /system/vendor is a symlink, we need to move it out of $MODPATH/system, otherwise it will be overlayed
  # if /system/vendor is a normal directory, it is ok to overlay it and we don't need to overlay it separately.

  if [ -L "/system/$1" ] && [ "$(readlink -f /system/$1)" = "/$1" ]; then
    # we create a symlink if module want to access $module/system/$1
    # but it doesn't always work(ie. write it in post-fs-data.sh would fail because it is readonly)
    if [ -e $module/system/$1 ]; then
      mv -f $module/system/$1 $module/$1
    fi
    if [ -e ../$1 ]; then
      ln -sf ../$1 $module/system/$1
    fi
  fi
}

cd $module
mkdir -p $module/system
handle_partition 'vendor'
handle_partition 'system_ext'
handle_partition 'product'

echo '@string:dialog_addin_by_magisk' 1>&2
