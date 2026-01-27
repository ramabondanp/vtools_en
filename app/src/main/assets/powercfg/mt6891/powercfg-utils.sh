# /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies
# 840000000 778000000 738000000 676000000 608000000 540000000 491000000 443000000 379000000 315000000

manufacturer=$(getprop ro.product.manufacturer)

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

# [none] intra-slot inter-slot full full-reset
serialize_jobs(){
  echo $1 > /sys/devices/platform/13000000.mali/scheduling/serialize_jobs
}

# 0:Nrmal 1:Perf
cpu_cci_mode() {
  echo $1 > /proc/cpufreq/cpufreq_cci_mode
}

# 0 Default(Normal) mode
# 1 Low Power mode
# 2 Just Make mode
# 3 Performance(Sports) mode
cpu_power_mode() {
  echo $1 > /proc/cpufreq/cpufreq_power_mode
}

# sched_deisolation [cpuIndex]
sched_deisolation() {
  echo $1 > /sys/devices/system/cpu/sched/set_sched_deisolation
}
# sched_isolation [cpuIndex]
sched_isolation() {
  echo $1 > /sys/devices/system/cpu/sched/set_sched_isolation
}
sched_isolation_disable() {
  for i in 0 1 2 3 4 5 6 7; do
    echo $i > /sys/devices/system/cpu/sched/set_sched_deisolation
  done
  chmod 000 /sys/devices/system/cpu/sched/set_sched_isolation
}
hmp() {
  lock_value 0 /sys/devices/system/cpu/eas/enable
}
eas() {
  lock_value 1 /sys/devices/system/cpu/eas/enable
}
hybrid() {
  lock_value 2 /sys/devices/system/cpu/eas/enable
}

ppm() {
  echo $2 > "/proc/ppm/$1"
}

policy() {
  lock_value "$2" "/proc/ppm/policy/$1"
}

lock_freq() {
  policy ut_fix_freq_idx "$1 $2"
}

max_freq() {
  policy hard_userlimit_max_cpu_freq "0 $1"
  policy hard_userlimit_max_cpu_freq "1 $2"
  policy hard_userlimit_max_cpu_freq "2 $3"
  # policy userlimit_max_cpu_freq "0 $1"
  # policy userlimit_max_cpu_freq "1 $2"
  # policy userlimit_max_cpu_freq "2 $3"
  # echo $3 > /sys/kernel/fpsgo/fbt/limit_cfreq
  # echo $3 > /sys/kernel/fpsgo/fbt/limit_rfreq
  # echo $2 > /sys/kernel/fpsgo/fbt/limit_cfreq_m
  # echo $2 > /sys/kernel/fpsgo/fbt/limit_rfreq_m
}

min_freq() {
  policy hard_userlimit_min_cpu_freq "0 $1"
  policy hard_userlimit_min_cpu_freq "1 $2"
  policy hard_userlimit_min_cpu_freq "2 $3"
  # policy userlimit_min_cpu_freq "0 $1"
  # policy userlimit_min_cpu_freq "1 $2"
  # policy userlimit_min_cpu_freq "2 $3"
}

ged() {
  echo $2 > /sys/module/ged/parameters/$1
}

cpuset() {
  echo $1 > /dev/cpuset/background/cpus
  echo $2 > /dev/cpuset/system-background/cpus
  echo $3 > /dev/cpuset/foreground/cpus
  echo $4 > /dev/cpuset/top-app/cpus
  echo $5 > /dev/cpuset/restricted/cpus
}

# gpu_freq_max [oppIndex]
gpu_freq_max() {
  echo $1 > /sys/kernel/ged/hal/custom_upbound_gpu_freq
}
# gpu_freq_max_freq [freqKHZ]
gpu_freq_max_freq() {
  gpu_opp=$(grep "freq = $1," /proc/gpufreq/gpufreq_opp_dump)
  lock_value $((${gpu_opp:1:2}+0)) /sys/kernel/ged/hal/custom_upbound_gpu_freq
  lock_value 32 /sys/kernel/ged/hal/custom_boost_gpu_freq
}

gpu_dvfs_margin() {
  echo $1 > /sys/kernel/ged/hal/timer_base_dvfs_margin
  echo $1 > /sys/kernel/ged/hal/dvfs_margin_value
  if [[ "$2" == "" ]]; then
    echo 0 > /sys/kernel/fpsgo/fstb/margin_mode
  else
    echo $2 > /sys/kernel/fpsgo/fstb/margin_mode
  fi
}

