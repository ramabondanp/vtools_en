import_utils="source $START_DIR/kr-script/mtk/mtk_utils.sh;"
run="sh $START_DIR/kr-script/mtk"

xml_start() {
    echo '<?xml version="1.0" encoding="UTF-8" ?>'
    echo "<root>"
}
xml_end() {
    echo "</root>"
}
resource() {
    echo "  <resource dir=\"$1\" />"
}
group_start() {
    echo "  <group id=\"@$1\" title=\"$1\">"
}
group_end() {
    echo "  </group>"
}
switch() {
    echo "      <switch title=\"$1\">"
    echo "          <get>$2</get>"
    echo "          <set>$3</set>"
    echo "      </switch>"
}
switch_hidden() {
    echo "      <switch title=\"$1\" shell=\"hidden\" >"
    echo "          <get>$2</get>"
    echo "          <set>$3</set>"
    echo "      </switch>"
}

action() {
    echo "      <action confirm=\"true\" title=\"$1\">"
    echo "          <desc>$2</desc>"
    echo "          <set>$3</set>"
    echo "      </action>"
}

get_row_id() {
  local row_id=`echo $1 | cut -f1 -d ']'`
  echo ${row_id/[/}
}
get_row_title() {
    echo $1 | cut -f2 -d ' ' | cut -f1 -d ':'
}
get_row_state() {
    echo $1 | cut -f2 -d ':'
}

ppm_render() {
    switch_hidden "Enable PPM" "state=\`cat /proc/ppm/enabled | grep enabled\`; if [[ \$state != '' ]]; then echo 1; fi" "echo \$state > /proc/ppm/enabled"

    path="/proc/ppm/policy_status"
    cat $path | grep 'PPM_' | while read line
    do
      id=`get_row_id "$line"`
      title=`get_row_title "$line"`
      state=`get_row_state "$line"`
      # echo $id $title $state
      switch_hidden "$title" "cat $path | grep $title | grep enabled 1>&amp;2 > /dev/null &amp;&amp; echo 1" "echo $id \$state > $path"
    done
}

ged_render() {
    local ged="/sys/module/ged/parameters"
    ls -1 $ged | grep -v "log" | grep -v "debug" | grep -E "enable|_on|mode" | while read line
    do
      # echo $line
      local title="$line"
      if [[ "$line" == "gpu_dvfs_enable" ]]; then
        title="Dynamic freq/volt scaling"
      elif [[ "$line" == "ged_force_mdp_enable" ]]; then
        title="Force MDP"
      elif [[ "$line" == "gx_game_mode" ]]; then
        title="Game mode"
      else
        continue # Hide options with poor effect for now
      fi
      switch_hidden "$title" "cat $ged/$line" "echo \$state > $ged/$line"
    done
}

soc=$(getprop ro.hardware)
gpu_render() {
    if [[ "$soc" == "mt6891" || "$soc" == "mt6893" ]]; then
      volt_list="65000 64375 63750 63125 62500 61875 61875 61250 60625 60000 59375 58750 58125 57500 56875 56250 55625 55000 54375 53750 53125 52500 51875 51250 50625 50000 49375 48750 48125 47500 46875 46250 45625 45000 44375 43750"
        echo "      <action title=\"Fixed Frequency\" shell=\"hidden\" reload=\"@GPU\" summary-sh=\"$import_utils gpu_freq_cur_khz\">"
        echo '          <param title="Frequency" name="state" value-sh="'$import_utils gpu_freq_cur'">'
        echo "            <option value=\"0\">No fixed</option>"
        for freq in $(cat /proc/gpufreq/gpufreq_opp_dump | awk '{printf $4 "\n"}' | cut -f1 -d ",")
        do
          echo "            <option value=\"$freq\">${freq}KHz</option>"
        done
        echo "          </param>"
        echo '          <param title="Voltage" name="voltage" value-sh="'$import_utils gpu_volt_cur'">'
        echo "            <option value=\"-1\">No fixed</option>"
        for voltage in $volt_list
        do
          echo "            <option value=\"$voltage\">${voltage}</option>"
        done
        echo "          </param>"
        echo "          <set>$import_utils gpu_freq</set>"
        echo "      </action>"
    else
        # local freqs=$(cat /proc/gpufreq/gpufreq_opp_dump | awk '{printf $4 "\n"}' | cut -f1 -d ",")
        local get_shell="cat /proc/gpufreq/gpufreq_opp_freq | grep freq | awk '{printf \$4 \"\\\\n\"}' | cut -f1 -d ','"

        echo "      <picker title=\"Fixed Frequency\" shell=\"hidden\" reload=\"@GPU\" summary-sh=\"$import_utils gpu_freq_cur_khz\">"
        echo "          <options>"
        echo "            <option value=\"0\">No fixed</option>"
        for freq in $(cat /proc/gpufreq/gpufreq_opp_dump | awk '{printf $4 "\n"}' | cut -f1 -d ",")
        do
          echo "            <option value=\"$freq\">${freq}KHz</option>"
        done
        echo "          </options>"
        echo "          <get>$get_shell</get>"
        echo "          <set>$import_utils gpu_freq</set>"
        echo "      </picker>"
    fi
    echo "      <picker title=\"Max Frequency\" shell=\"hidden\" reload=\"@GPU\" summary-sh=\"$import_utils gpu_freq_max_freq_cur_khz\">"
    echo "          <options>"
    for freq in $(cat /proc/gpufreq/gpufreq_opp_dump | awk '{printf $4 "\n"}' | cut -f1 -d ",")
    do
      echo "            <option value=\"$freq\">${freq}KHz</option>"
    done
    echo "          </options>"
    echo "          <get>$import_utils gpu_freq_max_freq_cur</get>"
    echo "          <set>$import_utils gpu_freq_max_freq</set>"
    echo "      </picker>"


    local dvfs=/proc/mali/dvfs_enable
    if [[ -f $dvfs ]]; then
      switch_hidden "Dynamic freq/volt scaling (DVFS)" "cat $dvfs | cut -f2 -d ' '" "echo \$state > $dvfs"
    fi

    if [[ -d '/data/adb/modules/dimensity_hybrid_governor' ]]; then
    switch_hidden 'GPU Hybrid Governor (Undervolt)' 'if [[ $(pidof gpu-scheduler) != "" ]]; then echo 1;fi' "$import_utils dimensity_hybrid_switch"
    else
    echo "\
    <action shell=\"hidden\">\
        <title>Get GPU Hybrid Governor (Undervolt)</title>\
        <desc>Download and use the GPU/DDR auxiliary governor. It may reduce GPU power under heavy load, but not always.</desc>\
        <set>am start -a android.intent.action.VIEW -d https://vtools.oss-cn-beijing.aliyuncs.com/addin/dimensity_hybrid_governor.zip</set>\
        <summary sh=\"if [[ '$(pidof gpu-scheduler)' != '' ]]; then echo 'Running';fi\" />\
    </action>"
    fi
}

cpu_render() {
    if [[ -f /sys/devices/system/cpu/sched/sched_boost ]]; then
      echo "      <picker title=\"Sched Boost\" shell=\"hidden\">"
      echo "          <options>"
      echo "            <option value=\"no boost\">no boost</option>"
      echo "            <option value=\"all boost\">all</option>"
      echo "            <option value=\"foreground boost\">foreground</option>"
      echo "          </options>"
      echo "          <get>$import_utils sched_boost_get</get>"
      echo "          <set>$import_utils sched_boost_set</set>"
      echo "      </picker>"
    fi

    if [[ -f /sys/devices/system/cpu/eas/enable ]]; then
      echo "      <picker title=\"Eas Enable\" shell=\"hidden\">"
      echo "          <options>"
      echo "            <option value=\"HMP\">HMP</option>"
      echo "            <option value=\"EAS\">EAS</option>"
      echo "            <option value=\"hybrid\">Hybrid</option>"
      echo "          </options>"
      echo "          <get>$import_utils eas_get</get>"
      echo "          <set>$import_utils eas_set</set>"
      echo "      </picker>"
    fi
}

ddr_render() {
  dvfsrc=/sys/devices/platform/10012000.dvfsrc/helio-dvfsrc
  opp_table=$dvfsrc/dvfsrc_opp_table
  echo "      <picker title=\"Fixed DDR Frequency\" summary=\"If voltage is too low, the device may crash!!!\" shell=\"hidden\" reload=\"@DRAM\">"
  echo "          <options>"
  echo "            <option value=\"-1\">No fixed</option>"
  cat $opp_table | while read freq
  do
    if [[ "$freq" != "" ]]; then
    d_opp=$(echo "${freq:4:2}")
    d_khz=$(echo ${freq:9})
    echo "            <option value=\"$d_opp\">${d_khz}</option>"
    fi
  done
  echo "          </options>"
  echo "          <set>$import_utils ddr_freq</set>"
  echo "      </picker>"
}

# GPU memory usage bytes
# cat /proc/mali/memory_usage | grep "Total" | cut -f2 -d "(" | cut -f1 -d " "

xml_start
    resource 'file:///android_asset/kr-script/common'
    resource 'file:///android_asset/kr-script/mtk'
    group_start 'PPM'
        ppm_render
    group_end

    # group_start 'GED'
    #     ged_render
    # group_end

if [[ -f /proc/gpufreq/gpufreq_opp_freq ]]
then
    group_start 'GPU'
      gpu_render
    group_end
fi


group_start 'CPU'
  cpu_render
group_end

if [[ -f /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp ]]; then
group_start 'DRAM'
  ddr_render
group_end
fi

if [[ -f /proc/eem/EEM_DET_L/eem_offset ]]; then
group_start 'Voltage Offset'

# Little
if [[ -f /proc/eem/EEM_DET_L/eem_offset ]]; then
echo '  <action title="Little Cores" shell="hidden" summary-sh="cat /proc/eem/EEM_DET_L/eem_offset">'
echo '      <param name="value" value-sh="cat /proc/eem/EEM_DET_L/eem_offset" type="seekbar" min="-50" max="50" />'
echo "      <set>$import_utils eem_offset L \$value</set>"
echo '  </action>'
fi

# Middle
if [[ -f /proc/eem/EEM_DET_BL/eem_offset ]]; then
echo '  <action title="Middle Cores" shell="hidden" summary-sh="cat /proc/eem/EEM_DET_BL/eem_offset">'
echo '      <param name="value" value-sh="cat /proc/eem/EEM_DET_BL/eem_offset" type="seekbar" min="-50" max="50" />'
echo "      <set>$import_utils eem_offset BL \$value</set>"
echo '  </action>'
fi

# Big
if [[ -f /proc/eem/EEM_DET_B/eem_offset ]]; then
echo '  <action title="Big Cores" shell="hidden" summary-sh="cat /proc/eem/EEM_DET_B/eem_offset">'
echo '      <param name="value" value-sh="cat /proc/eem/EEM_DET_B/eem_offset" type="seekbar" min="-50" max="50" />'
echo "      <set>$import_utils eem_offset B \$value</set>"
echo '  </action>'
fi

# CCI
if [[ -f /proc/eem/EEM_DET_CCI/eem_offset ]]; then
echo '  <action title="CCI" shell="hidden" summary-sh="cat /proc/eem/EEM_DET_CCI/eem_offset">'
echo '      <param name="value" value-sh="cat /proc/eem/EEM_DET_CCI/eem_offset" type="seekbar" min="-50" max="50" />'
echo "      <set>$import_utils eem_offset CCI \$value</set>"
echo '  </action>'
fi

# GPU
if [[ -f /proc/eemg/EEMG_DET_GPU/eemg_offset ]]; then
echo '  <action title="GPU" shell="hidden" summary-sh="cat /proc/eemg/EEMG_DET_GPU/eemg_offset">'
echo '      <param name="value" value-sh="cat /proc/eemg/EEMG_DET_GPU/eemg_offset" type="seekbar" min="-50" max="50" />'
echo "      <set>$import_utils eemg_offset GPU \$value</set>"
echo '  </action>'
fi

# GPU_HI
if [[ -f /proc/eemg/EEMG_DET_GPU_HI/eemg_offset ]]; then
echo '  <action title="GPU HI" shell="hidden" summary-sh="cat /proc/eemg/EEMG_DET_GPU_HI/eemg_offset">'
echo '      <param name="value" value-sh="cat /proc/eemg/EEMG_DET_GPU_HI/eemg_offset" type="seekbar" min="-50" max="50" />'
echo "      <set>$import_utils eemg_offset GPU_HI \$value</set>"
echo '  </action>'
fi

if [[ -n "$MAGISK_PATH" ]] && [[ -d "$MAGISK_PATH" ]]
then
echo '  <action title="[Magisk]Automatic apply" summary-sh="'$import_utils' eem_module_summary" desc="Keep the current adjustment after restarting the phone\nKeep current settings after reboot">'
echo "      <set>$run/install_eem_module.sh</set>"
echo '  </action>'
fi
group_end
fi


if [[ -n "$MAGISK_PATH" ]] && [[ -d "$MAGISK_PATH" ]]
then
  group_start 'PowerPolicy'
    powerscntbl=/system/vendor/etc/powerscntbl.xml
    if [[ -f $powerscntbl ]]; then
      if [[ $(grep 'powerhint' $powerscntbl) != "" ]]; then
        action "Disable Scenario Boost" "Disable scenario boost to manually control CPU performance, but responsiveness will drop significantly." "$run/powerscntbl_remove.sh"
      else
        action "Enable Scenario Boost" "Restore scenario boost; reboot immediately after restoring." "$run/powerscntbl_restore.sh"
      fi
    fi
    power_app_cfg=/system/vendor/etc/power_app_cfg.xml
    if [[ -f $power_app_cfg ]]; then
      if [[ $(grep '<Package name' $power_app_cfg) != "" ]]; then
        action "Disable AppConfig" "Disable AppConfig (per-app/Activity performance policy). This helps manual control but may reduce performance in some cases." "$run/power_app_cfg_remove.sh"
      else
        action "Enable AppConfig" "Restore AppConfig (per-app/Activity performance policy)." "$run/power_app_cfg_restore.sh"
      fi
    fi
  group_end
fi

group_start 'Battery Stats'
    if [[ -f /sys/devices/platform/battery/reset_battery_cycle ]]
    then
      action "Reset Battery Cycle Count" "Reset the recorded battery cycle count (this does not restore capacity)." "echo 1 &gt; /sys/devices/platform/battery/reset_battery_cycle"
    fi

    if [[ -f /sys/devices/platform/battery/reset_aging_factor ]]
    then
      action "Reset Battery Aging Factor" "Reset the recorded battery aging factor (does not restore battery life; may cause sudden shutdown at low battery)." "echo 1 &gt; /sys/devices/platform/battery/reset_aging_factor"
    fi
group_end


group_start 'Thermal'
echo "      <picker reload=\"@Thermal\" options-sh=\"ls -a /vendor/etc/.tp | grep -E 'conf|mtc|thermal'\" title=\"Profile\" desc=\"Switch thermal profile; choosing ht120 may overheat and reboot!\" shell=\"hidden\">"
echo "          <set>$import_utils thermal_profile</set>"
echo "      </picker>"

echo "      <switch title=\"SSPM Thermal Throttle\" shell=\"hidden\" desc=\"Enabling this disables some automatic throttling, which may cause overheating damage or sudden reboot\" reload=\"@Thermal\">"
echo "          <get>cat /proc/driver/thermal/sspm_thermal_throttle | cut -f2 -d ':'</get>"
echo "          <set>$import_utils sspm_thermal_throttle</set>"
echo "      </switch>"

platform=$(getprop ro.board.platform)
if [[ "$platform" == "mt6893" ]] || [[ "$platform" == "mt6891" ]] || [[ "$platform" == "mt6885" ]] || [[ "$platform" == "mt6875" ]];then
echo "      <switch title=\"Thermal UltraLimit\" desc=\"Raise CPU thermal shutdown temp (default 120C) to 145C; may cause overheating damage!!!\" reload=\"@Thermal\">"
echo "          <get>$import_utils ultra_limit_get</get>"
echo "          <set>$import_utils ultra_limit_set</set>"
echo "      </switch>"
fi
group_end


xml_end
