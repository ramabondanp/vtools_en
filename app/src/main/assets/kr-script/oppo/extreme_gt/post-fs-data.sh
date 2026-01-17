MODDIR=${0%/*}

# The module must handle file permissions, for example:
# set_perm_recursive  $MODPATH  0  0  0755  0644

# MODDIR=/data/adb/modules/extreme_gt

# replace_files /my_product
replace_files() {
  local folder="$1"
  find "$MODDIR/$folder" -type f 2>/dev/null | while read -r src; do
    local dst="${src#$MODDIR}"
    [[ -f "$dst" ]] && mount --bind "$src" "$dst"
  done
}

# Folders that need manual mounting
mount_folders='my_product my_heytap my_stock odm'
if [[ "$KSU" == "true" ]] || [[ $(which ksud) != "" ]] || [[ $(which apd) != "" ]]; then
  mount_folders='my_product my_heytap my_stock'
fi

# Iterate through special folders that need processing
for folder in $mount_folders; do
  if [[ -d $MODDIR/$folder ]]; then
    replace_files "$folder"
  fi
done