# gpu_freq_fixed [freqKHZ]
gpu_freq_fixed() {
  echo $1 > /proc/gpufreq/gpufreq_opp_freq
  local dvfs=/proc/mali/dvfs_enable
  if [[ -f $dvfs ]]; then
    if [[ "$1" == "0" ]]; then
      echo 1 > $dvfs
      # set_value 1 /sys/module/ged/parameters/gpu_dvfs_enable
    else
      echo 0 > $dvfs
      # set_value 0 /sys/module/ged/parameters/gpu_dvfs_enable
    fi
  fi
  echo $1 > /proc/gpufreq/gpufreq_opp_freq
}

gbe() {
  if [[ "$1" == "on" || "$1" == "1" || "$1" == "true" ]]; then
    echo 1 > /sys/module/ged/parameters/ged_boost_enable
    echo 2 > /sys/kernel/gbe/gbe2_max_boost_cnt
    echo 20 > /sys/kernel/gbe/gbe2_loading_th
    echo 1 > /sys/kernel/gbe/gbe_enable1
    echo 1 > /sys/kernel/gbe/gbe_enable2
    echo 1 > /sys/module/ged/parameters/enable_cpu_boost
    echo 1 > /sys/module/ged/parameters/enable_gpu_boost
    echo 1 > /sys/module/ged/parameters/is_GED_KPI_enabled
    # echo 16000000 > /sys/module/ged/parameters/target_t_cpu_remained
    # echo 200 > /sys/module/ged/parameters/gx_fb_dvfs_margin
  else
    echo 0 > /sys/kernel/gbe/gbe_enable1
    echo 0 > /sys/kernel/gbe/gbe_enable2
    echo 5 > /sys/kernel/gbe/gbe2_max_boost_cnt
  fi
}

reset_basic_governor() {
  stop_scene_scheduler
  set_core_online
  hybrid
  policy=/sys/devices/system/cpu/cpufreq/
  ls $policy | while read cluster; do
    set_value schedutil ${policy}${cluster}/scaling_governor
  done

  # GPU
  gpu_freq_fixed 0
  serialize_jobs none
  gpu_freq_max 0
  gbe_on=0
  # gpu_dvfs_margin 10

  # DRAM
  dram_freq 0

  # PPM
  # policy_status
  # [0] PPM_POLICY_PTPOD: enabled
  # [1] PPM_POLICY_UT: enabled
  # [2] PPM_POLICY_FORCE_LIMIT: enabled
  # [3] PPM_POLICY_PWR_THRO: enabled
  # [4] PPM_POLICY_THERMAL: enabled
  # [6] PPM_POLICY_HARD_USER_LIMIT: enabled
  # [7] PPM_POLICY_USER_LIMIT: enabled
  # [8] PPM_POLICY_LCM_OFF: disabled
  # [9] PPM_POLICY_SYS_BOOST: disabled

  # Usage: echo <idx> <1/0> > /proc/ppm/policy_status

  ppm enabled 1
  ppm policy_status "0 0"
  ppm policy_status "1 0"
  ppm policy_status "2 0"
  ppm policy_status "3 0"
  ppm policy_status "4 0"
  # ppm policy_status "5 0"
  ppm policy_status "6 1"
  ppm policy_status "7 0"
  ppm policy_status "9 0"

  sspm_thermal_throttle 0
  echo 0 > /sys/kernel/fpsgo/fbt/switch_idleprefer
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

set_cpu_freq() {
  # echo "0:$2 1:$2 2:$2 3:$2 4:$4 5:$4 6:$4 7:$6" > /sys/module/msm_performance/parameters/cpu_max_freq
  # echo $1 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
  # echo $2 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
  # echo $3 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
  # echo $4 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
  # echo $5 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
  # echo $6 > /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq

  min_freq $1 $3 $5
  max_freq $2 $4 $6
}

sched_limit() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
  echo $2 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
  echo $3 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/down_rate_limit_us
  echo $4 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/up_rate_limit_us
  echo $5 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/down_rate_limit_us
  echo $6 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/up_rate_limit_us
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
  echo $3 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/hispeed_freq
}

set_stune() {
  echo $2 > /dev/stune/$1/schedtune.prefer_idle
  echo $3 > /dev/stune/$1/schedtune.boost
}
stune_top_app() {
  set_stune top-app $1 $2
}

# For MTK
# stune_util [top-app] [Max:0~1024] [Min:0~1014]
stune_util() {
  chmod 400 /dev/stune/$1/schedtune.util.max.effective
  chmod 400 /dev/stune/$1/schedtune.util.max.pct
  chmod 400 /dev/stune/$1/schedtune.util.min.effective
  chmod 400 /dev/stune/$1/schedtune.util.min.pct
  echo $2 > /dev/stune/$1/schedtune.util.max
  echo $3 > /dev/stune/$1/schedtune.util.min
  lock_value $2 /dev/stune/$1/schedtune.util.max
  lock_value $3 /dev/stune/$1/schedtune.util.min
}

