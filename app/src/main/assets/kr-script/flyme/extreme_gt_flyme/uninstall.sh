echo '' > /data/adb/modules/extreme_gt_flyme/remove
setprop sys.extreme_gt.uninstall 1
run extreme_gt_flyme/module_uninstall.sh
echo '@string:dialog_addin_by_magisk' 1>&2