realme_gt() {
  gt_switch=$(settings get system scene_gt_switch)
  if [[ "$gt_switch" != "1" ]]; then
    return
  fi
  gt=$(settings get system gt_mode_state_setting)
  if [[ "$gt" == "1" || "$gt" == "0" ]] && [[ "$gt" != "$1" ]]; then
    if [[ "$1" == "1" ]]; then
      # GT ON
      action='open'
    elif [[ "$1" == "0" ]]; then
      # GT OFF
      action='close'
    else
      return
    fi
    gt_receiver='com.coloros.oppoguardelf/com.coloros.performance.GTModeBroadcastReceiver'
    # am broadcast -a gt_mode_broadcast_intent_${action}_action -n $gt_receiver -f 0x01000000
    if [[ -n $(pm query-receivers --brief -n $gt_receiver | grep $gt_receiver) ]]; then
      am broadcast -a gt_mode_broadcast_intent_${action}_action -n $gt_receiver -f 0x01000000
    else
      am broadcast -a gt_mode_broadcast_intent_${action}_action -f 0x01000000
    fi
  fi
}

reset_basic_governor() {
  stop_scene_scheduler
}

bw_min() {
  local path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $1}' > $path/min_freq

  local path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $1}' > $path/min_freq
}

bw_max() {
  local path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $NF}' > $path/max_freq

  local path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $NF}' > $path/max_freq
}

bw_max_always() {
  local path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  local b_max=`cat $path/available_frequencies | awk -F ' ' '{print $NF}'`
  echo $b_max > $path/min_freq
  echo $b_max > $path/max_freq
  echo $b_max > $path/min_freq

  local path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  local b_max=`cat $path/available_frequencies | awk -F ' ' '{print $NF}'`
  echo $b_max > $path/min_freq
  echo $b_max > $path/max_freq
  echo $b_max > $path/min_freq
}

set_value() {
  value=$1
  path=$2
  if [[ -f $path ]]; then
    current_value="$(cat $path)"
    if [[ ! "$current_value" = "$value" ]]; then
      chmod 0664 "$path"
      echo "$value" > "$path"
    fi;
  fi;
}

lock_value() {
  if [[ -f $2 ]];then
    chmod 644 $2
    echo $1 > $2
    chmod 444 $2
  fi
}

# hide_value /sys/module/task_turbo/parameters/feats [write_value]
hide_value() {
  if [[ -e "$1" ]]; then
    umount "$1" 2>/dev/null
    c_path="/cache${1}"
    if [[ ! -f "$c_path" ]]; then
      mkdir -p "$c_path"
      rm -r "$c_path"
    fi
    chattr -i "$c_path"
    cp -f "$1" "$c_path"
    if [[ "$2" != "" ]]; then
      lock_value "$2" "$1"
    fi
    mount "$c_path" "$1"
  else
    echo "$1" Not Found!
  fi
}

set_cpu_freq() {
  set_value $1 /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
  set_value $2 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
  set_value $1 /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq

  set_value $3 /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
  set_value $4 /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
  set_value $3 /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq

  set_value $5 /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
  set_value $6 /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq
  set_value $5 /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
}

ufshc_perf(){
  if [[ "$1" == "on" ]];then
    echo 0 > /sys/devices/platform/soc/1d84000.ufshc/clkscale_enable
    echo 0 > /sys/devices/platform/soc/1d84000.ufshc/clkgate_enable
    # echo 0 > /sys/devices/platform/soc/1d84000.ufshc/hibern8_on_idle_enable
    echo 300000000 > /sys/class/devfreq/1d84000.ufshc/min_freq
  else
    echo 1 > /sys/devices/platform/soc/1d84000.ufshc/clkscale_enable
    echo 1 > /sys/devices/platform/soc/1d84000.ufshc/clkgate_enable
    # echo 1 > /sys/devices/platform/soc/1d84000.ufshc/hibern8_on_idle_enable
    echo 37500000 > /sys/class/devfreq/1d84000.ufshc/min_freq
  fi
}

