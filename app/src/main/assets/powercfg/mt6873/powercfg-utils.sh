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

stune_top_app() {
  echo $1 > /dev/stune/top-app/schedtune.prefer_idle
  echo $2 > /dev/stune/top-app/schedtune.boost
}

lock_freq() {
  policy ut_fix_freq_idx "$1 $2"
}

max_freq() {
  policy hard_userlimit_max_cpu_freq "0 $1"
  policy hard_userlimit_max_cpu_freq "1 $2"
  # policy userlimit_max_cpu_freq "0 $1"
  # policy userlimit_max_cpu_freq "1 $2"
}

min_freq() {
  policy hard_userlimit_min_cpu_freq "0 $1"
  policy hard_userlimit_min_cpu_freq "1 $2"
  # policy userlimit_min_cpu_freq "0 $1"
  # policy userlimit_min_cpu_freq "1 $2"
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

reset_basic_governor() {
  stop_scene_scheduler
  set_core_online

  # CPU
  governor0=`cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor`
  governor4=`cat /sys/devices/system/cpu/cpufreq/policy4/scaling_governor`

  if [[ ! "$governor0" = "schedutil" ]]; then
    echo 'schedutil' > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
  fi
  if [[ ! "$governor4" = "schedutil" ]]; then
    echo 'schedutil' > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor
  fi

  # GPU
  gpu_freq_fixed 0
  serialize_jobs none
  gpu_freq_max 0
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
  # echo "0:$2 1:$2 2:$2 3:$2 4:$4 5:$4 6:$4 7:$4" > /sys/module/msm_performance/parameters/cpu_max_freq
  # echo $1 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
  # echo $2 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
  # echo $3 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
  # echo $4 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq

  min_freq $1 $2
  max_freq $3 $4
}

sched_limit() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
  echo $2 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
  echo $3 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/down_rate_limit_us
  echo $4 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/up_rate_limit_us
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

cpuctl () {
  echo $2 > /dev/cpuctl/$1/cpu.uclamp.sched_boost_no_override
  echo $3 > /dev/cpuctl/$1/cpu.uclamp.latency_sensitive
  echo $4 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $5 > /dev/cpuctl/$1/cpu.uclamp.max
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
    taskset -p "FF" "$pid" > /dev/null 2>&1
    for tid in $(ls "/proc/$pid/task/"); do
      if [[ "$pid" == "$tid" ]]; then
        taskset -p "FF" "$tid" > /dev/null 2>&1
      elif [[ -f "/proc/$pid/task/$tid/comm" ]]; then
        comm=$(cat /proc/$pid/task/$tid/comm)
        case "$comm" in
         "UnityMain")
           # set cpu7
           taskset -p "80" "$tid" > /dev/null 2>&1
         ;;
         *)
           # set cpu0-6
           taskset -p "7F" "$tid" > /dev/null 2>&1
         ;;
        esac
      fi
    done
  fi
}

# HePingJingYing
pubgmhd_opt_run () {
  local current_app=$(getprop vtools.powercfg_app)
  if [[ "$current_app" != 'com.tencent.tmgp.pubgmhd' ]] && [[ "$current_app" != 'com.tencent.ig' ]]; then
    return
  fi

  # mask=`echo "obase=16;$((num=2#11110000))" | bc` # F0 (cpu 7-4)
  # mask=`echo "obase=16;$((num=2#10000000))" | bc` # 80 (cpu 7)
  # mask=`echo "obase=16;$((num=2#01110000))" | bc` # 70 (cpu 6-4)
  # mask=`echo "obase=16;$((num=2#01111111))" | bc` # 7F (cpu 6-0)

  ps -ef -o PID,NAME | grep -e "$current_app$" | egrep -o '[0-9]{1,}' | while read pid; do
    taskset -p "FF" "$pid" > /dev/null 2>&1
    for tid in $(ls "/proc/$pid/task/"); do
      if [[ "$tid" == "$pid" ]]; then
        taskset -p "FF" "$tid" > /dev/null 2>&1
        continue
      fi
      if [[ -f "/proc/$pid/task/$tid/comm" ]]; then
        comm=$(cat /proc/$pid/task/$tid/comm)

        case "$comm" in
         "RenderThread"*)
           taskset -p "80" "$tid" > /dev/null 2>&1
           echo 1
         ;;
         *)
           taskset -p "7F" "$tid" > /dev/null 2>&1
         ;;
        esac
      fi
    done
  done
}

# Unity'Games
unity_opt_run () {
  local current_app=$top_app

  # mask=`echo "obase=16;$((num=2#11110000))" | bc` # F0 (cpu 7-4)
  # mask=`echo "obase=16;$((num=2#10000000))" | bc` # 80 (cpu 7)
  # mask=`echo "obase=16;$((num=2#01110000))" | bc` # 70 (cpu 6-4)
  # mask=`echo "obase=16;$((num=2#01111111))" | bc` # 7F (cpu 6-0)

  ps -ef -o PID,NAME | grep -e "$current_app$" | egrep -o '[0-9]{1,}' | while read pid; do
    for tid in $(ls "/proc/$pid/task/"); do
      if [[ "$tid" == "$pid" ]]; then
        taskset -p "FF" "$tid" > /dev/null 2>&1
        continue
      fi
      if [[ -f "/proc/$pid/task/$tid/comm" ]]; then
        comm=$(cat /proc/$pid/task/$tid/comm)

        case "$comm" in
          "RenderThread"*|"UnityMain")
            taskset -p "80" "$tid" > /dev/null 2>&1
          ;;
          "UnityGfxDevice"*|"UnityMultiRende"*)
            taskset -p "F0" "$tid" > /dev/null 2>&1
          ;;
        esac
      fi
    done
  done
}

