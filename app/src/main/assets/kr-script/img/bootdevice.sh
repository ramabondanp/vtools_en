dirs="/dev/block/bootdevice/by-name
/dev/block/by-name
/dev/block/platform/bootdevice/by-name"
root_dir=
for dir in $dirs
do
  if [[ -d $dir ]];then
    # echo "Found dir:" $dir
    root_dir=$dir
  fi
done
