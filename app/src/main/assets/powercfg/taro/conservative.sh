action=$1
task=$2

cfg_dir=$(cd $(dirname $0); pwd)

if [[ ! -f "$cfg_dir/powercfg-utils.sh" ]]; then
  echo "The dependent '$cfg_dir/powercfg-utils.sh' was not found !" > /cache/powercfg.sh.log
  exit 1
fi

source "$cfg_dir/powercfg-utils.sh"

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

# if [[ $(cat /sys/devices/soc0/machine | tr 'a-z' 'A-Z') == "CAPE" ]]; then
if [[ $(cat /sys/devices/system/cpu/cpu7/cpufreq/cpuinfo_max_freq) -gt 2995200 ]]; then
  echo '8+GEN1'
  profile="profile.plus.json"
  source "$cfg_dir/8+gen1.sh"
else
  echo '8GEN1'
  source "$cfg_dir/8gen1.sh"
fi
