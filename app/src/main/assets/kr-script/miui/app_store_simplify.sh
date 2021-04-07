base_dir="/data/user/$ANDROID_UID/com.xiaomi.market/files"
res_dir=`ls $base_dir | grep web-res- | tail -1`
if [[ "$res_dir" == "" ]]; then
    echo 'Find the resources folder' 1>&2
    return
fi
echo 'Find the resources folder' $res_dir

function override_file() {
  local page="$1"
  local css_override="$base_dir/$res_dir/$page.override.css"
  local html_file="$base_dir/$res_dir/$page.html"

  if [[ -f "$html_file" ]]; then
    echo "@import url(\"$page.chunk.css\");" > $css_override
    cat $PAGE_WORK_DIR/app_store/$page.css >> $css_override
    sed -i "s/$page.chunk.css/$page.override.css/" "$html_file"

    chmod 777 $css_override
    chmod 777 "$html_file"
  else
    echo 'Not found' $html_file 1>&2
  fi

  echo ''
}

echo 'Before using this function, please make sure to open each screen of the app store once~'
echo ''

if [[ "$res_dir" = "" ]];
then
  echo 'Please start the app store once and navigate through the various screens~' 1>&2
  exit 1
fi

echo 'This function is best suited for：'
echo 'App Store 20.9.14(4001240)，web-res-1749'
echo ''

echo 'Streamline [Application Details]~'
override_file "detailV2"

echo 'Streamline [Essential]~'
override_file "essential"

echo 'Streamline [Game]~'
override_file "g-feature"

echo 'Streamline [Home]~'
override_file "index"

echo 'Streamline [my]~'
override_file "mine"

echo 'Streamline [Leaderboard]~'
override_file "rank"

echo 'Streamline [search]~'
override_file "search-guide"

echo 'Streamline [Software] ~'
override_file "software"

killall -9 com.xiaomi.market 2>/dev/null

versionCode=`dumpsys package com.xiaomi.market | grep versionCode | cut -f2 -d '=' | cut -f1 -d ' ' | head -1`
if [[ $versionCode < 4001102 ]] || [[ $versionCode > 4001240 ]]
then
  echo 'Your [App Store] is not the best version for this feature, some changes may not be effective~'
  # 最佳适配 4001240，web-res-1749
fi