# cpuset() {
#   echo $1 > /dev/cpuset/background/cpus
#   echo $2 > /dev/cpuset/system-background/cpus
#   echo $3 > /dev/cpuset/foreground/cpus
#   echo $4 > /dev/cpuset/top-app/cpus
# }

lock_value () {
  chmod 644 $2
  echo $1 > $2
  chmod 444 $2
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

# 0 / max / 4266000 3733000 3733000 3068000 3068000 2366000 2366000 2366000 1866000 1866000 1866000 1866000 1534000 1534000 1534000 1534000 1200000 1200000 1200000 1200000 800000 800000 800000 800000
dram_freq(){
  if [[ "$1" == "max" ]]; then
    echo 1 > /sys/devices/platform/boot_dramboost/dramboost/dramboost
    ddr_opp=$(cat /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_opp_table | head -1)
    echo ${ddr_opp:4:2} > /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
  elif [[ "$1" == "0" ]]; then
    echo 0 > /sys/devices/platform/boot_dramboost/dramboost/dramboost
    echo -1 > /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
  else
    ddr_opp=$(grep ${1}000 /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_opp_table | head -1)
    echo ${ddr_opp:4:2} > /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
  fi
}

disable_oppo_elf() {
  pm disable com.coloros.oppoguardelf/com.coloros.powermanager.fuelgaue.GuardElfAIDLService
  pm disable com.coloros.oppoguardelf/com.coloros.oppoguardelf.OppoGuardElfService
}

sched_boost_get() {
  cat /sys/devices/system/cpu/sched/sched_boost | cut -f2 -d '='
}

sched_boost_set() {
  if [[ "$state" == "no boost" ]]; then
    echo 0 > /sys/devices/system/cpu/sched/sched_boost
  elif [[ "$state" == "all boost" ]]; then
    echo 1 > /sys/devices/system/cpu/sched/sched_boost
  elif [[ "$state" == "foreground boost" ]]; then
    echo 2 > /sys/devices/system/cpu/sched/sched_boost
  fi
}

# 0:Normal 1:Extreme(dangerous)
sspm_thermal_throttle(){
  echo $1 > /proc/driver/thermal/sspm_thermal_throttle
}

# set_task_affinity $pid $use_cores[cpu7~cpu0]
set_task_affinity() {
  pid=$1
  if [[ "$pid" != "" ]]; then
    mask=`echo "obase=16;$((num=2#$2))" | bc`
    for tid in $(ls "/proc/$pid/task/"); do
      taskset -p "$mask" "$tid" 1>/dev/null
    done
    taskset -p "$mask" "$pid" 1>/dev/null
  fi
}


# YuanShen
yuan_shen_basic() {
  cpu_cci_mode 1
  if [[ "$1" = "powersave" ]]; then
    stune_top_app 0 0
    set_cpu_freq 1525000 2000000 902000 1624000 659000 1985000
    sched_limit 5000 0 0 0 0 0
    # gpu_freq_fixed 512000
    gpu_freq_max_freq 512000
    gpu_dvfs_margin 15
    # serialize_jobs intra-slot
    # dram_freq 3733
    dram_freq max
  elif [[ "$1" = "balance" ]]; then
    stune_top_app 0 0
    set_cpu_freq 1525000 2000000 902000 1855000 659000 2292000
    sched_limit 5000 0 0 0 0 0
    # gpu_freq_fixed 512000
    gpu_freq_max_freq 614000
    gpu_dvfs_margin 20
    # serialize_jobs intra-slot
    dram_freq max
  elif [[ "$1" = "performance" ]]; then
    stune_top_app 0 10
    set_cpu_freq 1725000 2000000 1335000 2354000 1482000 2600000
    sched_limit 5000 0 0 0 0 0
    # gpu_freq_fixed 614000
    gpu_freq_max_freq 705000
    gpu_dvfs_margin 20
    # serialize_jobs intra-slot
    dram_freq max
  elif [[ "$1" = "fast" ]]; then
    stune_top_app 1 55
    sched_limit 5000 0 2000 0 2000 0
    # gpu_freq_fixed 705000
    gpu_freq_max_freq 755000
    gpu_dvfs_margin 25
    # gpu_freq_max_freq 848000
    # serialize_jobs intra-slot
    dram_freq max
  elif [[ "$1" = "pedestal" ]]; then
    stune_top_app 0 100
  fi
}

board_sensor_temp=/sys/class/thermal/thermal_message/board_sensor_temp
thermal_disguise() {
  if [[ "$1" == "1" ]] || [[ "$1" == "true" ]]; then
    chmod 644 $board_sensor_temp
    echo 36500 > $board_sensor_temp
    # disguise_timeout=10
    # while [ $disguise_timeout -gt 0 ]; do
    #   echo $1 > $board_sensor_temp
    #   disguise_timeout=$((disguise_timeout-1))
    #   sleep 1
    # done

    # # restart mi_thermald
    # # pgrep mi_thermald | xarg kill -9 2>/dev/null
    # stop mi_thermald && start mi_thermald
    # sleep 0.2

    echo "thermal_disguise [enable]"
    chmod 000 $board_sensor_temp
    setprop vtools.thermal.disguise 1
    nohup pm clear com.xiaomi.gamecenter.sdk.service >/dev/null 2>&1 &
    nohup pm disable com.xiaomi.gamecenter.sdk.service/.PidService >/dev/null 2>&1 &
  else
    setprop vtools.thermal.disguise 0
    nohup pm enable com.xiaomi.gamecenter.sdk.service/.PidService >/dev/null 2>&1 &
    chmod 644 $board_sensor_temp
    echo 'thermal_disguise [disable]'
  fi
}

move_to_cpuset() {
  local pid="$1"
  local cpuset="/dev/cpuset/$2/cgroup.procs"
  if [[ "$pid" != "" ]] && [[ -e "$cpuset" ]]; then
    echo $pid > "$cpuset"
  fi
}

# Check whether the taskset command is useful
taskset_test() {
  local pid="$1"
  if [[ "$pid" == "" ]]; then
    return 2
  fi

  # Compatibility Test
  any_tid=$(ls /proc/$pid/task | head -n 1)
  if [[ "$any_tid" != "" ]]; then
    test_fail=$(taskset -p ff $any_tid 2>&1 | grep 'Operation not permitted')
    if [[ "$test_fail" != "" ]]; then
      echo 'taskset Cannot run on your device!' 1>&2
      return 0
    fi
  fi
  return 1
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
    "com.miHoYo.Yuanshen" | "com.miHoYo.ys.mi" | "com.miHoYo.ys.bilibili" | "com.miHoYo.GenshinImpact")
        # ctl_off cpu4
        # ctl_off cpu7
        thermal_disguise 1
        set_hispeed_freq 0 0 0
        yuan_shen_basic $action
        cpuset '0' '0' '0-7' '0-7'
        # scene_scheduler "$top_app" "$action"
    ;;

    # Project SEKAI
    "com.hermes.mk.asia"|"com.sega.pjsekai")
      if [[ "$action" == "powersave" ]]; then
        stune_top_app 1 0
      elif [[ "$action" == "balance" ]]; then
        stune_top_app 1 0
      elif [[ "$action" == "performance" ]]; then
        stune_top_app 1 0
      else
        stune_top_app 1 10
      fi
    ;;

    # Wang Zhe Rong Yao\LOL
    "com.tencent.lolm"|"com.tencent.tmgp.sgame"|"com.garena.game.kgtw")
        # ctl_off cpu4
        # ctl_off cpu7
        thermal_disguise 1
        if [[ "$action" = "powersave" ]]; then
          stune_top_app 0 0
          set_cpu_freq 925000 1800000 700000 1745000 659000 2127000
          cpuset '0-1' '0-1' '0-6' '0-7'
          gpu_dvfs_margin 15 2
        elif [[ "$action" = "balance" ]]; then
          stune_top_app 0 0
          sched_limit 5000 0 0 0 0 0
          set_cpu_freq 1525000 1800000 1162000 1855000 921000 2292000
          cpuset '0-1' '0-1' '0-7' '0-7'
          gpu_dvfs_margin 20 2
        elif [[ "$action" = "performance" ]]; then
          stune_top_app 0 0
          sched_limit 5000 0 500 0 500 0
          set_cpu_freq 1075000 2000000 1451000 2200000 1482000 2600000
          cpuset '0-1' '0-1' '0-7' '0-7'
          gbe_on=1
        elif [[ "$action" = "fast" ]]; then
          stune_top_app 0 10
          set_cpu_freq 1075000 2000000 1537000 2507000 1632000 2600000
          cpuset '0-1' '0-1' '0-7' '0-7'
          gbe_on=1
        elif [[ "$1" = "pedestal" ]]; then
          stune_top_app 0 100
          gbe_on=1
        fi
    ;;

    "com.tencent.tmgp.speedmobile", "com.garena.game.fctw")
      realme_gt_on=1
      cpuset '0' '0' '0-7' '0-7'
      # scene_scheduler "$top_app" "$action"
    ;;

    "com.dw.h5yvzr.yt"|"com.pwrd.hotta.laohu"|"com.hottagames.hotta.bilibili"|"com.hottagames.hotta.mi")
      cpuset '0' '0' '0-7' '0-7'
      # scene_scheduler "$top_app" "$action"
    ;;

    "default")
      echo '未适配的应用'
    ;;
  esac
  # gbe $gbe_on
  scene_scheduler "$top_app" "$action"
}
