#!/system/bin/sh

action=$1

init () {
  local dir=$(cd $(dirname $0); pwd)
  if [[ -f "$dir/powercfg-base.sh" ]]; then
    sh "$dir/powercfg-base.sh"
  elif [[ -f '/data/powercfg-base.sh' ]]; then
    sh /data/powercfg-base.sh
  fi
}
if [[ "$action" = "init" ]]; then
  init
	exit 0
fi

stop perfd

echo 0 > /sys/module/msm_thermal/core_control/enabled
echo 0 > /sys/module/msm_thermal/vdd_restriction/enabled
echo N > /sys/module/msm_thermal/parameters/enabled

governor0=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`
governor6=`cat /sys/devices/system/cpu/cpu6/cpufreq/scaling_governor`

if [ ! "$governor0" = "schedutil" ]; then
	echo 'schedutil' > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
fi
if [ ! "$governor6" = "schedutil" ]; then
	echo 'schedutil' > /sys/devices/system/cpu/cpu6/cpufreq/scaling_governor
fi

governor_backup () {
  local governor_backup=/cache/governor_backup.prop
  if [[ ! -f $governor_backup ]]; then
    echo '' > $governor_backup
    local dir=/sys/class/devfreq
    for file in `ls $dir`; do
      if [ -f $dir/$file/governor ]; then
        governor=`cat $dir/$file/governor`
        echo "$file#$governor" >> $governor_backup
      fi
    done
  fi
}

governor_performance () {
  governor_backup
  local dir=/sys/class/devfreq
  for file in `ls $dir`; do
    if [ -f $dir/$file/governor ]; then
      echo $dir/$file/governor
      echo performance > $dir/$file/governor
    fi
  done
}

governor_restore () {
  local governor_backup=/cache/governor_backup.prop
  local dir=/sys/class/devfreq
  if [[ -f "$governor_backup" ]]; then
      while read line; do
        if [[ "$line" != "" ]]; then
            echo ${line#*#} > $dir/${line%#*}/governor
        fi
      done < /cache/governor_backup.prop
  fi
}

set_value()
{
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

# GPU频率表
gpu_freqs=`cat /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies`
# GPU最大频率
gpu_max_freq='700000000'
# GPU最小频率
gpu_min_freq='180000000'
# GPU最小 power level
gpu_min_pl=6
# GPU最大 power level
gpu_max_pl=0
# GPU默认 power level
gpu_default_pl=`cat /sys/class/kgsl/kgsl-3d0/default_pwrlevel`
# GPU型号
gpu_model=`cat /sys/class/kgsl/kgsl-3d0/gpu_model`
# GPU调度器
gpu_governor=`cat /sys/class/kgsl/kgsl-3d0/devfreq/governor`

# MaxFrequency、MinFrequency
for freq in $gpu_freqs; do
    if [[ $freq -gt $gpu_max_freq ]]; then
        gpu_max_freq=$freq
    fi;
    if [[ $freq -lt $gpu_min_freq ]]; then
        gpu_min_freq=$freq
    fi;
done

# Power Levels
if [[ -f /sys/class/kgsl/kgsl-3d0/num_pwrlevels ]];then
    gpu_min_pl=`cat /sys/class/kgsl/kgsl-3d0/num_pwrlevels`
    gpu_min_pl=`expr $gpu_min_pl - 1`
fi;
if [[ "$gpu_min_pl" -lt 0 ]];then
    gpu_min_pl=0
fi;

if [ ! "$gpu_governor" = "msm-adreno-tz" ]; then
	echo 'msm-adreno-tz' > /sys/class/kgsl/kgsl-3d0/devfreq/governor
fi

echo $gpu_max_freq > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
echo $gpu_min_freq > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
echo $gpu_max_pl > /sys/class/kgsl/kgsl-3d0/max_pwrlevel

# Setting b.L scheduler parameters
# default sched up and down migrate values are 90 and 85
# echo 65 > /proc/sys/kernel/sched_downmigrate
# echo 71 > /proc/sys/kernel/sched_upmigrate
# default sched up and down migrate values are 100 and 95
# echo 85 > /proc/sys/kernel/sched_group_downmigrate
# echo 100 > /proc/sys/kernel/sched_group_upmigrate

set_cpu_freq()
{
    echo $1 $2 $3 $4
	echo "0:$2 1:$2 2:$2 3:$2 4:$4 5:$4 6:$4 7:$4" > /sys/module/msm_performance/parameters/cpu_max_freq
	echo $1 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	echo $2 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
	echo $3 > /sys/devices/system/cpu/cpu6/cpufreq/scaling_min_freq
	echo $4 > /sys/devices/system/cpu/cpu6/cpufreq/scaling_max_freq
}

set_input_boost_freq() {
    local c0="$1"
    local c1="$2"
    local ms="$3"
    echo "0:$c0 1:$c0 2:$c0 3:$c0 4:$c0 5:$c0 6:$c1 7:$c1" > /sys/module/cpu_boost/parameters/input_boost_freq
	echo $ms > /sys/module/cpu_boost/parameters/input_boost_ms
}

sched_config() {
    echo "$1" > /proc/sys/kernel/sched_downmigrate
    echo "$2" > /proc/sys/kernel/sched_upmigrate
    echo "$1" > /proc/sys/kernel/sched_downmigrate
    echo "$2" > /proc/sys/kernel/sched_upmigrate

    echo "$3" > /proc/sys/kernel/sched_group_downmigrate
    echo "$4" > /proc/sys/kernel/sched_group_upmigrate
    echo "$3" > /proc/sys/kernel/sched_group_downmigrate
    echo "$4" > /proc/sys/kernel/sched_group_upmigrate
}

if [ "$action" = "powersave" ]; then
	set_cpu_freq 5000 1612800 5000 1555200
	set_input_boost_freq 0 0 0

	echo 1248000 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq
	echo 825600 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/hispeed_freq

	echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
	echo 0 > /proc/sys/kernel/sched_boost

  echo 1 > /sys/devices/system/cpu/cpu0/core_ctl/enable
  echo 1 > /sys/devices/system/cpu/cpu6/core_ctl/enable

  sched_config 75 92 380 500

  echo 0 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
  echo 0 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/down_rate_limit_us
  echo 500 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
  echo 1000 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/up_rate_limit_us

  governor_restore

elif [ "$action" = "balance" ]; then
	set_cpu_freq 5000 1708800 5000 1843200
	set_input_boost_freq 1324800 0 40

	echo 1248000 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq
	echo 1209600 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/hispeed_freq

	echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
	echo 0 > /proc/sys/kernel/sched_boost

  echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable
  echo 1 > /sys/devices/system/cpu/cpu6/core_ctl/enable

  sched_config 68 82 300 400

  echo 0 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
  echo 0 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/down_rate_limit_us
  echo 0 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
  echo 0 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/up_rate_limit_us

  governor_restore

elif [ "$action" = "performance" ]; then
	set_cpu_freq 300000 2500000 300000 2750000
	set_input_boost_freq 1324800 1555200 40

  echo 1708800 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq
  echo 1209600 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/hispeed_freq

	echo `expr $gpu_min_pl - 1` > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
	echo 0 > /proc/sys/kernel/sched_boost

  echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable
  echo 0 > /sys/devices/system/cpu/cpu6/core_ctl/enable

  sched_config 60 80 300 400

  echo 2000 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
  echo 1000 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/down_rate_limit_us
  echo 0 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
  echo 0 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/up_rate_limit_us

  governor_restore

elif [ "$action" = "fast" ]; then
	set_cpu_freq 1708800 2500000 1209600 2750000
	set_input_boost_freq 1804800 1939200 120

	echo 300000 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq
	echo 300000 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/hispeed_freq

	echo `expr $gpu_min_pl - 2` > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
	echo 1 > /proc/sys/kernel/sched_boost

  echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable
  echo 0 > /sys/devices/system/cpu/cpu6/core_ctl/enable

  sched_config 50 78 300 400

  echo 5000 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
  echo 2000 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/down_rate_limit_us
  echo 0 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
  echo 0 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/up_rate_limit_us

  governor_performance
fi
