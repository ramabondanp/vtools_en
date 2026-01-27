target=`getprop ro.board.platform`

# Setting b.L scheduler parameters
# echo 95 95 > /proc/sys/kernel/sched_upmigrate
# echo 85 85 > /proc/sys/kernel/sched_downmigrate
# echo 100 > /proc/sys/kernel/sched_group_upmigrate
# echo 85 > /proc/sys/kernel/sched_group_downmigrate
# echo 1 > /proc/sys/kernel/sched_walt_rotate_big_tasks
# echo 400000000 > /proc/sys/kernel/sched_coloc_downmigrate_ns

# configure input boost settings
# echo "0:1708800" > /sys/devices/system/cpu/cpu_boost/input_boost_freq
# echo 120 > /sys/devices/system/cpu/cpu_boost/input_boost_ms
echo "0:1401600 1:0 2:0 3:0 4:2342400 5:0 6:0 7:2496000" > /sys/devices/system/cpu/cpu_boost/powerkey_input_boost_freq
echo 400 > /sys/devices/system/cpu/cpu_boost/powerkey_input_boost_ms

echo "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0" > /sys/module/msm_performance/parameters/cpu_min_freq

echo N > /sys/module/lpm_levels/parameters/sleep_disabled

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

    settings put secure speed_mode_enable 1
    chmod 000 $migt/*
  fi

  glk=/proc/sys/glk
  if [[ -d $glk ]]; then
    hide_value $migt/glk_disable '1'
    hide_value $migt/freq_break_enable '0'
    hide_value $migt/game_minfreq_limit '0 0 0'
    hide_value $migt/game_maxfreq_limit '0 0 0'
    hide_value $migt/game_lowspeed_load '30 30 30'
    hide_value $migt/game_hispeed_load '80 80 80'
  fi

  migt=/proc/sys/migt
  if [[ -d $migt ]]; then
    hide_value $migt/force_stask_tob '0'
    hide_value $migt/enable_pkg_monitor '0'
    hide_value $migt/boost_pid '0'
  fi
}
core_ctl_preset(){
  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  echo 10 > $cpu7_core_ctl_dir/offline_delay_ms
  echo 1 > $cpu7_core_ctl_dir/not_preferred
  # echo 1 > $cpu7_core_ctl_dir/enable
  echo 1 > $cpu7_core_ctl_dir/max_cpus
  echo 0 > $cpu7_core_ctl_dir/min_cpus
  # echo 1 > $cpu7_core_ctl_dir/nr_prev_assist_thresh
  echo 1 > $cpu7_core_ctl_dir/task_thres
  echo 27 > $cpu7_core_ctl_dir/busy_down_thres
  echo 50 > $cpu7_core_ctl_dir/busy_up_thres

  cpu4_core_ctl_dir=/sys/devices/system/cpu/cpu4/core_ctl
  echo 20 > $cpu4_core_ctl_dir/offline_delay_ms
  echo 1 > $cpu4_core_ctl_dir/not_preferred
  # echo 1 > $cpu4_core_ctl_dir/enable
  echo 3 > $cpu4_core_ctl_dir/max_cpus
  echo 0 > $cpu4_core_ctl_dir/min_cpus
  # echo 4294967295 > $cpu4_core_ctl_dir/nr_prev_assist_thresh
  echo 3 > $cpu4_core_ctl_dir/task_thres
  echo 20 > $cpu4_core_ctl_dir/busy_down_thres
  echo 35 > $cpu4_core_ctl_dir/busy_up_thres

  cpu0_core_ctl_dir=/sys/devices/system/cpu/cpu0/core_ctl
  echo 100 > $cpu0_core_ctl_dir/offline_delay_ms
  echo 0 1 1 1 > $cpu0_core_ctl_dir/not_preferred
  # echo 1 > $cpu0_core_ctl_dir/enable
  echo 4 > $cpu0_core_ctl_dir/max_cpus
  echo 1 > $cpu0_core_ctl_dir/min_cpus
  # echo 4294967295 > $cpu0_core_ctl_dir/nr_prev_assist_thresh
  # echo 3 > $cpu0_core_ctl_dir/task_thres
  echo 10 > $cpu0_core_ctl_dir/busy_down_thres
  echo 20 > $cpu0_core_ctl_dir/busy_up_thres

  echo 0 > /sys/devices/system/cpu/hang_detect_core/enable
  echo 0 > /sys/devices/system/cpu/hyp_core_ctl/enable
}

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

move_to_heavy() {
  pidof $1 | while read pid; do
    echo $pid > /dev/stune/top-app/heavy/cgroup.procs
    echo $pid > /dev/cpuctl/heavy/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuctl/heavy/tasks
    done
  done
}

governor_cover() {
  policy=/sys/devices/system/cpu/cpufreq/policy
  ls $policy | while read cluster; do
    hide_value ${policy}${cluster}/scaling_governor $1
  done
}

process_opt() {
  set_cpuset surfaceflinger top-app
  set_cpuset system_server top-app
  set_cpuset vendor.qti.hardware.display.composer-service top-app

  move_to_heavy vendor.qti.hardware.display.composer-service
  move_to_heavy com.android.systemui
  move_to_heavy com.miui.home
  move_to_heavy surfaceflinger
  move_to_heavy system_server
  move_to_heavy com.omarea.vtools
  move_to_heavy com.omarea.gesture

  # set_cpuset mediaserver background
  # set_cpuset media.hwcodec background

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

# cpuctl top-app 0 0 0 max
# cpuctl foreground 0 0 0 max
# cpuctl background 0 0 0 max
mk_cpuctl 'heavy' 1 0 1 max
mk_stune 'top-app/heavy' 0 0

# echo 0 > /dev/stune/nnapi-hal/schedtune.boost
# echo 0 > /dev/stune/nnapi-hal/schedtune.prefer_idle

set_value 8000000 /proc/sys/kernel/sched_latency_ns
set_value 2000000 /proc/sys/kernel/sched_min_granularity_ns

disable_migt
core_ctl_preset

hide_value /sys/class/kgsl/kgsl-3d0/devfreq/governor 'msm-adreno-tz'
echo "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0" > /sys/module/cpu_boost/parameters/input_boost_freq
echo 0 > /sys/module/cpu_boost/parameters/input_boost_ms
echo 0 > /sys/module/cpu_boost/parameters/sched_boost_on_input
for index in 0 1 2 3 4 5 6; do
  hide_value /sys/devices/system/cpu/cpu$index/online 1
done

# governor_cover schedutil
# echo '0:4294967295 1:4294967295 2:4294967295 3:4294967295 4:4294967295 5:4294967295 6:4294967295 7:4294967295' > /sys/module/msm_performance/parameters/cpu_max_freq 
# echo '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0' > /sys/module/msm_performance/parameters/cpu_min_freq 

t_message=/sys/class/thermal/thermal_message
if [[ -f $t_message/cpu_limits ]]; then
  for i in $(seq 0 7); do
    echo cpu$i 3300000 > $t_message/cpu_limits
  done
  chmod 444 $t_message/cpu_limits
fi
hide_value $t_message/market_download_limit 0
hide_value $t_message/cpu_nolimit_temp 47500
lock_value 0 /sys/module/aigov/parameters/enable

echo 128 > /dev/cpuctl/background/cpu.shares
echo 128 > /dev/cpuctl/system-background/cpu.shares
echo 512 > /dev/cpuctl/foreground/cpu.shares

for group in top-app
do
  echo 0 > /dev/cpuctl/$group/cpu.uclamp.latency_sensitive
  echo 1 > /dev/cpuctl/$group/cpu.uclamp.sched_boost_no_override
done

for group in system ui foreground background system-background
do
  echo 0 > /dev/cpuctl/$group/cpu.uclamp.latency_sensitive
  echo 0 > /dev/cpuctl/$group/cpu.uclamp.sched_boost_no_override
done

# Fix Scene'[Magisk]SwapController Bugs
# resetprop persist.sys.lmk.camera_minfree_levels ''
lock_value 0 /proc/sys/vm/panic_on_oom

# echo libunity.so, libfb.so > /proc/sys/kernel/sched_lib_name
# echo 240 > /proc/sys/kernel/sched_lib_mask_force

process_opt &

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

joyose_db='/data/data/com.xiaomi.joyose/databases/SmartP.db'
joyose_dfps_clear() {
  params='{"header":{"version":"2022121231","network_improve":true,"index_enable":true,"mqs_enable":true},"game_booster":{"booster_enable":true,"cpuset_enable":true,"tuner_enable":true,"monitor":{"monitor_enable":false,"analytics_enable":false,"default_interval":2},"support_motor_app":[],"support_display_refresh_rates":[60,90,120],"support_dynamic_refresh_rate_games":[],"support_highfps_app":[],"scale_app_enable":false,"support_scale_app_list":[],"support_gdpvo_app":[],"support_gt_app":[],"dynamic_fps_global":{"dynamic_fps":"10:120,30:120,35:120,38:120,50:90,52:60","dynamic_fps_M":"10:120,35:120,50:90,52:60"},"migt":[],"booster_config":{"default_config":[],"scene_config":[],"ovrride_config":[]}}}'
  sqlite3 $joyose_db "update cloud_config set params = '$params' where config_name = 'booster_config'"
}
mi_joyose_opt() {
  joyose_opt_ok=0
  if [[ ! -f $joyose_db ]]; then
    # echo 'Joyose Uninstalled!' 1>&2
    joyose_opt_ok=0
  elif [[ $(type sqlite3 | grep  "/sqlite3") == "" ]];then
    if [[ -d "$TOOLKIT" ]];then
      wget -O "$TOOLKIT/sqlite3" https://vtools.oss-cn-beijing.aliyuncs.com/addin/sqlite3 2>/dev/null
      s=`du -k "$TOOLKIT/sqlite3"|awk '{print $1}'`
      if [[ "$s" -gt 256 ]]; then
        chmod 777 "$TOOLKIT/sqlite3" 2>/dev/null
        joyose_opt_ok=1
      else
        rm "$TOOLKIT/sqlite3" 2>/dev/null
        # echo 'Download failed!' 1>&2
        joyose_opt_ok=2
      fi
    else
      # echo 'Sqlite3 binary is required!' 1>&2
      joyose_opt_ok=3
    fi
  else
    joyose_opt_ok=1
  fi
  # echo $joyose_opt_ok > /cache/joyose_opt_ok.log
  if [[ "$joyose_opt_ok" == 1 ]];then
    joyose_dfps_clear
  else
    echo 'Skip ...' $joyose_opt_ok
  fi
}

# Uninstall MIUI's daemon\joyose
version=$(getprop ro.miui.ui.version.name)
if [[ "$version" == "V130" ]]; then
  mi_joyose_opt &
  # echo 'mi_joyose_opt'
elif [[ "$version" == "V12" ]]; then
  uninstall_mi_opt &
elif [[ "$version" == "V125" ]]; then
  # uninstall_mi_opt &
  echo 'uninstall_mi_opt'
fi

setprop persist.sys.miui_animator_sched.bigcores 4-7
