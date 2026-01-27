
if [[ "$action" = "powersave" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 60 80 70 90 78 93
  conservative_step 2 1 1
  walt_mode 0 3000 0 6000 0 6000
  set_cpu_freq 307200 1478400 633600 1881600 806400 2131200
  set_hispeed_freq 1075200 1209600 1036800
  set_hispeed_load 90 90 90
  set_cpu_pl 0
  realme_gt_on=0


elif [[ "$action" = "balance" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 55 75 68 87 69 87
  conservative_step 2 2 2
  walt_mode 0 2000 0 4000 0 4000
  set_cpu_freq 307200 1574400 633600 2246400 806400 2476800
  set_hispeed_freq 1075200 1324800 1228800
  set_hispeed_load 85 85 85
  set_cpu_pl 0
  realme_gt_on=0


elif [[ "$action" = "performance" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 48 67 68 82 67 83
  conservative_step 3 3 3
  walt_mode 0 2000 0 3000 0 3000
  # set_cpu_freq 307200 1574400 633600 2227200 806400 2284800
  set_cpu_freq 307200 1574400 633600 2457600 806400 2822400
  set_hispeed_freq 1171200 1555200 1536000
  set_hispeed_load 82 82 82
  set_cpu_pl 1
  realme_gt_on=1


elif [[ "$action" = "fast" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 48 60 62 73 60 72
  conservative_step 3 3 3
  walt_mode 0 1000 0 2000 0 2000
  set_cpu_freq 1075200 1785600 998400 2745600 940800 2995200
  set_hispeed_freq 1267200 1555200 1766400
  set_hispeed_load 82 82 82
  set_cpu_pl 1
  realme_gt_on=1

elif [[ "$action" = "pedestal" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 45 55 45 68 45 58
  conservative_step 3 3 3
  walt_mode 0 0 0 0 0 0
  set_cpu_freq 1075200 1785600 1209600 2745600 1286400 3187200
  set_hispeed_freq 1478400 1996800 1996800
  set_hispeed_load 80 80 80
  set_cpu_pl 1
  realme_gt_on=1

fi

adjustment_by_top_app
realme_gt $realme_gt_on