sched_config() {
  echo "$1" > /proc/sys/kernel/sched_downmigrate
  echo "$2" > /proc/sys/kernel/sched_upmigrate
  echo "$1" > /proc/sys/kernel/sched_downmigrate
  echo "$2" > /proc/sys/kernel/sched_upmigrate

  echo "$3" > /proc/sys/kernel/sched_group_downmigrate
  echo "$4" > /proc/sys/kernel/sched_group_upmigrate
  echo "$3" > /proc/sys/kernel/sched_group_downmigrate
  echo "$4" > /proc/sys/kernel/sched_group_upmigrate
}

sched_limit() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
  echo $2 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
  echo $3 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/down_rate_limit_us
  echo $4 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/up_rate_limit_us
  echo $5 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/down_rate_limit_us
  echo $6 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/up_rate_limit_us
}

set_cpu_pl() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/pl
  echo $1 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/pl
  echo $1 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/pl
}

ctl_on() {
  echo 1 > /sys/devices/system/cpu/$1/core_ctl/enable
  if [[ "$2" != "" ]]; then
    echo $2 > /sys/devices/system/cpu/$1/core_ctl/min_cpus
  else
    echo 0 > /sys/devices/system/cpu/$1/core_ctl/min_cpus
  fi
}

ctl_off() {
  echo 0 > /sys/devices/system/cpu/$1/core_ctl/enable
}

set_hispeed_freq() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/hispeed_freq
  echo $2 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/hispeed_freq
  echo $3 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/hispeed_freq
}

set_hispeed_load() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/hispeed_load
  echo $2 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/hispeed_load
  echo $3 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/hispeed_load
}

sched_boost() {
  echo $1 > /proc/sys/kernel/sched_boost_top_app
  echo $2 > /proc/sys/kernel/sched_boost
}

stune_top_app() {
  echo $1 > /dev/stune/top-app/schedtune.prefer_idle
  echo $2 > /dev/stune/top-app/schedtune.boost
}

cpuset() {
  echo $1 > /dev/cpuset/background/cpus
  echo $2 > /dev/cpuset/system-background/cpus
  echo $3 > /dev/cpuset/foreground/cpus
  echo $4 > /dev/cpuset/top-app/cpus
  # Mi
  set_value 0-7 /dev/cpuset/game/cpus
  set_value 0-7 /dev/cpuset/gamelite/cpus
}

