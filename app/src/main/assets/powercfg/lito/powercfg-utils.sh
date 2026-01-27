# GPU频率表
gpu_freqs=`cat /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies`
# GPU最大频率
gpu_max_freq='625000000'
# GPU最小频率
gpu_min_freq='275000000'
# GPU最小 power level
gpu_min_pl=3
# GPU最大 power level
gpu_max_pl=0

# MaxFrequency、MinFrequency
for freq in $gpu_freqs; do
  if [[ $freq -gt $gpu_max_freq ]]; then
    gpu_max_freq=$freq
  fi;
  if [[ $freq -lt $gpu_min_freq ]]; then
    gpu_min_freq=$freq
  fi;
done

# Power Levels
if [[ -f /sys/class/kgsl/kgsl-3d0/num_pwrlevels ]];then
  gpu_min_pl=`cat /sys/class/kgsl/kgsl-3d0/num_pwrlevels`
  gpu_min_pl=`expr $gpu_min_pl - 1`
fi;
if [[ "$gpu_min_pl" -lt 0 ]];then
  gpu_min_pl=0
fi;


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

  for cluster in 0 6 7; do
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

  echo $3 > ${policy}6/conservative/down_threshold
  echo $4 > ${policy}6/conservative/up_threshold
  echo $3 > ${policy}6/conservative/down_threshold
  echo $4 > ${policy}6/conservative/up_threshold
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

  # CPU
  governor0=`cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor`
  governor6=`cat /sys/devices/system/cpu/cpufreq/policy6/scaling_governor`
  governor7=`cat /sys/devices/system/cpu/cpufreq/policy7/scaling_governor`

  if [[ ! "$governor0" = "schedutil" ]]; then
    echo 'schedutil' > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
  fi
  if [[ ! "$governor6" = "schedutil" ]]; then
    echo 'schedutil' > /sys/devices/system/cpu/cpufreq/policy6/scaling_governor
  fi
  if [[ ! "$governor7" = "schedutil" ]]; then
    echo 'schedutil' > /sys/devices/system/cpu/cpufreq/policy7/scaling_governor
  fi

  # GPU
  gpu_governor=`cat /sys/class/kgsl/kgsl-3d0/devfreq/governor`
  if [[ ! "$gpu_governor" = "msm-adreno-tz" ]]; then
    echo 'msm-adreno-tz' > /sys/class/kgsl/kgsl-3d0/devfreq/governor
  fi
  # echo $gpu_max_freq > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
  echo $gpu_min_freq > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
  echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/def_pwrlevel
  echo $gpu_max_pl > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
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
    fi
  fi
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

disable_migt() {
  migt=/sys/module/migt/parameters
  if [[ -d $migt ]]; then
    hide_value $migt/migt_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
    hide_value $migt/glk_freq_limit_start '0'
    hide_value $migt/glk_freq_limit_walt '0'
    hide_value $migt/glk_maxfreq '0 0 0'
    hide_value $migt/glk_minfreq '300000 652800 806400'
    hide_value $migt/migt_ceiling_freq '0 0 0'
    hide_value $migt/glk_disable '1'
    hide_value $migt/mi_freq_enable '0'
    hide_value $migt/force_stask_to_big '0'
    hide_value $migt/glk_fbreak_enable '0'
    hide_value $migt/force_reset_runtime '0'

    settings put secure speed_mode_enable 1
  fi

  glk=/proc/sys/glk
  if [[ -d $glk ]]; then
    hide_value $glk/glk_disable '1'
    hide_value $glk/freq_break_enable '0'
    hide_value $glk/game_minfreq_limit '0 0 0'
    hide_value $glk/game_maxfreq_limit '0 0 0'
    hide_value $glk/game_lowspeed_load '30 30 30'
    hide_value $glk/game_hispeed_load '80 80 80'
  fi

  migt=/proc/sys/migt
  if [[ -d $migt ]]; then
    hide_value $migt/force_stask_tob '0'
    hide_value $migt/enable_pkg_monitor '0'
    hide_value $migt/boost_pid '0'
  fi
}

