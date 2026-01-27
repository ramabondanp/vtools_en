action=$1

init () {
  local dir=$(cd $(dirname $0); pwd)
  if [[ -f "$dir/powercfg-base.sh" ]]; then
    sh "$dir/powercfg-base.sh"
  elif [[ -f '/data/powercfg-base.sh' ]]; then
    sh /data/powercfg-base.sh
  fi
}
scene_scheduler() {
  SCDIR=${0%/*}
  killall 'scene-scheduler' 2>/dev/null
  # echo $SCDIR/scene-scheduler -c="$SCDIR/profile.json" -p="$1" -m="$2" > /cache/scene-scheduler.log
  $SCDIR/scene-scheduler -p="$1" -m="$2" -c="$SCDIR/profile.json" >/dev/null 2>&1 &
}

if [[ "$action" == "init" ]]; then
  init
  exit 0
fi


# 当前被打开的前台应用（需要Scene 4.3+版本，并开启【严格模式】才会获得此值）
if [[ "$top_app" != "" ]]; then
  echo "应用切换到前台 [$top_app]" >> /cache/scene_powercfg.log
fi

if [[ "$action" = "powersave" ]]; then
  echo "powersave"
elif [[ "$action" = "balance" ]]; then
  echo "balance"
elif [[ "$action" = "performance" ]]; then
  echo "performance"
elif [[ "$action" = "fast" ]]; then
  echo "fast"
fi

scene_scheduler "$top_app" "$1"