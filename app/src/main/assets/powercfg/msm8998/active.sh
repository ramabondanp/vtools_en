#!/system/bin/sh

action=$1
task=$2

cfg_dir=$(cd $(dirname $0); pwd)

if [[ ! -f "$cfg_dir/powercfg-utils.sh" ]]; then
  echo "The dependent '$cfg_dir/powercfg-utils.sh' was not found !" > /cache/powercfg.sh.log
  exit 1
fi

source "$cfg_dir/powercfg-utils.sh"

init () {
  if [[ -f "$cfg_dir/powercfg-base.sh" ]]; then
    source "$cfg_dir/powercfg-base.sh"
  elif [[ -f '/data/powercfg-base.sh' ]]; then
    source /data/powercfg-base.sh
  fi
}

if [[ "$action" == "init" ]]; then
  init
  exit 0
fi

lock_value 0 /sys/devices/system/cpu/cpu0/cpufreq/interactive/boost
lock_value 0 /sys/devices/system/cpu/cpu4/cpufreq/interactive/boost

interactive_cfg(){
  set_value $2 /sys/devices/system/cpu/cpu$1/cpufreq/interactive/max_freq_hysteresis
  set_value $3 /sys/devices/system/cpu/cpu$1/cpufreq/interactive/min_sample_time
  set_value $4 /sys/devices/system/cpu/cpu$1/cpufreq/interactive/timer_rate
}

schedutil_cfg(){
  set_value $2 /sys/devices/system/cpu/cpu$1/cpufreq/schedutil/down_rate_limit_us
  set_value $3 /sys/devices/system/cpu/cpu$1/cpufreq/schedutil/up_rate_limit_us
  set_value $4 /sys/devices/system/cpu/cpu$1/cpufreq/schedutil/iowait_boost_enable
}

if [[ "$action" = "powersave" ]]; then
  set_cpu_freq 5000 1747200 5000 1574400
  set_input_boost_freq 0 0 0

  echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
  echo 0 > /proc/sys/kernel/sched_boost
  echo 15 > /proc/sys/kernel/sched_init_task_load

  cpuset 0-2 0-3 0-3 0-7
  sched_config 80 90 80 90

  if [[ "$governor" == 'interactive' ]]; then
    set_value "85 300000:85 595200:67 825600:75 1248000:78" /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
    set_value 518400 /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
    set_value "99" /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
    set_value 576000 /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
    set_value 0 /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
  fi

  interactive_cfg 0 0 9000 10000
  schedutil_cfg 0 1000 10000 0

  interactive_cfg 4 0 19000 20000
  schedutil_cfg 4 1000 10000 0

elif [[ "$action" = "balance" ]]; then
  set_cpu_freq 5000 1900800 5000 2112000
  set_input_boost_freq 1478400 1574400 500

  gpu_pl_up 1
  echo 0 > /proc/sys/kernel/sched_boost
  echo 25 > /proc/sys/kernel/sched_init_task_load

  cpuset 0-2 0-3 0-3 0-7
  sched_config 70 85 70 85

  if [[ "$governor" == 'interactive' ]]; then
    set_value "84 300000:85 595200:67 825600:75 1248000:78" /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
    set_value 960000 /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
    set_value "83 300000:89 1056000:89 1344000:92" /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
    set_value 1056000 /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
    set_value 0 /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
  fi

  interactive_cfg 0 0 9000 10000
  schedutil_cfg 0 1000 5000 0

  interactive_cfg 4 0 19000 20000
  schedutil_cfg 4 1000 5000 0

elif [[ "$action" = "performance" ]]; then
  set_cpu_freq 5000 1900800 5000 2457600
  set_input_boost_freq 1900800 1881600 1000

  gpu_pl_up 2
  echo 0 > /proc/sys/kernel/sched_boost
  echo 30 > /proc/sys/kernel/sched_init_task_load

  cpuset 0-1 0-3 0-7 0-7
  sched_config 50 65 50 65

  if [[ "$governor" == 'interactive' ]]; then
    set_value "73 960000:72 1478400:78 1804800:87" /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
    set_value 1478400 /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
    set_value "78 1497600:80 2016000:87" /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
    set_value 1267200 /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
  fi

  interactive_cfg 0 79000 19000 10000
  schedutil_cfg 0 1000 1000 1

  interactive_cfg 4 79000 23000 12000
  schedutil_cfg 4 1000 1000 1

elif [[ "$action" = "fast" ]]; then
  set_cpu_freq 1248000 2500000 1056000 2750000
  set_input_boost_freq 1900800 1804800 2000

  gpu_pl_up 2
  echo 2 > /proc/sys/kernel/sched_boost
  echo 30 > /proc/sys/kernel/sched_init_task_load

  cpuset 0 0-3 0-7 0-7
  sched_config 30 45 30 45

  if [[ "$governor" == 'interactive' ]]; then
    set_value "52 960000:50 1478400:55 1804800:60" /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
    set_value 1036800 /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
    set_value "60 1497600:55 2016000:70" /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
    set_value 1497600 /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
  fi

  interactive_cfg 0 79000 19000 5000
  schedutil_cfg 0 1000 1000 1

  interactive_cfg 4 79000 19000 5000
  schedutil_cfg 4 1000 1000 1

elif [[ "$action" = "pedestal" ]]; then
  set_cpu_freq 1900800 2500000 2457600 2750000
  set_input_boost_freq 1900800 2457600 0

  gpu_pl_up 4
  echo 2 > /proc/sys/kernel/sched_boost
  echo 30 > /proc/sys/kernel/sched_init_task_load

  cpuset 0 0-3 0-7 0-7
  sched_config 30 45 30 45

  if [[ "$governor" == 'interactive' ]]; then
    set_value "30 960000:40 1478400:45 1804800:45" /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
    set_value 1036800 /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
    set_value "45 1497600:45 2016000:50" /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
    set_value 2457600 /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
  fi

  interactive_cfg 0 79000 19000 5000
  schedutil_cfg 0 1000 1000 1

  interactive_cfg 4 79000 19000 5000
  schedutil_cfg 4 1000 1000 1

fi

adjustment_by_top_app