stop_scene_scheduler(){
  killall 'scene-scheduler' 2>/dev/null
}
scene_scheduler() {
  SCDIR=${0%/*}
  killall 'scene-scheduler' 2>/dev/null
  # echo $SCDIR/scene-scheduler -c="$SCDIR/profile.json" -p="$1" -m="$2" > /cache/scene-scheduler.log
  $SCDIR/scene-scheduler -p="$1" -m="$2" -c="$SCDIR/profile.json" >/dev/null 2>&1 &
}

adjustment_by_top_app() {
  case "$top_app" in
    # GenshinImpact
    "com.miHoYo.Yuanshen" | "com.miHoYo.ys.mi" | "com.miHoYo.ys.bilibili" | "com.miHoYo.GenshinImpact")
      # ctl_off cpu4
      # ctl_off cpu7
      set_hispeed_freq 0 0 0
      realme_gt_on=1
      cpuset '0' '0-1' '0-5' '0-7'
      if [[ "$action" = "powersave" ]]; then
        sched_boost 0 0
        stune_top_app 0 0
        sched_config "70 53" "98 68" "300" "400"
        sched_limit 10000 0 0 5000 0 1000
      elif [[ "$action" = "balance" ]]; then
        sched_boost 0 0
        stune_top_app 0 0
        sched_config "60 57" "87 72" "300" "400"
        set_cpu_freq 1075200 1804800 1056000 2054400 1075200 2841600
        sched_limit 10000 0 0 5000 0 1000
      elif [[ "$action" = "performance" ]]; then
        sched_boost 0 0
        stune_top_app 0 10
        set_cpu_freq 1075200 1804800 1056000 2419200 1075200 3200000
        sched_limit 5000 0 5000 0 5000 0
      elif [[ "$action" = "fast" ]]; then
        sched_boost 0 0
        stune_top_app 0 50
        sched_limit 5000 0 10000 0 5000 0
        # sched_config "40 60" "50 75" "120" "150"
      fi
      # scene_scheduler "$top_app" "$action"
    ;;

    # Benchmark
    "com.primatelabs.geekbench" | "com.primatelabs.geekbench5")
      sched_limit 50000 0 50000 0 50000 0
      sched_config "50 52" "65 68" "70" "90"
      sched_boost 0 0
      stune_top_app 0 100
    ;;

    # pubg
    "com.tencent.tmgp.pubgmhd" | "com.tencent.ig")
      cpuset '0-1' '0-3' '0-7' '0-7'
      set_hispeed_freq 0 0 0
    ;;

    # Project SEKAI
    "com.hermes.mk.asia"|"com.sega.pjsekai")
      realme_gt_on=1
      if [[ "$action" == "powersave" ]]; then
        sched_boost 1 2
        stune_top_app 1 0
        sched_config "50 55" "70 70" "85" "100"
      elif [[ "$action" == "balance" ]]; then
        sched_boost 1 2
        stune_top_app 1 0
        sched_config "50 52" "65 68" "85" "100"
      elif [[ "$action" == "performance" ]]; then
        sched_boost 1 2
        stune_top_app 1 0
        sched_config "45 52" "55 65" "85" "100"
      else
        sched_boost 1 2
        stune_top_app 1 10
        sched_config "45 48" "55 60" "85" "100"
      fi
    ;;

    # Wang Zhe Rong Yao
    "com.tencent.tmgp.sgame")
      # ctl_off cpu4
      # ctl_on cpu7
      if [[ "$action" = "powersave" ]]; then
        sched_config "52 55" "69 70" "300" "400"
        sched_boost 1 0
        stune_top_app 0 0
        cpuset '0-1' '0-1' '0-3' '0-7'
        set_hispeed_freq 0 1382400 1305600
        realme_gt_on=0
      elif [[ "$action" = "balance" ]]; then
        sched_config "50 55" "65 69" "300" "400"
        sched_boost 1 0
        stune_top_app 0 1
        cpuset '0-1' '0-1' '0-6' '0-7'
        set_hispeed_freq 0 1670400 1305600
        realme_gt_on=1
      elif [[ "$action" = "performance" ]]; then
        sched_config "45 55" "57 69" "300" "400"
        sched_boost 1 0
        stune_top_app 0 10
        cpuset '0-1' '0-1' '0-6' '0-7'
        realme_gt_on=1
      elif [[ "$action" = "fast" ]]; then
        sched_config "40 55" "55 69" "300" "400"
        cpuset '0-1' '0-1' '0-6' '0-7'
        sched_boost 1 0
        stune_top_app 1 20
        realme_gt_on=1
        sched_limit 4000 0 4000 0 8000 0
      fi
    ;;

    # NeteaseCloudMusic, KuGou, KuGou Lite
    "com.netease.cloudmusic" | "com.kugou.android" | "com.kugou.android.lite")
      echo 0-6 > /dev/cpuset/foreground/cpus
    ;;

    "com.pwrd.hotta.laohu"|"com.hottagames.hotta.bilibili"|"com.hottagames.hotta.mi")
      realme_gt_on=1
      # scene_scheduler "$top_app" "$action"
    ;;

    "com.tencent.tmgp.speedmobile", "com.garena.game.fctw")
      realme_gt_on=1
      # scene_scheduler "$top_app" "$action"
    ;;

    "com.android.packageinstaller")
      realme_gt_on=2
    ;;

    "default")
      echo '未适配的应用'
    ;;
  esac
  scene_scheduler "$top_app" "$action"
}
