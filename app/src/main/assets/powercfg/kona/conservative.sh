action=$1
task=$2

init () {
  echo '[Scene PerfConfig Init] ...'
  if [[ -f "$cfg_dir/powercfg-base.sh" ]]; then
    nohup "$cfg_dir/powercfg-base.sh" >/dev/null 2>&1 &
  elif [[ -f '/data/powercfg-base.sh' ]]; then
    nohup /data/powercfg-base.sh >/dev/null 2>&1 &
  fi
  echo '[Scene PerfConfig Init] √'
}

if [[ "$action" == "init" ]]; then
  init
  exit 0
fi

cfg_dir=$(cd $(dirname $0); pwd)

if [[ ! -f "$cfg_dir/powercfg-utils.sh" ]]; then
  echo "The dependent '$cfg_dir/powercfg-utils.sh' was not found !" > /cache/powercfg.sh.log
  exit 1
fi

source "$cfg_dir/powercfg-utils.sh"

if [[ "$action" == "fast" ]]; then
  bw_max_always
else
  bw_min
fi
reset_basic_governor

if [[ "$action" = "powersave" ]]; then
  set_cpu_freq 300000 1708800 710400 1574400 844800 1747200
  sched_boost 0 0
  set_hispeed_freq 1075200 940800 1075200
  sched_config "72 68" "90 80" "150" "400"
  sched_limit 0 0 0 2000 0 1000
  cpuset '0-2' '1-4' '1-6' '0-7'
  stune_top_app 0 0
  set_cpu_pl 0

  realme_gt_on=0

elif [[ "$action" = "balance" ]]; then
  set_cpu_freq 300000 1804800 710400 1862400 844800 2073600
  sched_boost 1 0
  set_hispeed_freq 1612800 1670400 1862400
  sched_config "70 67" "80 80" "150" "400"
  sched_limit 0 0 0 500 0 500
  cpuset '0-2' '1-4' '1-6' '0-7'
  stune_top_app 0 0
  set_cpu_pl 0

  realme_gt_on=0

elif [[ "$action" = "performance" ]]; then
  set_cpu_freq 300000 1804800 710400 2419200 825600 2841600
  sched_boost 1 0
  set_hispeed_freq 1612800 1766400 2073600
  sched_config "65 65" "75 80" "200" "400"
  sched_limit 0 0 0 0 0 0
  cpuset '0-1' '1-4' '1-7' '0-7'
  stune_top_app 0 0
  set_cpu_pl 1

  realme_gt_on=1

elif [[ "$action" = "fast" ]]; then
  set_cpu_freq 1248000 1804800 1478400 2600000 1516800 3200000
  sched_boost 1 0
  set_hispeed_freq 1708800 2342400 2649600
  sched_config "62 62" "70 78" "300" "400"
  sched_limit 4000 0 4000 0 4000 0
  cpuset '0' '0-4' '1-7' '0-7'
  stune_top_app 1 1
  set_cpu_pl 1

  realme_gt_on=1

elif [[ "$action" = "pedestal" ]]; then
  set_cpu_freq 1804800 1804800 2419200 2600000 2841600 3200000
  sched_boost 1 0
  set_hispeed_freq 1804800 2419200 2841600
  sched_config "47 50" "60 68" "75" "90"
  sched_limit 8000 0 8000 0 8000 0
  cpuset '0' '1-4' '1-7' '0-7'
  stune_top_app 1 100
  set_cpu_pl 1

  realme_gt_on=1

fi

adjustment_by_top_app
realme_gt $realme_gt_on
