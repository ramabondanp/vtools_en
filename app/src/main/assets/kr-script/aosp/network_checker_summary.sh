mode=$(settings get global captive_portal_mode)
if [[ "$mode" == "0" ]]; then
  echo '@string:kr_aosp_net_checker_disable'
else
  url=$(settings get global captive_portal_https_url)
  case "$url" in
    *"google"*)
      echo '@string:kr_aosp_net_checker_google'
    ;;
    *"miui"*)
      echo '@string:kr_aosp_net_checker_miui'
    ;;
    *"v2ex"*)
      echo '@string:kr_aosp_net_checker_v2ex'
    ;;
    "null"|"")
      echo '@string:kr_aosp_net_checker_default'
    ;;
  esac
fi