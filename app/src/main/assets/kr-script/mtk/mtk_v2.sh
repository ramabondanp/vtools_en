import_utils="source $START_DIR/kr-script/mtk/mtk_utils_v2.sh;"
run="sh $START_DIR/kr-script/mtk"

perfmgr=/sys/module/mtk_fpsgo/parameters/perfmgr_enable
pandora_feas=/sys/module/perfmgr_mtk/parameters/perfmgr_enable
if [[ -f $pandora_feas ]]; then
  perfmgr=$pandora_feas
fi
fpsgo=/sys/kernel/fpsgo/common/fpsgo_enable
hybrid=/data/adb/modules/dimensity_hybrid_governor

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
switch_full() {
    echo "      <switch title=\"$1\" desc=\"$2\">"
    echo "          <get>$3</get>"
    echo "          <set>$4</set>"
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
  local row_id=$(echo "$1" | cut -f1 -d ']')
  echo "${row_id/[/}"
}
get_row_title() {
    echo "$1" | cut -f2 -d ' ' | cut -f1 -d ':'
}
get_row_state() {
    echo "$1" | cut -f2 -d ':'
}


soc=$(getprop ro.hardware)
gpu_render() {
    if [[ -f /proc/gpufreqv2/stack_signed_opp_table ]]; then
        TABLE="/proc/gpufreqv2/stack_signed_opp_table"
    elif [[ -f /proc/gpufreqv2/gpu_working_opp_table ]]; then
        TABLE="/proc/gpufreqv2/gpu_working_opp_table"
    fi

    if [[ "$soc" == "mt6983" || "$soc" == "mt6895" || "$soc" == "mt6789" ]]; then
        if [[ "$soc" == "mt6983" ]]; then
          volt_list="62500 61875 61875 61250 60625 60000 59375 58750 58125 57500 56875 56250 55625 55000 54375 53750 53125 52500 51875 51250 50625 50000"
        elif [[ "$soc" == "mt6789" ]]; then
          volt_list="74375 73750 73750 73125 72500 71875 71875 71250 70625 70000 70000 69375 69375 68750 68125 68125 67500 66875 66875 66250 66250 65625 65000 65000 64375 63750 63750 63125 62500 61875 61250 60625 60625 60000 59375 58750 58125 57500"
        else
          volt_list="62500 61875 61875 61250 60625 60000 59375 58750 58125 57500 56875 56250 55625 55000 54375 53750 53125 52500 51875 51250 50625 50000 49375 48750 48125 47500 46875 46250 45625 45000 44375 43750 43125 42500 41875"
        fi
        echo "      <action title=\"Fixed frequency\" shell=\"hidden\" reload=\"@GPU\" summary-sh=\"$import_utils gpu_freq_cur_khz2\">"
        echo '          <param title="Frequency" name="state" value-sh="'"$import_utils" gpu_freq_cur'">'
        echo "            <option value=\"-1\">Not fixed</option>"
        for freq in $(cat "$TABLE" | awk '{printf $3 "\n"}' | cut -f1 -d ",")
        do
          echo "            <option value=\"$freq\">${freq}KHz</option>"
        done
        echo "          </param>"
        echo '          <param title="Voltage" name="voltage" value-sh="'"$import_utils" gpu_volt_cur'">'
        echo "            <option value=\"-1\">Not fixed</option>"
        for voltage in $volt_list
        do
          echo "            <option value=\"$voltage\">${voltage}</option>"
        done
        echo "          </param>"
        echo "          <set>$import_utils gpu_freq</set>"
        echo "      </action>"
    else
        echo "      <picker title=\"Fixed frequency\" shell=\"hidden\" reload=\"@GPU\" summary-sh=\"$import_utils gpu_freq_cur_khz\">"
        echo "          <options>"
        echo "            <option value=\"-1\">Not fixed</option>"
        for freq in $(cat "$TABLE" | awk '{printf $3 "\n"}' | cut -f1 -d ",")
        do
          echo "            <option value=\"$freq\">${freq}KHz</option>"
        done
        echo "          </options>"
        echo "          <get>$import_utils gpu_freq_cur</get>"
        echo "          <set>$import_utils gpu_freq</set>"
        echo "      </picker>"
    fi

    echo "      <picker title=\"Highest frequency\" shell=\"hidden\" reload=\"@GPU\" summary-sh=\"$import_utils gpu_freq_max_freq_cur_khz\">"
    echo "          <options>"
    cat "$TABLE" | while read freq
    do
      echo "            <option value=\"$(echo "${freq:1:2}")\">$(echo "$freq" | awk '{printf $3 "\n"}' | cut -f1 -d ",")KHz</option>"
    done
    echo "          </options>"
    echo "          <get>$import_utils gpu_freq_max_freq_cur</get>"
    echo "          <set>$import_utils gpu_freq_max_freq</set>"
    echo "      </picker>"
    echo "<text><slice>[Fixed frequency] has a higher priority than [Highest frequency] and cannot be set at the same time.</slice></text>"

    dcs_mode=/sys/kernel/ged/hal/dcs_mode
    if [[ -f $dcs_mode ]]; then
      switch_full "DCS Policy" 'When GPU performance requirements decrease, some cores are shut down to reduce power consumption. But with this feature turned on, sometimes the GPU frequency will jump repeatedly between the lowest/highest.' "if [[ \$(grep enable $dcs_mode) != '' ]]; then echo 1; fi" "$import_utils set_dcs_mode"
    fi

    ged_kpi=/sys/module/sspm_v3/holders/ged/parameters/is_GED_KPI_enabled
    if [[ -f $ged_kpi ]]; then
      switch_full "GED KPI" 'Lower performance to reduce battery consumption, but may cause lag during gaming' "cat $ged_kpi" "$import_utils set_ged_kpi"
    fi

    local dvfs=/proc/mali/dvfs_enable
    if [[ -f $dvfs ]]; then
      switch_hidden "Dynamic Frequency and Voltage Scaling (DVFS)" "cat $dvfs | cut -f2 -d ' '" "echo \$state > $dvfs"
    fi

    if [[ -d '/data/adb/modules/dimensity_hybrid_governor' ]]; then
    switch_hidden 'GPU Hybrid Tuner (step-down)' 'if [[ $(pidof gpu-scheduler) != "" ]]; then echo 1;fi' "$import_utils dimensity_hybrid_switch"
    else
    echo "\
    <action shell=\"hidden\">\
        <title>Get GPU Hybrid Tuner (step-down)</title>\
        <desc>Downloading and using a GPU/DDR auxiliary frequency regulator may reduce power consumption in high-load GPU scenarios, but it doesn't always happen!</desc>\
        <set>am start -a android.intent.action.VIEW -d https://vtools.oss-cn-beijing.aliyuncs.com/addin/dimensity_hybrid_governor.zip</set>\
        <summary sh=\"if [[ '$(pidof gpu-scheduler)' != '' ]]; then echo '正在运行中';fi\" />\
    </action>"
    fi
}

