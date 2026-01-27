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

if [[ "$action" = "powersave" ]]; then
  set_cpu_freq 300000 1708800 710400 1555200 844800 1785600
  sched_boost 0 0
  sched_config "85 75" "96 86" "150" "400"
  sched_limit 0 2000 0 5000 0 1000
  stune_top_app 0 0
  cpuset '0-2' '0-3' '0-6' '0-7'
  cpuctl foreground 0 max
  cpuctl background 0 0
  cpuctl top-app 0 max
  bw_min
  # bw_down 2 2
  bw_max
  set_hispeed_freq 1209600 960000 960000
  set_hispeed_load 88 90 80
  set_cpu_pl 0
  # tcp_low_latency 0
  realme_gt_on=0
  set_input_boost_freq 0 0 0 0

elif [[ "$action" = "balance" ]]; then
  set_cpu_freq 300000 1804800 710400 1881600 844800 2035200
  sched_boost 1 0
  sched_config "78 75" "89 86" "150" "400"
  sched_limit 0 0 0 500 0 500
  stune_top_app 0 0
  cpuset '0-2' '0-3' '0-6' '0-7'
  cpuctl foreground 0 max
  cpuctl background 0 max
  cpuctl top-app 0 max
  bw_min
  # bw_down 1 1
  bw_max
  set_hispeed_freq 1497600 1075200 1075200
  set_hispeed_load 85 90 80
  set_cpu_pl 0
  # tcp_low_latency 0
  realme_gt_on=0
  set_input_boost_freq 1094400 844800 844800 40

elif [[ "$action" = "performance" ]]; then
  set_cpu_freq 300000 1804800 710400 2419200 825600 2841600
  sched_boost 1 0
  sched_config "65 65" "75 78" "200" "400"
  sched_limit 0 0 0 0 0 0
  cpuset '0-1' '0-3' '0-6' '0-7'
  cpuctl foreground 0.25 max
  cpuctl background 0 1
  cpuctl top-app 0.25 max
  if [[ "$a12" == true ]]; then
    stune_top_app 0 0
  else
    stune_top_app 1 0
  fi
  bw_min
  bw_max
  set_hispeed_freq 1612800 1555200 1670400
  set_hispeed_load 75 80 80
  set_cpu_pl 1
  # tcp_low_latency 0
  realme_gt_on=1
  set_input_boost_freq 1209600 1075200 844800 80

elif [[ "$action" = "fast" ]]; then
  set_cpu_freq 1401600 1804800 1440000 2600000 1555200 3200000
  sched_boost 1 0
  sched_config "62 40" "70 52" "300" "400"
  if [[ "$a12" == true ]]; then
    bw_min
    bw_max
    stune_top_app 0 0
  else
    stune_top_app 1 20
    bw_max_always
  fi
  sched_limit 0 0 0 0 0 0
  cpuset '0' '0-3' '0-6' '0-7'
  cpuctl foreground 0.5 max
  cpuctl background 0 max
  cpuctl top-app 0.5 max
  set_hispeed_freq 1804800 1881600 2035200
  set_hispeed_load 80 80 80
  set_cpu_pl 1
  # tcp_low_latency 1
  realme_gt_on=1
  set_input_boost_freq 0 0 0 0

elif [[ "$action" = "pedestal" ]]; then
  cpu4_core_ctl off
  cpu7_core_ctl off

  set_cpu_freq 1612800 1804800 1996800 2419200 2265600 3200000
  sched_boost 1 0
  sched_config "62 40" "70 52" "300" "400"
  sched_limit 0 0 0 0 0 0
  cpuset '0' '0-3' '0-6' '0-7'
  cpuctl foreground max max
  cpuctl background 0 max
  cpuctl top-app max max
  if [[ "$a12" == true ]]; then
    stune_top_app 0 70
  else
    stune_top_app 1 70
  fi
  bw_max_always
  set_hispeed_freq 1804800 2342400 2496000
  set_hispeed_load 80 80 80
  set_cpu_pl 1
  # tcp_low_latency 1
  realme_gt_on=1
  set_input_boost_freq 0 0 0 0

fi

adjustment_by_top_app
# restore_core_online
realme_gt $realme_gt_on
