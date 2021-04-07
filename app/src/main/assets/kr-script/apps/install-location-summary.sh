loc=`pm get-install-location | cut -f1 -d '['`
if [[ "$loc" = "0" ]]; then
    echo 'Automatic (automatically determined by the system)'
elif [[ "$loc" = "1" ]]; then
    echo 'Internal storage (local)'
elif [[ "$loc" = "2" ]]; then
    echo 'External Storage(SDCard)'
fi