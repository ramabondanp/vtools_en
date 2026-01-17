loc=`pm get-install-location | cut -f1 -d '['`
if [[ "$loc" = "0" ]]; then
    echo '@string:kr_apps_install_location_auto'
elif [[ "$loc" = "1" ]]; then
    echo '@string:kr_apps_install_internal_storage'
elif [[ "$loc" = "2" ]]; then
    echo '@string:kr_apps_install_external_storage'
fi