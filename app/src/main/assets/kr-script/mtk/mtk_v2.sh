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
    echo "      <switch title=\"$1\" desc=\"$2\" shell=\"hidden\" >"
    echo "          <get>$3</get>"
    echo "          <set>$4</set>"
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

    echo "      <picker title=\"Highest frequency\" shell=\"hidden\" reload=\"@GPU\" summary-sh=\"$import_utils gpu_freq_max_freq_cur_khz\">"
    echo "          <desc>[Fixed frequency] has a higher priority than [Highest frequency] and cannot be set at the same time.</desc>"
    echo "          <options>"
    cat "$TABLE" | while read freq
    do
      echo "            <option value=\"$(echo "${freq:1:2}")\">$(echo "$freq" | awk '{printf $3 "\n"}' | cut -f1 -d ",")KHz</option>"
    done
    echo "          </options>"
    echo "          <get>$import_utils gpu_freq_max_freq_cur</get>"
    echo "          <set>$import_utils gpu_freq_max_freq</set>"
    echo "      </picker>"

    #dcs_mode=/sys/kernel/ged/hal/dcs_mode
    #if [[ -f $dcs_mode ]]; then
    #  switch_hidden "DCS Policy" 'When GPU performance requirements decrease, some cores are shut down to reduce power consumption. But with this feature turned on, sometimes the GPU frequency will jump repeatedly between the lowest/highest.' "if [[ \$(grep enable $dcs_mode) != '' ]]; then echo 1; fi" "$import_utils set_dcs_mode"
    #fi

    ged_kpi=/sys/module/sspm_v3/holders/ged/parameters/is_GED_KPI_enabled
    if [[ -f $ged_kpi ]]; then
      switch_hidden "GED KPI" 'Lower performance to reduce battery consumption, but may cause lag during gaming' "cat $ged_kpi" "$import_utils set_ged_kpi"
    fi

    local dvfs=/proc/mali/dvfs_enable
    if [[ -f $dvfs ]]; then
      switch_hidden "Dynamic Frequency and Voltage Scaling (DVFS)" "Enable or disable DVFS" "cat $dvfs | cut -f2 -d ' '" "echo \$state > $dvfs"
    fi
}

common_render() {
  if [[ -f $fpsgo ]]; then
    switch_hidden "FPSGO Enable" 'Lower or boost performance based on real-time frame rate to reduce power consumption or improve frame rate stability. However, if this feature is turned on, there may be continuous small frame drops.' "cat $fpsgo" "$import_utils set_fpsgo"
  fi

  if [[ -f $perfmgr ]]; then
    echo "      <switch title=\"Perfmgr Enable\" desc=\"FEAS is implemented through Perfmgr. Enabling this feature can significantly reduce power consumption in some games.\" reload=\"page\" shell=\"hidden\">"
    echo "          <get>cat $perfmgr</get>"
    echo "          <set>$import_utils set_perfmgr</set>"
    echo "      </switch>"
  fi
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

xml_end
