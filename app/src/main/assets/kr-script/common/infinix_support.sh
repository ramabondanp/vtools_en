#!/system/bin/sh

note30=$(getprop ro.product.vendor.name | grep X678B)
note30pro=$(getprop ro.product.vendor.name | grep X6833B)
if [ "$note30" != "" ] || [ "$note30pro" != "" ] 
then
  echo 1
fi