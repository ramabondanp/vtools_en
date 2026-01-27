action=$1
task=$2
SCDIR=${0%/*}

init () {
  echo '[Scene PerfConfig Init] ...'
  if [[ -f "$SCDIR/powercfg-base.sh" ]]; then
    nohup "$SCDIR/powercfg-base.sh" >/dev/null 2>&1 &
  elif [[ -f '/data/powercfg-base.sh' ]]; then
    nohup /data/powercfg-base.sh >/dev/null 2>&1 &
  fi
  echo '[Scene PerfConfig Init] √'
}

if [[ "$action" == "init" ]]; then
  init
  exit 0
fi

killall 'scene-scheduler' 2>/dev/null
# cp /cache/scene.log /cache/scene.bak.log
# echo $SCDIR/scene-scheduler -p="$top_app" -m="$action" -c="$SCDIR/profile.json" > /cache/scene.log
# $SCDIR/scene-scheduler -p="$top_app" -m="$action" -c="$SCDIR/profile.json" >> /cache/scene.log
$SCDIR/scene-scheduler -p="$top_app" -m="$action" -c="$SCDIR/profile.json" >/dev/null 2>&1 &
