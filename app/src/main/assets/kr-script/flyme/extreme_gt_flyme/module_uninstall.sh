settings put global disable_dynamic_refresh_rate 0
if [[ $(getprop ro.product.odm.device) == 'meizu20Pro' ]]; then
  settings delete global flyme_force_rate
fi
