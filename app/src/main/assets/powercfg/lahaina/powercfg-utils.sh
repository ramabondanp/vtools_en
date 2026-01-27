manufacturer=$(getprop ro.product.manufacturer)

a12=false
if [[ $(getprop ro.product.build.version.sdk) -gt 30 ]]; then
  a12=true
fi

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

core_online=(1 1 1 1 1 1 1 1)
set_core_online() {
  for index in 0 1 2 3 4 5 6 7; do
    core_online[$index]=`cat /sys/devices/system/cpu/cpu$index/online`
    echo 1 > /sys/devices/system/cpu/cpu$index/online
  done
}
restore_core_online() {
  for i in "${!core_online[@]}"; do
     echo ${core_online[i]} > /sys/devices/system/cpu/cpu$i/online
  done
}

reset_basic_governor() {
  stop_scene_scheduler
  set_core_online
  policy=/sys/devices/system/cpu/cpufreq/
  ls $policy | while read cluster; do
    set_value schedutil ${policy}${cluster}/scaling_governor
  done

  echo '0:4294967295 1:4294967295 2:4294967295 3:4294967295 4:4294967295 5:4294967295 6:4294967295 7:4294967295' > /sys/module/msm_performance/parameters/cpu_max_freq 
  echo '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0' > /sys/module/msm_performance/parameters/cpu_min_freq 

}

bw_down() {
  path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  down1="$1"
  down2="$2"
  cat $path/available_frequencies | awk -F ' ' "{print \$(NF-$down1)}" > $path/max_freq

  path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  cat $path/available_frequencies | awk -F ' ' "{print \$(NF-$down2)}" > $path/max_freq
}

bw_min() {
  path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $1}' > $path/min_freq

  path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $1}' > $path/min_freq

  path='/sys/class/devfreq/1d84000.ufshc'
  cat $path/available_frequencies | awk -F ' ' '{print $1}' > $path/min_freq
}

bw_max() {
  path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $NF}' > $path/max_freq

  path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $NF}' > $path/max_freq

  path='/sys/class/devfreq/1d84000.ufshc'
  cat $path/available_frequencies | awk -F ' ' '{print $NF}' > $path/max_freq
}

bw_lock() {
  path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  down1="$1"
  down2="$2"
  bw_1=$(cat $path/available_frequencies | awk -F ' ' "{print \$(NF-$down1)}")
  echo $bw_1 > $path/min_freq
  echo $bw_1 > $path/max_freq
  echo $bw_1 > $path/min_freq

  path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  bw_2=$(cat $path/available_frequencies | awk -F ' ' "{print \$(NF-$down2)}")
  echo $bw_2 > $path/min_freq
  echo $bw_2 > $path/max_freq
  echo $bw_2 > $path/min_freq
}

