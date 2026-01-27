governor=interactive
# if [[ -n $(grep schedutil /sys/devices/system/cpu/cpufreq/policy0/scaling_available_governors) ]]; then
#   governor=schedutil
# else
#   governor=interactive
# fi

# GPU频率表
gpu_freqs=`cat /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies`
# GPU最大频率
gpu_max_freq='710000000'
# GPU最小频率
gpu_min_freq='180000000'
# GPU最小 power level
gpu_min_pl=7
# GPU最大 power level
gpu_max_pl=0

# MaxFrequency、MinFrequency
for freq in $gpu_freqs; do
  if [[ $freq -gt $gpu_max_freq ]]; then
    gpu_max_freq=$freq
  fi
  if [[ $freq -lt $gpu_min_freq ]]; then
    gpu_min_freq=$freq
  fi
done

# Power Levels
if [[ -f /sys/class/kgsl/kgsl-3d0/num_pwrlevels ]];then
  gpu_min_pl=`cat /sys/class/kgsl/kgsl-3d0/num_pwrlevels`
  gpu_min_pl=`expr $gpu_min_pl - 1`
fi
if [[ "$gpu_min_pl" -lt 0 ]];then
  gpu_min_pl=0
fi

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
  governor4=`cat /sys/devices/system/cpu/cpufreq/policy4/scaling_governor`

  if [[ "$governor0" != "$governor" ]]; then
    set_value $governor /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
  fi
  if [[ "$governor4" != "$governor" ]]; then
    set_value $governor /sys/devices/system/cpu/cpufreq/policy4/scaling_governor
  fi
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

lock_value(){
  value=$1
  path=$2
  if [[ -f $path ]]; then
    current_value="$(cat $path)"
    if [[ ! "$current_value" = "$value" ]]; then
      chmod 0664 "$path"
      echo "$value" > "$path"
      chmod 0444 "$path"
    fi;
  fi;
}

set_input_boost_freq() {
  local c0="$1"
  local c1="$2"
  local ms="$3"
  set_value "0:$c0 1:$c0 2:$c0 3:$c0 4:$c1 5:$c1 6:$c1 7:$c1" /sys/module/cpu_boost/parameters/input_boost_freq
  set_value $ms /sys/module/cpu_boost/parameters/input_boost_ms
  if [[ "$ms" -gt 0 ]]; then
    echo 1 > /sys/module/cpu_boost/parameters/sched_boost_on_input
  else
    echo 0 > /sys/module/cpu_boost/parameters/sched_boost_on_input
  fi
}

set_cpu_freq() {
  set_value "0:$2 1:$2 2:$2 3:$2 4:$4 5:$4 6:$4 7:$4" /sys/module/msm_performance/parameters/cpu_max_freq
  set_value $1 /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
  set_value $2 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
  set_value $3 /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
}

sched_config() {
  set_value "$1" /proc/sys/kernel/sched_downmigrate
  set_value "$2" /proc/sys/kernel/sched_upmigrate
  set_value "$1" /proc/sys/kernel/sched_downmigrate

  set_value "$3" /proc/sys/kernel/sched_group_downmigrate
  set_value "$4" /proc/sys/kernel/sched_group_upmigrate
  set_value "$3" /proc/sys/kernel/sched_group_downmigrate
}

sched_limit() {
  set_value $1 /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
  set_value $2 /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
  set_value $3 /sys/devices/system/cpu/cpufreq/policy4/schedutil/down_rate_limit_us
  set_value $4 /sys/devices/system/cpu/cpufreq/policy4/schedutil/up_rate_limit_us
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
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/$governor/hispeed_freq
  echo $2 > /sys/devices/system/cpu/cpufreq/policy4/$governor/hispeed_freq
}

set_hispeed_load() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/$governor/hispeed_load
  echo $2 > /sys/devices/system/cpu/cpufreq/policy4/$governor/hispeed_load
}

sched_boost() {
  set_value $1 /proc/sys/kernel/sched_boost_top_app
  set_value $2 /proc/sys/kernel/sched_boost
}

stune_top_app() {
  set_value $1 /dev/stune/top-app/schedtune.prefer_idle
  set_value $2 /dev/stune/top-app/schedtune.boost
}

cpuset() {
  set_value $1 /dev/cpuset/background/cpus
  set_value $2 /dev/cpuset/system-background/cpus
  set_value $3 /dev/cpuset/foreground/cpus
  set_value $4 /dev/cpuset/top-app/cpus
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
        set_hispeed_freq 0 0
        cpuset '0' '0' '0-5' '0-7'
        sched_boost 0 0
        stune_top_app 0 100

        if [[ "$action" = "powersave" ]]; then
          set_cpu_freq 1708800 1900800 1958400 2323200
        elif [[ "$action" = "balance" ]]; then
          set_cpu_freq 1708800 1900800 2208000 2457600
        elif [[ "$action" = "performance" ]]; then
          set_cpu_freq 1900800 2500000 2323200 2750000
        elif [[ "$action" = "fast" ]]; then
          set_cpu_freq 1900800 2500000 2457600 2750000
        fi

        if [[ "$governor" == 'interactive' ]]; then
          set_value "35 1804800:40" /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
          set_value 1 /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
          set_value "40 1728000:45 2208000:50" /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
          set_value 1 /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
        else
          sched_limit 5000 0 5000 0
        fi
        # scene_scheduler "$top_app" "$action"
    ;;

    # Wang Zhe Rong Yao
    "com.tencent.tmgp.sgame")
        ctl_off cpu0
        ctl_off cpu4
        set_hispeed_freq 0 0
        cpuset '0' '0' '0-5' '0-7'
        sched_boost 0 0
        stune_top_app 0 100

        if [[ "$action" = "powersave" ]]; then
          set_cpu_freq 1708800 1900800 1420800 2323200
        elif [[ "$action" = "balance" ]]; then
          set_cpu_freq 1708800 1900800 1420800 2457600
        elif [[ "$action" = "performance" ]]; then
          set_cpu_freq 1900800 2500000 1804800 2750000
        elif [[ "$action" = "fast" ]]; then
          set_cpu_freq 1900800 2500000 2457600 2750000
        fi

        if [[ "$governor" == 'interactive' ]]; then
          set_value "35 1804800:40" /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
          set_value 1 /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
          set_value "40 1728000:45 2208000:50" /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
          set_value 1 /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
        else
          sched_limit 5000 0 5000 0
        fi
    ;;

    "default")
      echo '未适配的应用'
    ;;
  esac
  scene_scheduler "$top_app" "$action"
}
