conservative_mode() {
  local policy=/sys/devices/system/cpu/cpufreq/policy
  # local down="$1"
  # local up="$2"
  #
  # if [[ "$down" == "" ]]; then
  #   local down="20"
  # fi
  # if [[ "$up" == "" ]]; then
  #   local up="60"
  # fi

  for cluster in 0 4; do
    echo $cluster
    echo 'conservative' > ${policy}${cluster}/scaling_governor
    # echo $down > ${policy}${cluster}/conservative/down_threshold
    # echo $up > ${policy}${cluster}/conservative/up_threshold
    echo 0 > ${policy}${cluster}/conservative/ignore_nice_load
    echo 1000 > ${policy}${cluster}/conservative/sampling_rate # 1000us = 1ms
    echo 2 > ${policy}${cluster}/conservative/freq_step
  done

  echo $1 > ${policy}0/conservative/down_threshold
  echo $2 > ${policy}0/conservative/up_threshold
  echo $1 > ${policy}0/conservative/down_threshold
  echo $2 > ${policy}0/conservative/up_threshold

  echo $3 > ${policy}4/conservative/down_threshold
  echo $4 > ${policy}4/conservative/up_threshold
  echo $3 > ${policy}4/conservative/down_threshold
  echo $4 > ${policy}4/conservative/up_threshold
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
}

devfreq_performance () {
  bw_max_always
}

devfreq_restore () {
  bw_min
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

set_input_boost_freq() {
  local c0="$1"
  local c1="$2"
  local ms="$3"
  echo "0:$c0 1:$c0 2:$c0 3:$c0 4:$c0 5:$c0 6:$c1 7:$c1" > /sys/module/cpu_boost/parameters/input_boost_freq
  echo $ms > /sys/module/cpu_boost/parameters/input_boost_ms
  if [[ "$ms" -gt 0 ]]; then
    echo 1 > /sys/module/cpu_boost/parameters/sched_boost_on_input
  else
    echo 0 > /sys/module/cpu_boost/parameters/sched_boost_on_input
  fi
}

set_cpu_freq() {
  echo "0:4294967295 1:4294967295 2:4294967295 3:4294967295 4:4294967295 5:4294967295 6:4294967295 7:4294967295" > /sys/module/msm_performance/parameters/cpu_max_freq
  echo "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0" > /sys/module/msm_performance/parameters/cpu_min_freq
  set_value $1 /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
  set_value $2 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
  set_value $1 /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq

  set_value $3 /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
  set_value $4 /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
  set_value $3 /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
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
}

set_cpu_pl() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/pl
  echo $1 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/pl
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

set_ctl() {
  echo $2 > /sys/devices/system/cpu/$1/core_ctl/busy_up_thres
  echo $3 > /sys/devices/system/cpu/$1/core_ctl/busy_down_thres
  echo $4 > /sys/devices/system/cpu/$1/core_ctl/offline_delay_ms
}

set_hispeed_freq() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/hispeed_freq
  echo $2 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/hispeed_freq
}

set_hispeed_load() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/hispeed_load
  echo $2 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/hispeed_load
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
}

# set_task_affinity $pid $use_cores[cpu4~cpu0]
set_task_affinity() {
  pid=$1
  mask=`echo "obase=16;$((num=2#$2))" | bc`
  for tid in $(ls "/proc/$pid/task/"); do
    taskset -p "$mask" "$tid" 1>/dev/null
  done
  taskset -p "$mask" "$pid" 1>/dev/null
}

# YuanShen
yuan_shen_opt_run() {
  if [[ $(getprop vtools.powercfg_app | grep miHoYo) == "" ]]; then
    return
  fi

  # top -H -p $(pgrep -ef Yuanshen)
  # pid=$(pgrep -ef Yuanshen)
  pid=$(pgrep -ef miHoYo)
  # mask=`echo "obase=16;$((num=2#11110000))" | bc` # F0 (cpu 7-4)
  # mask=`echo "obase=16;$((num=2#10000000))" | bc` # 80 (cpu 7)
  # mask=`echo "obase=16;$((num=2#01110000))" | bc` # 70 (cpu 6-4)
  # mask=`echo "obase=16;$((num=2#01111111))" | bc` # 7F (cpu 6-0)

  if [[ "$pid" != "" ]]; then
    for tid in $(ls "/proc/$pid/task/"); do
      if [[ -f "/proc/$pid/task/$tid/comm" ]]; then
        comm=$(cat /proc/$pid/task/$tid/comm)

        case "$comm" in
         "UnityMain"|"UnityGfxDevice"*|"UnityMultiRende"*)
           # set cpu6-7
           taskset -p "C0" "$tid" > /dev/null 2>&1
         ;;
         *)
           # set cpu0-6
           taskset -p "3F" "$tid" > /dev/null 2>&1
         ;;
        esac
      fi
    done
  fi
}

