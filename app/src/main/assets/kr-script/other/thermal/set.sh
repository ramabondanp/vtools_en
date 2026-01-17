module_dir=/data/adb/modules/scene_thermal_remover
if [[ -d $module_dir ]]; then
  echo 'Remove installed module...'
  rm -rf $module_dir
fi

if [[ ! -d /data/adb/modules ]];then
  echo 'Please install Magisk first!'
  exit 0
fi


echo 'Warning: this operation is high-risk. If you are not fully prepared with backups and recovery, exit now!' 1>&2
echo 'Warning: this operation is dangerous; if you have not backed up, please exit immediately!' 1>&2
echo ''
echo 'The operation will start in 15 seconds...' 1>&2
echo 'I will wait 15 seconds...' 1>&2
echo ''

sleep 15

props='id=scene_thermal_remover
name=[SCENE]ThermalRemover
version=1.0.0
versionCode=1
description=Replace the thermal-engine program with an empty file
author=Duduski
'

module_files=$PAGE_WORK_DIR/thermal
cp_t_module_file() {
  echo '[+]' $1
  cp $module_files/$1 $module_dir/$1
  chmod 755 $module_dir/$1
}

if [[ "$selected" != "" ]]; then
 mkdir $module_dir
 echo "$props" > $module_dir/module.prop
 cp_t_module_file service.sh
 echo "$selected" | while read item
 do
   echo [Replace] $item
   mkdir -p $module_dir$item
   rm -r $module_dir$item
   echo '' > $module_dir$item
 done
fi

handle_partition() {
    # if /system/vendor is a symlink, we need to move it out of $MODPATH/system, otherwise it will be overlayed
    # if /system/vendor is a normal directory, it is ok to overlay it and we don't need to overlay it separately.
    if [ ! -e $module_dir/system/$1 ]; then
        # no partition found
        return;
    fi

    if [ -L "/system/$1" ] && [ "$(readlink -f /system/$1)" = "/$1" ]; then
        # we create a symlink if module want to access $module_dir/system/$1
        # but it doesn't always work(ie. write it in post-fs-data.sh would fail because it is readonly)
        mv -f $module_dir/system/$1 $module_dir/$1 && ln -sf ../$1 $module_dir/system/$1
    fi
}

if [[ "$KSU" == "true" ]] || [[ $(which ksud) != "" ]]; then
  handle_partition 'vendor'
  handle_partition 'system_ext'
  handle_partition 'product'
fi
