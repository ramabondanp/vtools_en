#!/system/bin/sh

input=./kr-script/common/empty
output=/system/vendor/etc/perf/perfboostsconfig.xml

for dir in $(ls /data/adb/modules/ | grep -v scene_systemless)
do
  if [[ ! -e /data/adb/modules/$dir/disable ]]; then
    if [[ -e /data/adb/modules/$dir/$output ]]; then
      echo 'Detected another module overriding perfboostsconfig.xml' 1>&2
      echo 'Located at: ' /data/adb/modules/$dir/$output 1>&2
      echo 'Delete that file before performing this action in Scene!' 1>&2
    fi
  fi
done

source ./kr-script/common/magisk_replace.sh

file_mixture_hooked "$input" "$output"
result="$?"

if [[ "$result" = 1 ]]
then
  echo 0
else
  echo 1
fi
