#!/system/bin/sh

# Default is usually 5555; changed for a bit more safety
port="33445"

if [[ ! "$state" = "1" ]]
then
    setprop service.adb.tcp.port -1
    stop adbd
    killall -9 adbd 2>/dev/null
    start adbd
    echo 'Remote debugging service stopped'
    setprop service.adb.tcp.port ""
    return 0
fi

setprop service.adb.tcp.port $port;
stop adbd;
killall -9 adbd 2>/dev/null
sleep 1;
start adbd;

ip=`ifconfig wlan0 | grep "inet addr" | awk '{ print $2}' | awk -F: '{print $2}'` 2>/dev/null
if [[ ! -n "$ip" ]]
then
    ip=`ifconfig eth0 | grep "inet addr" | awk '{ print $2}' | awk -F: '{print $2}'` 2>/dev/null
fi

echo "On a computer connected to the same LAN as the phone"
echo 'Use the following command'
echo ''

if [[ -n "$ip" ]]
then
    echo "adb connect $ip:$port"
else
    echo "adb connect <phone-ip>:$port"
fi

echo 'to connect to the phone'

echo 'If both devices are on the same LAN and the IP is correct but it still fails'
echo 'try reconnecting Wi-Fi on both devices while keeping network debugging enabled'
