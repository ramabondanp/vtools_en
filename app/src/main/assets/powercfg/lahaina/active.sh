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
  sched_limit 0 0 0 2000 0 1000
  stune_top_app 0 0
  cpuset '0-2' '0-3' '0-6' '0-7'
  cpuctl foreground 0 max
  cpuctl background 0 1
  cpuctl top-app 0 max
  bw_min
  bw_down 1 1
  set_hispeed_freq 1401600 1209600 1190400
  set_hispeed_load 90 90 90
  set_cpu_pl 0
  # tcp_low_latency 0
  realme_gt_on=0
  set_input_boost_freq 1094400 0 0 40

elif [[ "$action" = "balance" ]]; then
  set_cpu_freq 300000 1804800 710400 1996800 844800 2380800
  sched_boost 1 0
  sched_config "78 70" "89 82" "150" "400"
  sched_limit 0 0 0 500 0 500
  stune_top_app 0 0
  cpuset '0-2' '0-3' '0-6' '0-7'
  cpuctl foreground 0 max
  cpuctl background 0 max
  cpuctl top-app 0.25 max
  bw_min
  bw_max
  set_hispeed_freq 1612800 1555200 1670400
  set_hispeed_load 88 88 88
  set_cpu_pl 0
  # tcp_low_latency 0
  realme_gt_on=0
  set_input_boost_freq 1209600 1075200 1075200 120

elif [[ "$action" = "performance" ]]; then
  set_cpu_freq 300000 1804800 710400 2419200 825600 2841600
  sched_boost 1 0
  sched_config "62 55" "72 65" "200" "400"
  sched_limit 0 0 0 0 0 0
  cpuset '0-1' '0-3' '0-6' '0-7'
  cpuctl foreground 0.25 max
  cpuctl background 0 max
  cpuctl top-app 0.5 max
  if [[ "$a12" == true ]]; then
    stune_top_app 0 0
  else
    stune_top_app 1 0
  fi
  bw_min
  bw_max
  set_hispeed_freq 1612800 1881600 2035200
  set_hispeed_load 83 83 83
  set_cpu_pl 1
  # tcp_low_latency 1
  realme_gt_on=1
  set_input_boost_freq 1209600 1209600 1075200 120

elif [[ "$action" = "fast" ]]; then
  set_cpu_freq 1401600 1804800 1555200 2600000 1670400 3200000
  sched_boost 1 0
  sched_config "62 35" "70 50" "300" "400"
  cpuset '0' '0-3' '0-6' '0-7'
  cpuctl foreground 0.5 max
  cpuctl background 0 max
  cpuctl top-app max max
  sched_limit 0 0 0 0 0 0
  if [[ "$a12" == true ]]; then
    stune_top_app 0 15
  else
    stune_top_app 1 35
  fi
  bw_max_always
  set_hispeed_freq 1612800 1996800 2380800
  set_hispeed_load 80 80 80
  set_cpu_pl 1
  # tcp_low_latency 1
  realme_gt_on=1
  set_input_boost_freq 0 0 0 0

elif [[ "$action" = "pedestal" ]]; then
  set_cpu_freq 1708800 1804800 2227200 2112000 2380800 3200000
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
  set_hispeed_freq 1804800 2419200 2841600
  set_hispeed_load 80 80 80
  set_cpu_pl 1
  # tcp_low_latency 1
  realme_gt_on=1
  set_input_boost_freq 0 0 0 0

fi

adjustment_by_top_app
realme_gt $realme_gt_on
# restore_core_online