# YuanShen
yuan_shen_basic() {
  cpu_cci_mode 1
  if [[ "$1" = "powersave" ]]; then
    stune_top_app 0 0
    set_cpu_freq 1541000 2000000 925000 1633000
    sched_limit 5000 0 0 0
    # gpu_freq_fixed 512000
    gpu_freq_max_freq 543000
    gpu_dvfs_margin 15
    # serialize_jobs intra-slot
    # dram_freq 3733
    dram_freq max
  elif [[ "$1" = "balance" ]]; then
    stune_top_app 0 0
    set_cpu_freq 1541000 2000000 925000 1933000
    sched_limit 5000 0 0 0
    # gpu_freq_fixed 512000
    gpu_freq_max_freq 647000
    gpu_dvfs_margin 20
    # serialize_jobs intra-slot
    dram_freq max
  elif [[ "$1" = "performance" ]]; then
    stune_top_app 0 10
    set_cpu_freq 1725000 2000000 1383000 2433000
    sched_limit 5000 0 0 0
    # gpu_freq_fixed 614000
    gpu_freq_max_freq 736000
    gpu_dvfs_margin 20
    # serialize_jobs intra-slot
    dram_freq max
  elif [[ "$1" = "fast" ]]; then
    stune_top_app 1 55
    sched_limit 5000 0 2000
    # gpu_freq_fixed 705000
    gpu_freq_max_freq 795000
    gpu_dvfs_margin 25
    # gpu_freq_max_freq 848000
    # serialize_jobs intra-slot
    dram_freq max
  fi
}

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
    if [[ "$taskset_effective" == "" ]]; then
      taskset_test $pid
      if [[ "$?" == '1' ]]; then
        taskset_effective=1
      else
        taskset_effective=0
        exit
      fi
    fi

    local mode=$(getprop vtools.powercfg)
    yuan_shen_basic $mode
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

# watch_app [on_tick] [on_change]
watch_app() {
  local interval=120
  local on_tick="$1"
  local on_change="$2"
  local app=$top_app
  local current_pid=$$

  if [[ "$on_tick" == "" ]] || [[ "$app" == "" ]]; then
    return
  fi

  if [[ "$task" != "" ]]; then
    pgrep -f com.omarea.*powercfg.sh | grep -v $current_pid | while read pid; do
      local cmdline=$(cat /proc/$pid/cmdline | grep -a task)
      if [[ "$cmdline" != '' ]] && [[ $(echo $cmdline | grep $task) == '' ]];then
        kill -9 $pid 2> /dev/null
      fi
    done
  fi

  if [[ $(getprop vtools.powercfg_app) == "$app" ]]; then
    $on_tick
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
      $on_tick
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
    "com.miHoYo.Yuanshen" | "com.miHoYo.ys.mi" | "com.miHoYo.ys.bilibili" | "com.miHoYo.GenshinImpact")
        # ctl_off cpu4
        # ctl_off cpu7
        thermal_disguise 1
        set_hispeed_freq 0 0 0
        yuan_shen_basic $action
        cpuset '0' '0' '0-7' '0-7'
        # scene_scheduler "$top_app" "$action"
        watch_app yuan_shen_opt_run &
    ;;

    # Project SEKAI
    "com.hermes.mk.asia"|"com.sega.pjsekai")
      # watch_app unity_opt_run &
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
          set_cpu_freq 1075000 1800000 774000 1800000
          cpuset '0-1' '0-1' '0-3' '0-7'
        elif [[ "$action" = "balance" ]]; then
          stune_top_app 0 0
          set_cpu_freq 1075000 1800000 925000 1933000
          cpuset '0-1' '0-1' '0-6' '0-7'
        elif [[ "$action" = "performance" ]]; then
          stune_top_app 0 0
          set_cpu_freq 1075000 2000000 1050000 2433000
          cpuset '0-1' '0-1' '0-6' '0-7'
        elif [[ "$action" = "fast" ]]; then
          stune_top_app 1 55
          cpuset '0-1' '0-1' '0-6' '0-7'
        fi
    ;;

    "com.speedsoftware.rootexplorer" | "com.estrongs.android.pop")
      if [[ "$action" = "powersave" ]]; then
        sched_limit 0 0 0 0
      elif [[ "$action" = "balance" ]]; then
        stune_top_app 1 1
      elif [[ "$action" = "performance" ]]; then
        stune_top_app 1 1
      elif [[ "$action" = "fast" ]]; then
        stune_top_app 1 20
      fi
    ;;

    # XianYu, TaoBao, Browser, TieBa Fast, TieBa, JingDong, TianMao, Mei Tuan, PuPuChaoShi, Alipay, Google Play
    "com.taobao.idlefish" | "com.taobao.taobao" | "com.android.browser" | "com.baidu.tieba_mini" | "com.baidu.tieba" | "com.jingdong.app.mall" | "com.tmall.wireless" | "com.sankuai.meituan" | "com.pupumall.customer" | "com.eg.android.AlipayGphone"|"com.android.vending")
      if [[ "$action" = "powersave" ]]; then
        sched_limit 0 0 0 0
      elif [[ "$action" = "balance" ]]; then
        stune_top_app 0 0
      elif [[ "$action" = "performance" ]]; then
        stune_top_app 1 0
      elif [[ "$action" = "fast" ]]; then
        stune_top_app 1 20
      fi
    ;;

    # NeteaseCloudMusic, KuGou, KuGou Lite
    "com.netease.cloudmusic" | "com.kugou.android" | "com.kugou.android.lite")
      echo 0-6 > /dev/cpuset/foreground/cpus
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
  scene_scheduler "$top_app" "$action"
}
