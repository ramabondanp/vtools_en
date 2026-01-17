if [[ $( getprop ro.vivo.os.build.display.id | grep OriginOS) != '' ]]
then
    echo 1
else
    echo 0
fi