bw_max_always() {
  path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  b_max=`cat $path/available_frequencies | awk -F ' ' '{print $NF}'`
  echo $b_max > $path/min_freq
  echo $b_max > $path/max_freq
  echo $b_max > $path/min_freq

  path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  b_max=`cat $path/available_frequencies | awk -F ' ' '{print $NF}'`
  echo $b_max > $path/min_freq
  echo $b_max > $path/max_freq
  echo $b_max > $path/min_freq

  path='/sys/class/devfreq/1d84000.ufshc'
  b_max=`cat $path/available_frequencies | awk -F ' ' '{print $NF}'`
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

set_input_boost_freq() {
  c0="$1"
  c1="$2"
  c2="$3"
  ms="$4"
  echo "0:$c0 1:$c0 2:$c0 3:$c0 4:$c1 5:$c1 6:$c1 7:$c2" > /sys/devices/system/cpu/cpu_boost/input_boost_freq
  echo $ms > /sys/devices/system/cpu/cpu_boost/input_boost_ms
  if [[ "$ms" -gt 0 ]]; then
    echo 1 > /sys/devices/system/cpu/cpu_boost/sched_boost_on_input
  else
    echo 0 > /sys/devices/system/cpu/cpu_boost/sched_boost_on_input
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

sched_config() {
  echo "$1" > /proc/sys/kernel/sched_downmigrate
  echo "$2" > /proc/sys/kernel/sched_upmigrate
  echo "$1" > /proc/sys/kernel/sched_downmigrate

  echo "$3" > /proc/sys/kernel/sched_group_downmigrate
  echo "$4" > /proc/sys/kernel/sched_group_upmigrate
  echo "$3" > /proc/sys/kernel/sched_group_downmigrate
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

cpuctl () {
  # echo $xxx > /dev/cpuctl/$1/cpu.uclamp.sched_boost_no_override
  # echo $xxx > /dev/cpuctl/$1/cpu.uclamp.latency_sensitive
  echo $2 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $3 > /dev/cpuctl/$1/cpu.uclamp.max
  echo $2 > /dev/cpuctl/$1/cpu.uclamp.min
}
mk_stune () {
  mkdir -p "/dev/stune/$1"
  echo $2 > "/dev/stune/$1/schedtune.prefer_idle"
  echo $3 > "/dev/stune/$1/schedtune.boost"
}
mk_cpuctl () {
  mkdir -p "/dev/cpuctl/$1"
  echo $2 > /dev/cpuctl/$1/cpu.uclamp.sched_boost_no_override
  echo $3 > /dev/cpuctl/$1/cpu.uclamp.latency_sensitive
  echo $4 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $5 > /dev/cpuctl/$1/cpu.uclamp.max
  echo $4 > /dev/cpuctl/$1/cpu.uclamp.min
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

tcp_low_latency() {
  if [[ "$1" == '1' ]]; then
    echo 1 > /proc/sys/net/ipv4/tcp_low_latency
    echo 0 > /proc/sys/net/ipv4/tcp_slow_start_after_idle
  else
    echo 0 > /proc/sys/net/ipv4/tcp_low_latency
    echo 1 > /proc/sys/net/ipv4/tcp_slow_start_after_idle
  fi
}

move_to_cpuset() {
  pid="$1"
  cpuset="/dev/cpuset/$2/cgroup.procs"
  if [[ "$pid" != "" ]] && [[ -e "$cpuset" ]]; then
    echo $pid > "$cpuset"
  fi
}
stop_scene_scheduler(){
  killall 'scene-scheduler' 2>/dev/null
}
scene_scheduler() {
  SCDIR=${0%/*}
  if [[ "$a12" == true ]]; then
    profile="profile.conservative.json"
  else
    profile="profile.json"
  fi
  killall 'scene-scheduler' 2>/dev/null
  # echo $SCDIR/scene-scheduler -c="$SCDIR/profile.json" -p="$1" -m="$2" > /cache/scene-scheduler.log
  $SCDIR/scene-scheduler -p="$1" -m="$2" -c="$SCDIR/$profile" >/dev/null 2>&1 &
}

adjustment_by_top_app() {
  case "$top_app" in
    # YuanShen
    "com.miHoYo.Yuanshen" | "com.miHoYo.ys.mi" | "com.miHoYo.ys.bilibili" | "com.miHoYo.GenshinImpact")
       realme_gt_on=1
       set_hispeed_freq 0 0 0
       sched_boost 0 0
       stune_top_app 0 0
       if [[ "$action" = "powersave" ]]; then
         bw_down 1 1
         set_hispeed_freq 1612800 1075200 1075200
         sched_config "70 53" "98 68" "300" "400"
       elif [[ "$action" = "balance" ]]; then
         bw_max
         set_hispeed_freq 1612800 1209600 1190400
         sched_config "55 49" "72 65" "300" "400"
       elif [[ "$action" = "performance" ]]; then
         bw_max
         set_hispeed_freq 1612800 1440000 1440000
         sched_config "70 65" "95 75" "200" "400"
       elif [[ "$action" = "fast" ]]; then
         bw_min
         bw_max
         set_hispeed_freq 1612800 1440000 1555200
         sched_config "67 50" "80 70" "300" "400"
       fi
    ;;

    # Project SEKAI
    "com.hermes.mk.asia"|"com.sega.pjsekai")
      realme_gt_on=1
      sched_boost 1 2
      if [[ "$action" == "powersave" ]]; then
        stune_top_app 1 0
        sched_config "50 55" "70 70" "85" "100"
      elif [[ "$action" == "balance" ]]; then
        stune_top_app 1 0
        sched_config "50 52" "65 68" "85" "100"
      elif [[ "$action" == "performance" ]]; then
        stune_top_app 1 0
        sched_config "45 52" "55 65" "85" "100"
      else
        stune_top_app 1 10
        sched_config "45 48" "55 60" "85" "100"
      fi
    ;;

    # LOL | Wang Zhe Rong Yao
    "com.tencent.lolm"|"com.tencent.tmgp.sgame"|"com.garena.game.kgtw")
      set_cpu_pl 0
      # tcp_low_latency 1
      if [[ "$action" = "powersave" ]]; then
        # conservative_mode 58 70 75 90 69 82
        sched_config "63 68" "78 82" "300" "400"
        realme_gt_on=0
        bw_down 3 3
      elif [[ "$action" = "balance" ]]; then
        # conservative_mode 53 68 70 85 69 82
        stune_top_app 0 0
        sched_config "65 67" "76 81" "300" "400"
        realme_gt_on=1
        bw_down 2 2
      elif [[ "$action" = "performance" ]]; then
        # conservative_mode 50 65 69 80 67 80
        sched_config "65 65" "74 80" "200" "400"
        if [[ "$a12" != true ]]; then
          stune_top_app 0 0
        else
          stune_top_app 1 15
        fi
        realme_gt_on=1
      elif [[ "$action" = "fast" ]]; then
        # conservative_mode 40 58 54 70 60 72
        sched_config "65 65" "73 80" "300" "400"
        if [[ "$a12" == true ]]; then
          stune_top_app 0 0
        fi
        realme_gt_on=1
      fi
    ;;

    "com.tencent.tmgp.speedmobile", "com.garena.game.fctw")
      realme_gt_on=1
      cpuset '0' '0' '0-7' '0-7'
      # scene_scheduler "$top_app" "$action"
    ;;

    "com.dw.h5yvzr.yt"|"com.pwrd.hotta.laohu"|"com.hottagames.hotta.bilibili"|"com.hottagames.hotta.mi")
      realme_gt_on=1
      # scene_scheduler "$top_app" "$action"
    ;;

    "com.android.packageinstaller")
      realme_gt_on=2
    ;;
  esac
  scene_scheduler "$top_app" "$action"
}
