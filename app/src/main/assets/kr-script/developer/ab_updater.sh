# example
# rom=/sdcard/Download/miui_STAR_V12.5.20.0.RKACNXM_942a5712ef_11.0.zip

if [[ ! -f /cache/7za ]]; then
  echo 'Place the 7za binary in /cache!' 1>&2
  exit
else
  chmod 755 /cache/7za
fi

alias 7za="/cache/7za"

if [[ "$rom" == "" ]] || [[ ! -f "$rom" ]]; then
  echo 'ROM file not selected or inaccessible!' 1>&2
  echo "Selected file: $rom" 1>&2
  exit 1
fi

out_dir=${rom%.*}
if [[ "$out_dir" == "" ]]; then
  echo "Failed to parse path $out_dir" 1>&2
  exit 1
elif [[ -e "$out_dir" ]]; then
  echo "Extraction path already exists $out_dir" 1>&2
  exit 1
fi

files=$(7za l $rom)
if [[ $(echo "$files" | grep payload.bin) == "" ]] && [[ $(echo "$files" | grep payload_properties.txt) == "" ]]; then
  echo 'Archive invalid: payload.bin or payload_properties.txt missing' 1>&2
  exit 1
fi

echo 'Extracting ROM...'
7za e -o"$out_dir" "$rom" > /dev/null

if [[ ! -f "$out_dir/payload.bin" ]] && [[ ! -f "$out_dir/payload_properties.txt" ]]; then
  echo 'Extraction failed: payload.bin or payload_properties.txt missing' 1>&2
  exit 1
fi

echo '\n\n'
echo 'System update is about to start; depending on device performance, it may take 5-10 minutes or longer'
echo 'You can touch the log output area to keep the screen on, but do not tap other buttons.'
echo 'During this period (before onPayloadApplicationComplete(ErrorCode::...) is printed), do not operate the phone'
echo 'If red text like [INFO:...UPDATE_STATUS_DOWNLOADING (x), x.xxxxxx...] appears, do not panic; it is normal progress output.' 1>&2
echo 'After the update completes, do not install Magisk before rebooting; it may cause data issues requiring a factory reset'

# slot=$(getprop ro.boot.slot_suffix)
# echo -n 'Current slot: ' $slot
# if [[ "$slot" == "_a" ]]; then
#   echo ', new system will install to: _b'
# else
#   echo ', new system will install to: _a'
# fi
# echo '\n'

sleep 15
# echo 'progress:[-1/100]'

headers=$(cat "$out_dir/payload_properties.txt")
update_engine_client --follow --update --payload="file://$out_dir/payload.bin" --headers="$headers" # --verify=false

echo 'Refer to ErrorCode to determine whether the update succeeded'
echo 'kSuccess(0) means the update succeeded ^_^'
echo 'Any other error code means the update failed!'