common_render() {
  if [[ -f $fpsgo ]]; then
    switch_full "FPSGO Enable" 'Lower or boost performance based on real-time frame rate to reduce power consumption or improve frame rate stability. However, if this feature is turned on, there may be continuous small frame drops.' "cat $fpsgo" "$import_utils set_fpsgo"
  fi

  if [[ -f $perfmgr ]]; then
    echo "      <switch title=\"Perfmgr Enable\" desc=\"FEAS is implemented through Perfmgr. Enabling this feature can significantly reduce power consumption in some games.\" reload=\"page\">"
    echo "          <get>cat $perfmgr</get>"
    echo "          <set>$import_utils set_perfmgr</set>"
    echo "      </switch>"
  fi
}

ddr_render() {
  dvfsrc='/sys/class/devfreq/mtk-dvfsrc-devfreq'
  opp_table=$dvfsrc/available_frequencies
  echo "      <picker id=\"DDR-MIN-FREQ\" title=\"DDR MinFreq\" shell=\"hidden\" reload=\"@DRAM\">"
  echo "          <options>"
  echo "            <option value=\"0\">Default</option>"
  for freq in $(cat $opp_table)
  do
    if [[ "$freq" != "" ]]; then
    echo "            <option value=\"$freq\">${freq}hz</option>"
    fi
  done
  echo "          </options>"
  echo "          <set>$import_utils ddr_freq</set>"
  echo "          <get>cat $dvfsrc/min_freq</get>"
  echo "      </picker>"


  # 无意义
  dvfsrc2=/sys/kernel/helio-dvfsrc
  opp_table=$dvfsrc2/dvfsrc_opp_table
  echo "      <picker title=\"Fixed DDR frequency\" summary=\"If the voltage is too low, it will crash! ! ! Most of the time, fixed frequency is meaningless and is only used for comparative testing.\" shell=\"hidden\" reload=\"@DRAM\">"
  echo "          <options>"
  echo "            <option value=\"999\">Not fixed</option>"
  grep '\[OPP' $opp_table | while read freq
  do
    if [[ "$freq" != "" ]]; then
    d_opp=$(echo "${freq:4:2}")
    d_khz=$(echo "${freq:9}")
    echo "            <option value=\"$(echo -n "$d_opp")\">${d_khz}</option>"
    fi
  done
  echo "          </options>"
  echo "          <set>$import_utils ddr_freq_fixed</set>"
  echo "      </picker>"
}

xml_start
  resource 'file:///android_asset/kr-script/common'
  resource 'file:///android_asset/kr-script/mtk'

if [[ -f /proc/gpufreqv2/stack_signed_opp_table || -f /proc/gpufreqv2/gpu_signed_opp_table ]]
then
  group_start 'GPU'
    gpu_render
  group_end
fi

group_start 'FPSGO/FEAS'
  common_render
group_end

group_start 'DRAM'
  ddr_render
group_end

xml_end
