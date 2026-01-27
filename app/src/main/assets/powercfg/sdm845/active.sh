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

reset_basic_governor

governor_backup () {
  local governor_backup=/cache/governor_backup.prop
  local backup_state=`getprop vtools.dev_freq_backup`
  if [[ ! -f $governor_backup ]] || [[ "$backup_state" != "true" ]]; then
    echo '' > $governor_backup
    local dir=/sys/class/devfreq
    for file in `ls $dir | grep -v 'kgsl-3d0'`; do
      if [ -f $dir/$file/governor ]; then
        governor=`cat $dir/$file/governor`
        echo "$file#$governor" >> $governor_backup
      fi
    done
    setprop vtools.dev_freq_backup true
  fi
}

governor_performance () {
  governor_backup

  local dir=/sys/class/devfreq
  local governor_backup=/cache/governor_backup.prop
  local backup_state=`getprop vtools.dev_freq_backup`

  if [[ -f "$governor_backup" ]] && [[ "$backup_state" == "true" ]]; then
    for file in `ls $dir | grep -v 'kgsl-3d0'`; do
      if [ -f $dir/$file/governor ]; then
        # echo $dir/$file/governor
        echo performance > $dir/$file/governor
      fi
    done
  fi
}

governor_restore () {
  local governor_backup=/cache/governor_backup.prop
  local backup_state=`getprop vtools.dev_freq_backup`

  if [[ -f "$governor_backup" ]] && [[ "$backup_state" == "true" ]]; then
    local dir=/sys/class/devfreq
    while read line; do
      if [[ "$line" != "" ]]; then
        echo ${line#*#} > $dir/${line%#*}/governor
      fi
    done < $governor_backup
  fi
}

function schedutil_cfg()
{
  set_value $2 /sys/devices/system/cpu/cpu$1/cpufreq/schedutil/down_rate_limit_us
  set_value $3 /sys/devices/system/cpu/cpu$1/cpufreq/schedutil/up_rate_limit_us
  set_value $4 /sys/devices/system/cpu/cpu$1/cpufreq/schedutil/iowait_boost_enable
}

if [[ "$action" = "powersave" ]]; then
  sched_boost 0 0
  stune_top_app 0 0

  set_cpu_freq 5000 1516800 5000 1612800
  set_input_boost_freq 0 0 0
  set_hispeed_freq 1056000 652800

  echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
  echo 0-7 > /dev/cpuset/foreground/cpus

  ctl_on cpu0
  ctl_on cpu4
  sched_config 85 96 380 500
  sched_limit 0 500 0 1000
  governor_restore

elif [[ "$action" = "balance" ]]; then
  sched_boost 0 0
  stune_top_app 0 0

  set_cpu_freq 5000 1766400 5000 2323200
  set_input_boost_freq 0 0 0
  set_hispeed_freq 1478400 1056000

  echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
  echo 0-7 > /dev/cpuset/foreground/cpus

  ctl_off cpu0
  ctl_on cpu4
  sched_config 70 85 300 400
  sched_limit 0 0 0 1000
  governor_restore

elif [[ "$action" = "performance" ]]; then
  sched_boost 1 0
  stune_top_app 1 0

  set_cpu_freq 5000 1766400 5000 2649600
  set_input_boost_freq 0 0 0
  set_hispeed_freq 1478400 1267200

  echo `expr $gpu_min_pl - 1` > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
  echo 0-7 > /dev/cpuset/foreground/cpus

  ctl_off cpu0
  ctl_off cpu4
  sched_config 60 78 300 400
  sched_limit 1000 0 0 0
  governor_performance

elif [[ "$action" = "fast" ]]; then
  sched_boost 1 2
  stune_top_app 1 30

  set_cpu_freq 1516800 2500000 1267200 3500000
  set_input_boost_freq 0 0 0
  set_hispeed_freq 0 0

  echo `expr $gpu_min_pl - 2` > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
  echo 0-7 > /dev/cpuset/foreground/cpus

  ctl_off cpu0
  ctl_off cpu4
  sched_config 57 75 300 400
  sched_limit 3000 2000 0 0
  governor_performance

elif [[ "$action" = "pedestal" ]]; then
  sched_boost 1 2
  stune_top_app 1 100

  set_cpu_freq 1766400 1766400 2649600 3500000
  set_input_boost_freq 0 0 0
  set_hispeed_freq 0 0

  echo `expr $gpu_min_pl - 4` > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
  echo 0-7 > /dev/cpuset/foreground/cpus

  ctl_off cpu0
  ctl_off cpu4
  sched_config 57 75 300 400
  sched_limit 8000 8000 0 0
  governor_performance

fi

adjustment_by_top_app
