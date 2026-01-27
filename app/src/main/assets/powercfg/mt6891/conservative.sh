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
  min_freq 500000 437000 659000
  max_freq 1725000 1622000 1632000
  cpu_cci_mode 0
  cpu_power_mode 1
  dram_freq 0
  sched_limit 0 0 0 2000 0 2000
  stune_top_app 0 0
  stune_util background 0 0
  stune_util foreground 1024 0
  stune_util top-app 1024 0

  # ged gpu_dvfs_enable 1
  # ged gx_game_mode 0
  gpu_dvfs_margin 10

  # tcp_low_latency 0

  cpuset 0-2 0-3 0-5 0-7 0-3

elif [[ "$action" = "balance" ]]; then
  min_freq 500000 437000 659000
  max_freq 1800000 1985000 2292000
  cpu_cci_mode 0
  cpu_power_mode 0
  dram_freq 0
  sched_limit 0 0 0 0 0 0
  stune_top_app 0 0
  stune_util background 102 102
  stune_util foreground 1024 0
  stune_util top-app 1024 0

  # ged gpu_dvfs_enable 1
  # ged gx_game_mode 0
  gpu_dvfs_margin 10

  cpuset 0-2 0-3 0-5 0-7 0-3

  # tcp_low_latency 0

elif [[ "$action" = "performance" ]]; then
  min_freq 500000 437000 659000
  max_freq 2000000 2354000 2600000
  cpu_cci_mode 1
  cpu_power_mode 3
  dram_freq 0
  sched_limit 5000 0 2000 0 2000 0
  stune_top_app 0 10
  stune_util background 1024 102
  stune_util foreground 1024 0
  stune_util top-app 1024 0

  # ged gpu_dvfs_enable 1
  # ged gx_game_mode 1
  gpu_dvfs_margin 20

  cpuset 0-1 0-3 0-5 0-7 0-3
  sched_isolation_disable

  # tcp_low_latency 1

elif [[ "$action" = "fast" ]]; then
  min_freq 1725000 1537000 1632000
  max_freq 2000000 2600000 2600000
  cpu_cci_mode 1
  cpu_power_mode 3
  dram_freq max
  sched_limit 5000 0 4000 0 4000 0
  stune_top_app 1 20
  stune_util background 1024 0
  stune_util foreground 1024 0
  stune_util top-app 1024 0

  # ged gpu_dvfs 1
  # ged gx_game_mode 0
  gpu_dvfs_margin 25

  cpuset 0 0-3 0-5 0-7 0-3
  sched_isolation_disable

  # tcp_low_latency 1

elif [[ "$action" = "pedestal" ]]; then
  min_freq 2000000 2600000 2600000
  max_freq 2000000 2600000 3000000
  cpu_cci_mode 1
  cpu_power_mode 3
  dram_freq max
  sched_limit 10000 0 20000 0 20000 0
  stune_top_app 1 100
  stune_util background 1024 0
  stune_util foreground 1024 0
  stune_util top-app 1024 1014

  # ged gpu_dvfs_enable 1
  # ged gx_game_mode 0
  gpu_dvfs_margin 130

  cpuset 0 0-3 0-5 0-7 0-3
  sched_isolation_disable

  # tcp_low_latency 1
  # sspm_thermal_throttle 1
  realme_gt_on=1

fi

adjustment_by_top_app
