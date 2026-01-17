platform=`getprop ro.board.platform | tr 'A-Z' 'a-z'`
device=$(getprop ro.product.device)

# TODO: Some devices do not have curl
options=$(curl -s https://vtools.oss-cn-beijing.aliyuncs.com/Scene-Online/Thermal/$platform/$device/options.ini)
if [[ $(echo $options | grep Error) != "" ]]; then
  echo 'default|@string:kr_system_default'
else
  echo "$options"
fi