# WangZheRongYao
sgame_opt_run() {
  local game="tmgp.sgame"
  if [[ $(getprop vtools.powercfg_app | grep $game) == "" ]]; then
    return
  fi

  # top -H -p $(pgrep -ef tmgp.sgame)
  # pid=$(pgrep -ef $game)
  pid=$(pgrep -ef $game)
  # mask=`echo "obase=16;$((num=2#01111111))" | bc` # 7F (cpu 6-0)

  if [[ "$pid" != "" ]]; then
    heavy_tid=$(top -H -b -q -n 1 -m 5 -p $pid | grep 'Thread-' | egrep  -o '[0-9]{1,}' | head -n 1)
    for tid in $(ls "/proc/$pid/task/"); do
      if [[ "$heavy_tid" == "$tid" ]]; then
        taskset -p "C0" "$tid" > /dev/null 2>&1
      elif [[ -f "/proc/$pid/task/$tid/comm" ]]; then
        comm=$(cat /proc/$pid/task/$tid/comm)
        case "$comm" in
         "UnityMain"|"UnityGfx"|"CoreThread"*|"NativeThread")
           # set cpu6-7
           taskset -p "C0" "$tid" > /dev/null 2>&1
         ;;
         *)
           # set cpu0-5
           taskset -p "3F" "$tid" > /dev/null 2>&1
         ;;
        esac
      fi
    done
  fi
}

# watch_app [on_tick] [on_change]
watch_app() {
  local interval=120
  local on_tick="$1"
  local on_change="$2"
  local app=$(getprop vtools.powercfg_app)

  if [[ "$on_tick" == "" ]]; then
    return
  fi

  if [[ "$app" == "" ]]; then
    return
  fi

  procs=$(pgrep -f com.omarea.*powercfg.sh)
  last_proc=$(echo "$procs" | tail -n 1)
  if [[ "$last_proc" != "" ]]; then
    echo "$procs" | grep -v "$last_proc" | while read pid; do
      kill -9 $pid 2> /dev/null
    done
  fi

  ticks=0
  while true
  do
    if [[ $ticks -gt 3 ]]; then
      sleep $interval
    elif [[ $ticks -gt 0 ]]; then
      sleep 30
    else
      sleep 10
    fi
    ticks=$((ticks + 1))

    current=$(getprop vtools.powercfg_app)
    if [[ "$current" == "$app" ]]; then
      $on_tick $current
    else
      if [[ "$on_change" ]]; then
        $on_change $current
      fi
      return
    fi
  done
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
    # YuanShen
    "com.miHoYo.Yuanshen" | "com.miHoYo.ys.mi" | "com.miHoYo.ys.bilibili")
        ctl_off cpu0
        ctl_off cpu4
        set_cpu_freq 1708800 2500000 1209600 2750000
        set_hispeed_freq 0 0
        devfreq_performance
        if [[ "$action" = "powersave" ]]; then
          sched_boost 0 0
          stune_top_app 0 0
          sched_config "50 80" "67 95" "300" "400"
          sched_limit 5000 0 5000 0
        elif [[ "$action" = "balance" ]]; then
          sched_boost 1 0
          stune_top_app 0 20
          sched_config "50 68" "67 80" "300" "400"
          sched_limit 5000 0 5000 0
        elif [[ "$action" = "performance" ]]; then
          sched_boost 1 0
          stune_top_app 0 100
          sched_limit 5000 0 5000 0
        elif [[ "$action" = "fast" ]]; then
          sched_boost 1 0
          stune_top_app 0 100
          sched_limit 5000 0 10000 0
        fi
        cpuset '0' '0' '0-7' '0-7'
        # scene_scheduler "$top_app" "$action"
    ;;

    # LOL | Wang Zhe Rong Yao
    "com.tencent.lolm"|"com.tencent.tmgp.sgame"|"com.garena.game.kgtw")
        ctl_off cpu0
        ctl_off cpu4
        set_cpu_freq 1708800 2500000 1209600 2750000
        set_hispeed_freq 0 0
        cpuset '0' '0' '0-7' '0-7'
        if [[ "$action" = "powersave" ]]; then
          sched_config "52 55" "69 67" "300" "400"
          sched_boost 1 0
          stune_top_app 0 10
        elif [[ "$action" = "balance" ]]; then
          sched_config "50 55" "65 65" "300" "400"
          sched_boost 1 0
          stune_top_app 0 30
        elif [[ "$action" = "performance" ]]; then
          sched_config "45 55" "55 65" "300" "400"
          sched_boost 1 0
          stune_top_app 0 100
        elif [[ "$action" = "fast" ]]; then
          sched_config "40 55" "50 63" "300" "400"
          sched_boost 1 2
          stune_top_app 1 100
        fi
        # 这个策略很好，但是会被系统(游戏)覆盖，甚至互斥产生负面作用
        # watch_app sgame_opt_run &
        # scene_scheduler "$top_app" "$action"
    ;;

    # DouYin, BiliBili
    "com.ss.android.ugc.aweme"|"com.ss.android.ugc.aweme.lite"|"tv.danmaku.bili")
      ctl_on cpu0
      ctl_on cpu4

      if [[ "$action" = "powersave" ]]; then
        set_cpu_freq 1132800 1612800 5000 1612800
        sched_boost 0 0
        stune_top_app 0 0
      elif [[ "$action" = "balance" ]]; then
        set_cpu_freq 1228800 1689600 5000 1766400
        sched_boost 0 0
        stune_top_app 0 0
      elif [[ "$action" = "performance" ]]; then
        set_cpu_freq 1516800 1766400 5000 1996800
        sched_boost 1 0
        stune_top_app 1 0
      elif [[ "$action" = "fast" ]]; then
        set_cpu_freq 1516800 1766400 5000 2323200
        sched_boost 1 2
        stune_top_app 1 10
      fi

      sched_config "85 85" "100 100" "240" "400"
    ;;

    "default")
      echo '未适配的应用'
    ;;
  esac
  scene_scheduler "$top_app" "$action"
}
