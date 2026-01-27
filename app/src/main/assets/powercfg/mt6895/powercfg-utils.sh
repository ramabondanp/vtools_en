realme_gt() {
  gt_switch=$(settings get system scene_gt_switch)
  if [[ "$gt_switch" != "1" ]]; then
    return
  fi
  gt=$(settings get system gt_mode_state_setting)
  if [[ "$gt" == "1" || "$gt" == "0" ]] && [[ "$gt" != "$1" ]]; then
    if [[ "$1" == "1" ]]; then
      # GT ON
      action='open'
    elif [[ "$1" == "0" ]]; then
      # GT OFF
      action='close'
    else
      return
    fi
    gt_receiver='com.coloros.oppoguardelf/com.coloros.performance.GTModeBroadcastReceiver'
    # am broadcast -a gt_mode_broadcast_intent_${action}_action -n $gt_receiver -f 0x01000000
    if [[ -n $(pm query-receivers --brief -n $gt_receiver | grep $gt_receiver) ]]; then
      am broadcast -a gt_mode_broadcast_intent_${action}_action -n $gt_receiver -f 0x01000000
    else
      am broadcast -a gt_mode_broadcast_intent_${action}_action -f 0x01000000
    fi
  fi
}

reset_basic_governor() {
  stop_scene_scheduler

  # CPU
  governor0=`cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor`
  governor4=`cat /sys/devices/system/cpu/cpufreq/policy4/scaling_governor`
  governor7=`cat /sys/devices/system/cpu/cpufreq/policy7/scaling_governor`

  if [[ ! "$governor0" = "schedutil" ]]; then
    echo 'schedutil' > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
  fi
  if [[ ! "$governor4" = "schedutil" ]]; then
    echo 'schedutil' > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor
  fi
  if [[ ! "$governor7" = "schedutil" ]]; then
    echo 'schedutil' > /sys/devices/system/cpu/cpufreq/policy7/scaling_governor
  fi
}

joyose_db='/data/data/com.xiaomi.joyose/databases/SmartP.db'
joyose_dfps_clear() {
  params='{"header":{"version":"2022121231","network_improve":true,"index_enable":true,"mqs_enable":true},"game_booster":{"booster_enable":false,"cpuset_enable":false,"tuner_enable":false,"monitor":{"monitor_enable":false,"analytics_enable":false,"default_interval":2},"support_motor_app":[],"support_display_refresh_rates":[60,90,120],"support_dynamic_refresh_rate_games":[],"support_highfps_app":[],"scale_app_enable":false,"support_scale_app_list":[],"support_gdpvo_app":[],"support_gt_app":[],"dynamic_fps_global":{"dynamic_fps":"10:120,30:120,35:120,38:120,50:90,52:60","dynamic_fps_M":"10:120,35:120,50:90,52:60"},"migt":[],"booster_config":{"default_config":[],"scene_config":[],"ovrride_config":[]}}}'
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
  # rm /data/system/mcd/*
  if [[ -e /data/system/mcd ]]; then
    if [[ -f /data/system/mcd/migl ]]; then
      chmod 666 /data/system/mcd/migl
    fi
    echo -n '' > /data/system/mcd/migl
    echo 'yuanshen 1600 720 -1' >> /data/system/mcd/migl
    echo 'pubg -1 -1 -1' >> /data/system/mcd/migl
    chmod 444 /data/system/mcd/migl
    if [[ -e /data/system/mcd/df ]]; then
      chattr -i /data/system/mcd/df
      rm /data/system/mcd/df
      echo '' > /data/system/mcd/df
      chattr +i /data/system/mcd/df
    fi
  fi
  if [[ -e /data/system/migt/migt ]]; then
    rm -rf /data/system/migt/migt
  fi
  echo 0 > /sys/module/mtk_fpsgo/parameters/max_freq_limit_level
  echo 0 > /sys/module/mtk_fpsgo/parameters/min_freq_limit_level
  echo 10 > /sys/module/mtk_fpsgo/parameters/variance
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

cpuctl () {
  # echo $2 > /dev/cpuctl/$1/cpu.uclamp.sched_boost_no_override
  echo $3 > /dev/cpuctl/$1/cpu.uclamp.latency_sensitive
  echo $4 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $5 > /dev/cpuctl/$1/cpu.uclamp.max
  echo $4 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $5 > /dev/cpuctl/$1/cpu.uclamp.max
}
mk_cpuctl () {
  mkdir -p "/dev/cpuctl/$1"
  # echo $2 > /dev/cpuctl/$1/cpu.uclamp.sched_boost_no_override
  echo $3 > /dev/cpuctl/$1/cpu.uclamp.latency_sensitive
  echo $4 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $5 > /dev/cpuctl/$1/cpu.uclamp.max
  echo $4 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $5 > /dev/cpuctl/$1/cpu.uclamp.max
}

cpuset() {
  echo $1 > /dev/cpuset/background/cpus
  echo $2 > /dev/cpuset/system-background/cpus
  echo $3 > /dev/cpuset/foreground/cpus
  echo $4 > /dev/cpuset/top-app/cpus
  # Mi
  set_value 0-7 /dev/cpuset/game/cpus
  set_value 0-7 /dev/cpuset/gamelite/cpus
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
      cat "$1" > "$c_path"
    fi
    if [[ "$2" != "" ]]; then
      lock_value "$2" "$1"
    fi
    mount "$c_path" "$1"
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

tcp_low_latency() {
  if [[ "$1" == '1' ]]; then
    echo 1 > /proc/sys/net/ipv4/tcp_low_latency
    echo 0 > /proc/sys/net/ipv4/tcp_slow_start_after_idle
  else
    echo 0 > /proc/sys/net/ipv4/tcp_low_latency
    echo 1 > /proc/sys/net/ipv4/tcp_slow_start_after_idle
  fi
}

set_cpuset(){
  pidof $1 | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    # echo $pid > /dev/stune/$2/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuset/$2/tasks
    done
  done
}

move_to_heavy() {
  pidof $1 | while read pid; do
    # echo $pid > /dev/stune/top-app/heavy/cgroup.procs
    echo $pid > /dev/cpuctl/heavy/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuctl/heavy/tasks
    done
  done
}

process_renice() {
  pidof $1 | while read pid; do
    renice -n $2 $pid
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
  scene_scheduler "$top_app" "$action"
}