clear_app_data() {
  if [[ "$1" != "" ]];then
    # pm clear $1
    rm -f /data/data/$1/databases/*
    rm -rf /data/data/$1/files/*
    rm -rf /data/data/$1/shared_prefs/*
    killall $1 2>/dev/null
    am force-stop $1
  fi
}

uninstall_mi_opt() {
  # if [[ $(pm list packages --user 0 com.miui.daemon) != "" ]] || [[ $(pm list packages --user 0 com.xiaomi.joyose) != "" ]]; then
  #   clear_app_data com.miui.powerkeeper
  #   clear_app_data com.xiaomi.powerchecker
  # fi
  # pm uninstall --user 0 -k com.miui.daemon >/dev/null 2>&1
  # pm uninstall --user 0 -k com.xiaomi.joyose >/dev/null 2>&1
  pm uninstall --user 0 com.miui.daemon >/dev/null 2>&1
  pm uninstall --user 0 com.xiaomi.joyose >/dev/null 2>&1
}

reinstall_mi_opt() {
  uninstall_mi_opt
  pm install-existing --user 0 com.miui.daemon >/dev/null 2>&1
  pm install-existing --user 0 com.xiaomi.joyose >/dev/null 2>&1
}

set_input_boost_freq() {
  local c0="$1"
  local c1="$2"
  local c2="$3"
  local ms="$4"
  echo "0:$c0 1:$c0 2:$c0 3:$c0 4:$c0 5:$c0 6:$c1 7:$c2" >/sys/devices/system/cpu/cpu_boost/input_boost_freq
  echo $ms >/sys/devices/system/cpu/cpu_boost/input_boost_ms
  if [[ "$ms" -gt 0 ]]; then
    echo 1 >/sys/devices/system/cpu/cpu_boost/sched_boost_on_input
  else
    echo 0 >/sys/devices/system/cpu/cpu_boost/sched_boost_on_input
  fi
}

set_cpu_freq() {
  echo "0:4294967295 1:4294967295 2:4294967295 3:4294967295 4:4294967295 5:4294967295 6:4294967295 7:4294967295" > /sys/module/msm_performance/parameters/cpu_max_freq
  echo "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0" > /sys/module/msm_performance/parameters/cpu_min_freq

  set_value $1 /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
  set_value $2 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
  set_value $1 /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq

  set_value $3 /sys/devices/system/cpu/cpufreq/policy6/scaling_min_freq
  set_value $3 /sys/devices/system/cpu/cpufreq/policy6/scaling_min_freq
  set_value $4 /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq

  set_value $5 /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
  set_value $6 /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq
  set_value $5 /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
}

ufshc_perf(){
  if [[ "$1" == "on" ]];then
    echo 0 > /sys/devices/platform/soc/1d84000.ufshc/clkscale_enable
    echo 0 > /sys/devices/platform/soc/1d84000.ufshc/clkgate_enable
    echo 0 > /sys/devices/platform/soc/1d84000.ufshc/hibern8_on_idle_enable
    echo 300000000 > /sys/class/devfreq/1d84000.ufshc/min_freq
  else
    echo 1 > /sys/devices/platform/soc/1d84000.ufshc/clkscale_enable
    echo 1 > /sys/devices/platform/soc/1d84000.ufshc/clkgate_enable
    echo 1 > /sys/devices/platform/soc/1d84000.ufshc/hibern8_on_idle_enable
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
  echo $3 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/down_rate_limit_us
  echo $4 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/up_rate_limit_us
  echo $5 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/down_rate_limit_us
  echo $6 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/up_rate_limit_us
}

set_cpu_pl() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/pl
  echo $1 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/pl
}

set_gpu_min_freq() {
  index=$1

  # GPU频率表
  gpu_freqs=`cat /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies`

  target_freq=$(echo $gpu_freqs | awk "{print \$${index}}")
  if [[ "$target_freq" != "" ]]; then
    echo $target_freq > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
  fi

  # gpu_max_freq=`cat /sys/class/kgsl/kgsl-3d0/devfreq/max_freq`
  # gpu_min_freq=`cat /sys/class/kgsl/kgsl-3d0/devfreq/min_freq`
  # echo "Frequency: ${gpu_min_freq} ~ ${gpu_max_freq}"
}
cpu6_core_ctl(){
  cpu6_core_ctl_dir=/sys/devices/system/cpu/cpu6/core_ctl
  if [[ "$1" == "on" ]];then
    echo 50 > $cpu6_core_ctl_dir/offline_delay_ms
    echo 1 > $cpu6_core_ctl_dir/not_preferred
    echo 1 > $cpu6_core_ctl_dir/enable
    echo 1 > $cpu6_core_ctl_dir/max_cpus
    echo 0 > $cpu6_core_ctl_dir/min_cpus
    # echo 4294967295 > $cpu6_core_ctl_dir/nr_prev_assist_thresh
    echo 1 > $cpu6_core_ctl_dir/task_thres
    echo 30 > $cpu6_core_ctl_dir/busy_down_thres
    echo 50 > $cpu6_core_ctl_dir/busy_up_thres
  else
    echo 0 > $cpu6_core_ctl_dir/enable
  fi
}
cpu7_core_ctl(){
  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  if [[ "$1" == "on" ]];then
    echo 50 > $cpu7_core_ctl_dir/offline_delay_ms
    echo 1 > $cpu7_core_ctl_dir/not_preferred
    echo 1 > $cpu7_core_ctl_dir/enable
    echo 1 > $cpu7_core_ctl_dir/max_cpus
    echo 0 > $cpu7_core_ctl_dir/min_cpus
    # echo 4294967295 > $cpu7_core_ctl_dir/nr_prev_assist_thresh
    echo 1 > $cpu7_core_ctl_dir/task_thres
    echo 30 > $cpu7_core_ctl_dir/busy_down_thres
    echo 50 > $cpu7_core_ctl_dir/busy_up_thres
  else
    echo 0 > $cpu7_core_ctl_dir/enable
  fi
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
  echo $2 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/hispeed_freq
  echo $3 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/hispeed_freq
}

set_hispeed_load() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/hispeed_load
  echo $2 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/hispeed_load
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

# [min/max/def] pl(number)
set_gpu_pl(){
  echo $2 > /sys/class/kgsl/kgsl-3d0/${1}_pwrlevel
}

set_gpu_max_freq () {
  echo $1 > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
  local pl=-1

  for freq in $gpu_freqs; do
    local pl=$((pl + 1))
    if [[ $freq -lt $1 ]] || [[ $freq == $1 ]]; then
      break
    fi;
  done
  if [[ $pl -gt -1 ]]; then
    echo $pl > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
  fi
}

# GPU MinPowerLevel To Up
gpu_pl_up() {
  local offset="$1"
  if [[ "$offset" != "" ]] && [[ ! "$offset" -gt "$gpu_min_pl" ]]; then
    echo `expr $gpu_min_pl - $offset` > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  elif [[ "$offset" -gt "$gpu_min_pl" ]]; then
    echo 0 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  else
    echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  fi
}

# GPU MinPowerLevel To Down
gpu_pl_down() {
  local offset="$1"
  if [[ "$offset" != "" ]] && [[ ! "$offset" -gt "$gpu_min_pl" ]]; then
    echo $offset > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
  elif [[ "$offset" -gt "$gpu_min_pl" ]]; then
    echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
  else
    echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
  fi
}

# set_task_affinity $pid $use_cores[cpu7~cpu0]
set_task_affinity() {
  pid=$1
  mask=`echo "obase=16;$((num=2#$2))" | bc`
  for tid in $(ls "/proc/$pid/task/"); do
    taskset -p "$mask" "$tid" 1>/dev/null
  done
  taskset -p "$mask" "$pid" 1>/dev/null
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
      ctl_off cpu6
      set_cpu_freq 1708800 2500000 1209600 2750000
      set_hispeed_freq 0 0
      devfreq_performance
      if [[ "$action" = "powersave" ]]; then
        sched_boost 0 0
        stune_top_app 0 0
        sched_config "50 80" "67 95" "300" "400"
        gpu_pl_up 2
        sched_limit 5000 0 5000 0 5000 0
      elif [[ "$action" = "balance" ]]; then
        sched_boost 1 0
        stune_top_app 0 20
        sched_config "50 68" "67 80" "300" "400"
        gpu_pl_up 2
        sched_limit 5000 0 5000 0 5000 0
      elif [[ "$action" = "performance" ]]; then
        sched_boost 1 0
        stune_top_app 0 100
        gpu_pl_up 3
        sched_limit 5000 0 5000 0 5000 0
      elif [[ "$action" = "fast" ]]; then
        sched_boost 1 0
        stune_top_app 0 100
        gpu_pl_up 3
        sched_limit 5000 0 10000 0 10000 0
      elif [[ "$action" = "pedestal" ]]; then
        stune_top_app 0 100
      fi
      cpuset '0' '0' '0-7' '0-7'
      # scene_scheduler "$top_app" "$action"
    ;;

    # Wang Zhe Rong Yao
    "com.tencent.tmgp.sgame")
      ctl_off cpu0
      ctl_off cpu6
      set_hispeed_freq 0 0
      cpuset '0' '0' '0-7' '0-7'
      if [[ "$action" = "powersave" ]]; then
        sched_config "52 55" "69 67" "300" "400"
        sched_boost 1 0
        stune_top_app 0 10
        set_cpu_freq 1804800 2500000 1094400 2208000 1094400 2400000
      elif [[ "$action" = "balance" ]]; then
        sched_config "50 55" "65 65" "300" "400"
        sched_boost 1 0
        stune_top_app 0 30
        set_cpu_freq 1804800 2500000 1478400 2208000 1401600 2400000
      elif [[ "$action" = "performance" ]]; then
        sched_config "45 55" "55 65" "300" "400"
        sched_boost 1 0
        stune_top_app 0 100
        set_cpu_freq 1804800 2500000 1478400 2208000 1401600 2600000
      elif [[ "$action" = "fast" ]]; then
        sched_config "40 55" "50 63" "300" "400"
        sched_boost 1 2
        stune_top_app 0 100
        set_cpu_freq 1804800 2500000 1900800 2600000 1996800 2900000
      elif [[ "$action" = "pedestal" ]]; then
        stune_top_app 0 100
      fi
      # 这个策略很好，但是会被系统(游戏)覆盖，甚至互斥产生负面作用
      # watch_app sgame_opt_run &
      # scene_scheduler "$top_app" "$action"
    ;;

    # XianYu, TaoBao, Browser, TieBa Fast, TieBa、JingDong、TianMao、Mei Tuan、PuPuChaoShi
    "com.taobao.idlefish" | "com.taobao.taobao" | "com.android.browser" | "com.baidu.tieba_mini" | "com.baidu.tieba" | "com.jingdong.app.mall" | "com.tmall.wireless" | "com.sankuai.meituan" | "com.pupumall.customer")
      if [[ "$action" == "powersave" ]]; then
        sched_config "45 62" "55 75" "85" "100"
      else
        sched_boost 1 2
        stune_top_app 1 1
        sched_config "45 62" "55 75" "85" "100"
      fi
    ;;

    "com.speedsoftware.rootexplorer" | "com.estrongs.android.pop")
      if [[ "$action" == "powersave" ]]; then
        sched_config "45 62" "55 75" "85" "100"
      elif [[ "$action" == "balance" ]]; then
        sched_config "40 50" "50 65" "85" "100"
      elif [[ "$action" == "performance" ]]; then
        sched_boost 1 0
        stune_top_app 1 1
        sched_config "40 50" "50 65" "85" "100"
      else
        sched_boost 1 2
        stune_top_app 1 1
        sched_config "40 50" "50 65" "85" "100"
      fi
    ;;


    "com.miui.home")
      if [[ "$action" == "powersave" ]]; then
        sched_config "45 62" "55 75" "85" "100"
      elif [[ "$action" == "balance" ]]; then
        sched_config "40 50" "50 65" "85" "100"
      elif [[ "$action" == "performance" ]]; then
        sched_config "35 52" "45 65" "65" "80"
      else
        sched_boost 1 2
        stune_top_app 1 1
        sched_config "45 62" "55 75" "85" "100"
      fi
    ;;

    # NeteaseCloudMusic, KuGou, KuGou Lite
    "com.netease.cloudmusic" | "com.kugou.android" | "com.kugou.android.lite")
      echo 0-6 > /dev/cpuset/foreground/cpus
    ;;

    # DouYin, BiliBili
    "com.ss.android.ugc.aweme"|"com.ss.android.ugc.aweme.lite"|"tv.danmaku.bili"|"com.bilibili.app.in")
      ctl_on cpu0
      ctl_on cpu7
      echo 0-3 > /dev/cpuset/foreground/cpus

      if [[ "$action" = "powersave" ]]; then
        sched_boost 0 0
        stune_top_app 0 0
        echo 0-5 > /dev/cpuset/top-app/cpus
      elif [[ "$action" = "balance" ]]; then
        sched_boost 0 0
        stune_top_app 0 0
        echo 0-7 > /dev/cpuset/top-app/cpus
      elif [[ "$action" = "performance" ]]; then
        sched_boost 1 0
        stune_top_app 1 0
        echo 0-7 > /dev/cpuset/top-app/cpus
      elif [[ "$action" = "fast" ]]; then
        sched_boost 1 2
        stune_top_app 1 10
        echo 0-7 > /dev/cpuset/top-app/cpus
      fi

      sched_config "85 85" "100 100" "240" "400"
    ;;

    "default")
      echo '未适配的应用'
    ;;
  esac
  scene_scheduler "$top_app" "$action"
}
