mode=$(settings get global captive_portal_mode)
if [[ "$mode" == "0" ]]; then
  echo 'Network connectivity check is disabled'
else
  echo -n 'use:'
  url=$(settings get global captive_portal_https_url)
  case "$url" in
    *"google"*)
      echo 'Google server'
    ;;
    *"miui"*)
      echo 'MIUI server'
    ;;
    *"v2ex"*)
      echo 'V2EX server'
    ;;
    "null"|"")
      echo 'Default server'
    ;;
  esac
fi