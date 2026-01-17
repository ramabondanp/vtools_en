#!/system/bin/sh

if [[ "$state" == "" ]]; then
    echo 'Invalid operation' 1>&2
else
    settings put global ntp_server $state
    echo 'Done.'
fi
