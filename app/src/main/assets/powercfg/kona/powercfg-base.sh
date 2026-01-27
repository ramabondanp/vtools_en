#! /vendor/bin/sh

cfg_dir=$(cd $(dirname $0); pwd)

if [[ ! -f "$cfg_dir/powercfg-utils.sh" ]]; then
  echo "The dependent '$cfg_dir/powercfg-utils.sh' was not found !" > /cache/powercfg.sh.log
  exit 1
else
  source "$cfg_dir/powercfg-utils.sh"
fi

# Setting b.L scheduler parameters
# echo 95 95 > /proc/sys/kernel/sched_upmigrate
# echo 85 85 > /proc/sys/kernel/sched_downmigrate
# echo 100 > /proc/sys/kernel/sched_group_upmigrate
# echo 85 > /proc/sys/kernel/sched_group_downmigrate
# echo 1 > /proc/sys/kernel/sched_walt_rotate_big_tasks
# echo 400000000 > /proc/sys/kernel/sched_coloc_downmigrate_ns

# colocation v3 settings
# echo 51 > /proc/sys/kernel/sched_min_task_util_for_boost
# echo 35 > /proc/sys/kernel/sched_min_task_util_for_colocation

# Enable conservative pl
echo 1 > /proc/sys/kernel/sched_conservative_pl

echo N > /sys/module/lpm_levels/parameters/sleep_disabled

set_cpuset(){
  pgrep -f $1 | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    echo $pid > /dev/stune/$2/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuset/$2/tasks
    done
  done
}

governor_cover() {
  policy=/sys/devices/system/cpu/cpufreq/policy
  ls $policy | while read cluster; do
    hide_value ${policy}${cluster}/scaling_governor $1
  done
}

process_opt(){
  set_cpuset surfaceflinger top-app
  set_cpuset system_server top-app
  set_cpuset vendor.qti.hardware.display.composer-service top-app
  # set_cpuset mediaserver background
  # set_cpuset media.hwcodec background

  # echo 1 > /dev/stune/rt/schedtune.sched_boost_no_override
  # echo 1 > /dev/stune/rt/schedtune.prefer_idle
  # echo 0 > /dev/stune/rt/schedtune.boost
  # move_to_rt surfaceflinger
  # move_to_rt system_server
  # move_to_rt vendor.qti.hardware.display.composer-service
  # move_to_rt com.android.systemui
  # move_to_rt com.miui.home
  # move_to_rt com.omarea.vtools
  # move_to_rt com.omarea.gesture

  pidof com.android.systemui | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    # echo $pid > /dev/stune/$2/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      case $(cat /proc/$pid/task/$tid/comm) in
        "wmshell.anim"*)
          echo $tid > /dev/cpuset/top-app/tasks
          taskset -p f0 $tid > /dev/null
        ;;
      esac
      # echo $tid > /dev/cpuset/$2/tasks
    done
  done

  miui_home=$(pidof com.miui.home)
  if [[ "$miui_home" != "" ]]; then
    memcg=/dev/memcg
    mem_fg=$memcg/scene_fg
    if [[ -d $memcg ]] && [[ ! -e "$mem_fg" ]]; then
      mkdir -p $mem_fg
      echo 0 > $mem_fg/memory.swappiness
      echo 1 > $mem_fg/memory.oom_control
      echo 1 > $mem_fg/memory.use_hierarchy
      echo 1 >  $mem_fg/memory.move_charge_at_immigrate
    fi
    echo $miui_home > $mem_fg/cgroup.procs
  fi
}

move_to_rt() {
  pidof $1 | while read pid; do
    echo $pid > /dev/stune/rt/cgroup.procs
    echo $pid > /dev/cpuset/top-app/cgroup.procs
  done
}

