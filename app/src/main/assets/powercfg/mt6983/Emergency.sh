lock_value() {
  chmod 777 $2
  echo $1 > $2
  chmod 444 $2
}

core_ctl_policy() {
  if [[ "$1" == "on" || "$1" == "1" ]]; then
    to_on=1
  else
    to_on=0
  fi

  echo $to_on > /sys/module/scheduler/holders/mtk_core_ctl/parameters/policy_enable
  echo $to_on > /sys/module/thermal_interface/holders/mtk_core_ctl/parameters/policy_enable
  echo $to_on > /sys/module/mtk_core_ctl/parameters/policy_enable
  echo $to_on > /sys/module/cpufreq_sugov_ext/holders/mtk_core_ctl/parameters/policy_enable
  echo $to_on > /sys/devices/system/cpu/cpu0/core_ctl/enable
  echo $to_on > /sys/devices/system/cpu/cpu4/core_ctl/enable
  echo $to_on > /sys/devices/system/cpu/cpu7/core_ctl/enable
  echo $to_on > /sys/module/cpufreq_sugov_ext/holders/mtk_core_ctl/parameters/policy_enable
}

# set_cpufreq 4 400000 800000
set_cpufreq(){
  lock_value $3 /sys/devices/system/cpu/cpu$1/cpufreq/scaling_max_freq
  lock_value $2 /sys/devices/system/cpu/cpu$1/cpufreq/scaling_min_freq
  lock_value $3 /sys/devices/system/cpu/cpu$1/cpufreq/scaling_max_freq
  lock_value "$1 $2 $3" /proc/cpudvfs/cpufreq_debug
}

refresh_rate(){
  settings put system peak_refresh_rate "$1"
  settings put system thermal_limit_refresh_rate "$1"
  settings put system user_refresh_rate "$1"
}

animation_speed(){
  settings put global animator_duration_scale $1
  # settings put global new_device_after_support_notification_animation 1
  if [[ "$1" == "0" ]];then
    settings put global transition_animation_duration_ratio 0.01
  else
    settings put global transition_animation_duration_ratio $1
  fi
  settings put global transition_animation_scale $1
  settings put global window_animation_scale $1
}
cpuset() {
  echo $1 > /dev/cpuset/background/cpus
  echo $2 > /dev/cpuset/system-background/cpus
  echo $3 > /dev/cpuset/foreground/cpus
  echo $4 > /dev/cpuset/top-app/cpus
}
conservative(){
  for policy in /sys/devices/system/cpu/cpufreq/*
  do
    lock_value conservative $policy/scaling_governor
    lock_value 1 $policy/conservative/sampling_down_factor
    lock_value 99 $policy/conservative/up_threshold
    lock_value 95 $policy/conservative/down_threshold
    lock_value 2 $policy/conservative/freq_step
  done
}
schedutil(){
  for policy in /sys/devices/system/cpu/cpufreq/*
  do
    lock_value schedutil $policy/scaling_governor
  done
}
cpuctl () {
  echo $2 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $3 > /dev/cpuctl/$1/cpu.uclamp.max
  echo $2 > /dev/cpuctl/$1/cpu.uclamp.min
}

# K50Pro Max:16383
brightness(){
  if [[ "$1" == "max" ]]; then
    max=$(cat /sys/devices/platform/soc/soc:mtk_leds/leds/lcd-backlight/max_brightness)
    echo $max > /sys/devices/platform/soc/soc:mtk_leds/leds/lcd-backlight/brightness
  else
    echo $1 > /sys/devices/platform/soc/soc:mtk_leds/leds/lcd-backlight/brightness
  fi
}

enter() {
  killall scene-scheduler 2>/dev/null
  killall scene-daemon 2>/dev/null
  brightness 2048

  lock_value 0 /sys/kernel/fpsgo/fstb/fstb_self_ctrl_fps_enable
  lock_value '1 3-3' /sys/kernel/fpsgo/fstb/fstb_soft_level
  lock_value 3 /sys/kernel/fpsgo/fstb/set_render_max_fps
  lock_value 1 /sys/kernel/fpsgo/common/fpsgo_enable
  lock_value 1 /sys/module/sspm_v3/holders/ged/parameters/is_GED_KPI_enabled
  lock_value 1 /sys/kernel/ged/hal/dcs_mode
  lock_value -1 /proc/gpufreqv2/fix_target_opp_index
  lock_value 40 /sys/kernel/ged/hal/custom_upbound_gpu_freq
  lock_value 0 /sys/module/ged/parameters/gpu_cust_boost_freq
  lock_value 99 /sys/kernel/ged/hal/custom_boost_gpu_freq
  lock_value 0 /sys/class/devfreq/13000000.mali/min_freq

  settings put secure accessibility_display_daltonizer 0
  settings put secure accessibility_display_daltonizer_enabled 1

  conservative
  set_cpufreq 0 200000 600000
  set_cpufreq 4 400000 1000000
  set_cpufreq 7 200000 1300000
  lock_value 0 /sys/devices/system/cpu/cpu7/core_ctl/max_cpus

  core_ctl_policy on

  cpuctl background 0.00 0.00
  cpuctl foreground 0.00 10.00
  cpuctl top-app 0.00 max

  cpuset 1 3 3-4 0-6

  animation_speed 0.1
  refresh_rate 60

  killall com.omarea.vtools 2>/dev/null
  killall scene-daemon 2>/dev/null
}

_exit() {
  lock_value 1 /sys/kernel/fpsgo/fstb/fstb_self_ctrl_fps_enable
  lock_value 120 /sys/kernel/fpsgo/fstb/set_render_max_fps
  lock_value '1 240-10' /sys/kernel/fpsgo/fstb/fstb_soft_level
  lock_value 1 /sys/kernel/fpsgo/common/fpsgo_enable
  lock_value 1 /sys/module/sspm_v3/holders/ged/parameters/is_GED_KPI_enabled
  lock_value 1 /sys/kernel/ged/hal/dcs_mode
  lock_value -1 /proc/gpufreqv2/fix_target_opp_index
  lock_value 0 /sys/kernel/ged/hal/custom_upbound_gpu_freq
  # lock_value 0 /sys/module/ged/parameters/gpu_cust_boost_freq
  # lock_value 99 /sys/kernel/ged/hal/custom_boost_gpu_freq
  # lock_value 0 /sys/class/devfreq/13000000.mali/min_freq

  settings put secure accessibility_display_daltonizer_enabled 0

  schedutil
  set_cpufreq 0 200000 2000000
  set_cpufreq 4 400000 2850000
  set_cpufreq 7 200000 3000000
  lock_value 1 /sys/devices/system/cpu/cpu7/core_ctl/max_cpus

  # core_ctl_policy on

  cpuctl background 0.00 max
  cpuctl foreground 0.00 max
  cpuctl top-app 0.00 max

  cpuset 1-3 0-4 0-6 0-7

  animation_speed 1
  refresh_rate ''
}