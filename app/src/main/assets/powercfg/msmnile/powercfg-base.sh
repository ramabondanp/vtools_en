#! /vendor/bin/sh

target=`getprop ro.board.platform`

chmod 0755 /sys/devices/system/cpu/cpu0/online
chmod 0755 /sys/devices/system/cpu/cpu1/online
chmod 0755 /sys/devices/system/cpu/cpu2/online
chmod 0755 /sys/devices/system/cpu/cpu3/online
chmod 0755 /sys/devices/system/cpu/cpu4/online
chmod 0755 /sys/devices/system/cpu/cpu5/online
chmod 0755 /sys/devices/system/cpu/cpu6/online
chmod 0755 /sys/devices/system/cpu/cpu7/online

# Core control parameters for gold
echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
echo 60 > /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres
echo 30 > /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres
echo 100 > /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms
echo 3 > /sys/devices/system/cpu/cpu4/core_ctl/task_thres

# Core control parameters for gold+
echo 0 > /sys/devices/system/cpu/cpu7/core_ctl/min_cpus
echo 60 > /sys/devices/system/cpu/cpu7/core_ctl/busy_up_thres
echo 30 > /sys/devices/system/cpu/cpu7/core_ctl/busy_down_thres
echo 100 > /sys/devices/system/cpu/cpu7/core_ctl/offline_delay_ms
echo 1 > /sys/devices/system/cpu/cpu7/core_ctl/task_thres

# Controls how many more tasks should be eligible to run on gold CPUs
# w.r.t number of gold CPUs available to trigger assist (max number of
# tasks eligible to run on previous cluster minus number of CPUs in
# the previous cluster).
#
# Setting to 1 by default which means there should be at least
# 4 tasks eligible to run on gold cluster (tasks running on gold cores
# plus misfit tasks on silver cores) to trigger assitance from gold+.
echo 1 > /sys/devices/system/cpu/cpu7/core_ctl/nr_prev_assist_thresh

# Disable Core control on silver
echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable

# hide_value /sys/module/task_turbo/parameters/feats [write_value]
hide_value() {
  if [[ -e "$1" ]]; then
    umount "$1" 2>/dev/null
    c_path="/cache${1}"
    if [[ ! -f "$c_path" ]]; then
      mkdir -p "$c_path"
      rm -r "$c_path"
      cat "$1" > "$c_path"
    fi
    if [[ "$2" != "" ]]; then
      lock_value "$2" "$1"
    fi
    mount "$c_path" "$1"
  fi
}
sdk_version=$(getprop ro.build.version.sdk)
if [[ $sdk_version -gt 29 ]] || [[ $(getprop ro.product.vendor.brand) == "google" ]] || [[ ! -f /proc/sys/kernel/sched_group_upmigrate ]]; then
  # Setting b.L scheduler parameters
  hide_value /proc/sys/kernel/sched_upmigrate
  hide_value /proc/sys/kernel/sched_downmigrate
  hide_value /proc/sys/kernel/sched_group_upmigrate
  hide_value /proc/sys/kernel/sched_group_downmigrate
  hide_value /proc/sys/kernel/sched_walt_rotate_big_tasks
else
  # Setting b.L scheduler parameters
  echo 95 95 > /proc/sys/kernel/sched_upmigrate
  echo 85 85 > /proc/sys/kernel/sched_downmigrate
  echo 100 > /proc/sys/kernel/sched_group_upmigrate
  echo 95 > /proc/sys/kernel/sched_group_downmigrate
  echo 1 > /proc/sys/kernel/sched_walt_rotate_big_tasks
fi
# cpuset parameters
echo 0-2     > /dev/cpuset/background/cpus
echo 0-3     > /dev/cpuset/system-background/cpus
echo 4-7     > /dev/cpuset/foreground/boost/cpus
echo 0-7 > /dev/cpuset/foreground/cpus
echo 0-7     > /dev/cpuset/top-app/cpus

# Turn off scheduler boost at the end
echo 0 > /proc/sys/kernel/sched_boost

# Turn on scheduler boost for top app main
echo 1 > /proc/sys/kernel/sched_boost_top_app

echo 1 > /sys/devices/system/cpu/cpu0/online
echo 1 > /sys/devices/system/cpu/cpu1/online
echo 1 > /sys/devices/system/cpu/cpu2/online
echo 1 > /sys/devices/system/cpu/cpu3/online
echo 1 > /sys/devices/system/cpu/cpu4/online
echo 1 > /sys/devices/system/cpu/cpu5/online
echo 1 > /sys/devices/system/cpu/cpu6/online
echo 1 > /sys/devices/system/cpu/cpu7/online

echo 0 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
echo 5 > /proc/sys/vm/dirty_background_ratio
echo 50 > /proc/sys/vm/overcommit_ratio
echo 100 > /proc/sys/vm/swap_ratio
echo 100 > /proc/sys/vm/vfs_cache_pressure
echo 20 > /proc/sys/vm/dirty_ratio
echo 3 > /proc/sys/vm/page-cluster
echo 2000 > /proc/sys/vm/dirty_expire_centisecs
echo 5000 > /proc/sys/vm/dirty_writeback_centisecs

# killall -9 vendor.qti.hardware.perf@1.0-service

set_cpuset(){
  pgrep -f $1 | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    echo $pid > /dev/stune/$2/cgroup.procs
  done
}

process_opt(){
  set_cpuset surfaceflinger top-app
  set_cpuset system_server top-app
  set_cpuset vendor.qti.hardware.display.composer-service top-app
  # set_cpuset mediaserver background
  # set_cpuset media.hwcodec background

  set_task_affinity `pgrep com.miui.home` 11111111
  set_task_affinity `pgrep com.miui.home` 11110000
}

set_value 40000000 /proc/sys/kernel/sched_latency_ns
set_value 1000000 /proc/sys/kernel/sched_min_granularity_ns

process_opt &