disable_migt() {
  migt=/sys/module/migt/parameters
  if [[ -d $migt ]]; then
    hide_value $migt/migt_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
    hide_value $migt/glk_freq_limit_start '0'
    hide_value $migt/glk_freq_limit_walt '0'
    hide_value $migt/glk_maxfreq '0 0 0'
    hide_value $migt/glk_minfreq '300000 710400 844800'
    hide_value $migt/migt_ceiling_freq '0 0 0'
    hide_value $migt/glk_disable '1'
    hide_value $migt/mi_freq_enable '0'
    hide_value $migt/force_stask_to_big '0'
    hide_value $migt/glk_fbreak_enable '0'
    hide_value $migt/force_reset_runtime '0'
    hide_value $migt/enable_pkg_monitor '0'

    settings put secure speed_mode_enable 1
    chmod 000 $migt/*
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
core_ctl_preset() {
  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  echo 50 > $cpu7_core_ctl_dir/offline_delay_ms
  echo 1 > $cpu7_core_ctl_dir/not_preferred
  echo 1 > $cpu7_core_ctl_dir/max_cpus
  echo 0 > $cpu7_core_ctl_dir/min_cpus
  # echo 1 > $cpu7_core_ctl_dir/nr_prev_assist_thresh
  echo 1 > $cpu7_core_ctl_dir/task_thres
  echo 30 > $cpu7_core_ctl_dir/busy_down_thres
  echo 60 > $cpu7_core_ctl_dir/busy_up_thres
  # echo 1 > $cpu7_core_ctl_dir/enable

  cpu4_core_ctl_dir=/sys/devices/system/cpu/cpu4/core_ctl
  echo 50 > $cpu4_core_ctl_dir/offline_delay_ms
  echo 1 1 1 > $cpu4_core_ctl_dir/not_preferred
  echo 3 > $cpu4_core_ctl_dir/max_cpus
  echo 0 > $cpu4_core_ctl_dir/min_cpus
  # echo 4294967295 > $cpu4_core_ctl_dir/nr_prev_assist_thresh
  echo 3 > $cpu4_core_ctl_dir/task_thres
  echo 15 > $cpu4_core_ctl_dir/busy_down_thres
  echo 20 > $cpu4_core_ctl_dir/busy_up_thres
  # echo 1 > $cpu4_core_ctl_dir/enable

  cpu0_core_ctl_dir=/sys/devices/system/cpu/cpu0/core_ctl
  echo 50 > $cpu0_core_ctl_dir/offline_delay_ms
  echo 0 1 1 1 > $cpu0_core_ctl_dir/not_preferred
  echo 4 > $cpu0_core_ctl_dir/max_cpus
  echo 1 > $cpu0_core_ctl_dir/min_cpus
  # echo 4294967295 > $cpu0_core_ctl_dir/nr_prev_assist_thresh
  # echo 3 > $cpu0_core_ctl_dir/task_thres
  echo 15 > $cpu0_core_ctl_dir/busy_down_thres
  echo 20 > $cpu0_core_ctl_dir/busy_up_thres
  # echo 1 > $cpu0_core_ctl_dir/enable
}

hide_value /sys/class/kgsl/kgsl-3d0/devfreq/governor 'msm-adreno-tz'
echo "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0" > /sys/module/cpu_boost/parameters/input_boost_freq
echo 0 > /sys/module/cpu_boost/parameters/input_boost_ms
echo 0 > /sys/module/cpu_boost/parameters/sched_boost_on_input
for index in 0 1 2 3 4 5 6 7; do
  hide_value /sys/devices/system/cpu/cpu$index/online 1
done

set_value 8000000 /proc/sys/kernel/sched_latency_ns
set_value 2000000 /proc/sys/kernel/sched_min_granularity_ns

governor_cover schedutil
# hide_value /sys/module/msm_performance/parameters/cpu_max_freq '0:4294967295 1:4294967295 2:4294967295 3:4294967295 4:4294967295 5:4294967295 6:4294967295 7:4294967295'
# chattr +i  /sys/module/msm_performance/parameters/cpu_max_freq
# hide_value /sys/module/msm_performance/parameters/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
# chattr +i  /sys/module/msm_performance/parameters/cpu_min_freq

t_message=/sys/class/thermal/thermal_message
if [[ -f $t_message/cpu_limits ]]; then
  chmod 644 $t_message/cpu_limits
  for i in $(seq 0 7); do
    echo cpu$i 3300000 > $t_message/cpu_limits
  done
  chmod 444 $t_message/cpu_limits
fi
hide_value $t_message/market_download_limit 0
hide_value $t_message/cpu_nolimit_temp 47500
lock_value 0 /sys/module/aigov/parameters/enable

core_ctl_preset
disable_migt

process_opt &

uninstall_mi_opt() {
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

disable_mi_opt() {
  if [[ "$manufacturer" == "Xiaomi" ]]; then
    # pm disable com.xiaomi.gamecenter.sdk.service/.PidService 2>/dev/null
    pm disable com.xiaomi.joyose/.smartop.gamebooster.receiver.BoostRequestReceiver >/dev/null 2>&1
    pm disable com.xiaomi.joyose/.smartop.SmartOpService >/dev/null 2>&1
    # pm disable com.xiaomi.joyose.smartop.smartp.SmartPAlarmReceiver >/dev/null 2>&1
    pm disable com.xiaomi.joyose.sysbase.MetokClService >/dev/null 2>&1

    pm disable com.miui.daemon/.performance.cloudcontrol.CloudControlSyncService >/dev/null 2>&1
    pm disable com.miui.daemon/.performance.statistics.services.GraphicDumpService >/dev/null 2>&1
    pm disable com.miui.daemon/.performance.statistics.services.AtraceDumpService >/dev/null 2>&1
    pm disable com.miui.daemon/.performance.SysoptService >/dev/null 2>&1
    pm disable com.miui.daemon/.performance.MiuiPerfService >/dev/null 2>&1
    pm disable com.miui.daemon/.performance.server.ExecutorService >/dev/null 2>&1
    pm disable com.miui.daemon/.mqsas.jobs.EventUploadService >/dev/null 2>&1
    pm disable com.miui.daemon/.mqsas.jobs.FileUploadService >/dev/null 2>&1
    pm disable com.miui.daemon/.mqsas.jobs.HeartBeatUploadService >/dev/null 2>&1
    pm disable com.miui.daemon/.mqsas.providers.MQSProvider >/dev/null 2>&1
    pm disable com.miui.daemon/.performance.provider.PerfTurboProvider >/dev/null 2>&1
    pm disable com.miui.daemon/.performance.system.am.SysoptjobService >/dev/null 2>&1
    pm disable com.miui.daemon/.performance.system.am.MemCompactService >/dev/null 2>&1
    pm disable com.miui.daemon/.performance.statistics.services.FreeFragDumpService >/dev/null 2>&1
    pm disable com.miui.daemon/.performance.statistics.services.DefragService >/dev/null 2>&1
    pm disable com.miui.daemon/.performance.statistics.services.MeminfoService >/dev/null 2>&1
    pm disable com.miui.daemon/.performance.statistics.services.IonService >/dev/null 2>&1
    pm disable com.miui.daemon/.performance.statistics.services.GcBoosterService >/dev/null 2>&1
    pm disable com.miui.daemon/.mqsas.OmniTestReceiver >/dev/null 2>&1
    pm disable com.miui.daemon/.performance.MiuiPerfService >/dev/null 2>&1
    killall -9 com.miui.daemon >/dev/null 2>&1
  fi
}

# Disable MIUI's daemon\joyose
# disable_mi_opt &

# Uninstall MIUI's daemon\joyose
version=$(getprop ro.miui.ui.version.name)
if [[ "$varsion" == "V130" ]]; then
  # mi_joyose_opt &
  echo 'mi_joyose_opt'
elif [[ "$version" == "V12" ]]; then
  uninstall_mi_opt &
elif [[ "$version" == "V125" ]]; then
  uninstall_mi_opt &
  echo 'uninstall_mi_opt'
fi

# Reinstall MIUI's daemon\joyose
# reinstall_mi_opt &


# module=/data/adb/modules/scene_systemless
# module_system_etc=$module/system/etc
# module_vendor_etc=$module/system/vendor/etc

# if [[ -d $module ]]; then
#   mkdir -p $module_system_etc
#   mkdir -p $module_vendor_etc
#   if [[ -f $cfg_dir/task_profiles.json ]];then
#     cp $cfg_dir/task_profiles.json $module_vendor_etc/
#     cp $cfg_dir/task_profiles.json $module_system_etc/
#   fi
#   if [[ -f $cfg_dir/perfinit.conf ]];then
#     cp $cfg_dir/perfinit.conf $module_system_etc/
#   fi
# fi


# Fix Scene'[Magisk]SwapController Bugs
# resetprop persist.sys.lmk.camera_minfree_levels ''
lock_value 0 /proc/sys/vm/panic_on_oom

setprop persist.sys.miui_animator_sched.bigcores 4-7
