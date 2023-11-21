
import_utils="source $START_DIR/kr-script/infinix/utils.sh;"
run="sh $START_DIR/kr-script/infinix"

transchg=/sys/devices/platform/charger/tran_aichg_disable_charger
usbotg=/sys/devices/platform/odm/odm:tran_battery/OTG_CTL

xml_start() {
    echo '<?xml version="1.0" encoding="UTF-8" ?>'
    echo "<root>"
}
xml_end() {
    echo "</root>"
}
resource() {
    echo "  <resource dir=\"$1\" />"
}
group_start() {
    echo "  <group id=\"@$1\" title=\"$1\">"
}
group_end() {
    echo "  </group>"
}
switch() {
    echo "      <switch title=\"$1\">"
    echo "          <get>$2</get>"
    echo "          <set>$3</set>"
    echo "      </switch>"
}
switch_full() {
    echo "      <switch title=\"$1\" desc=\"$2\">"
    echo "          <get>$3</get>"
    echo "          <set>$4</set>"
    echo "      </switch>"
}
switch_hidden() {
    echo "      <switch title=\"$1\" shell=\"hidden\" >"
    echo "          <get>$2</get>"
    echo "          <set>$3</set>"
    echo "      </switch>"
}

action() {
    echo "      <action confirm=\"true\" title=\"$1\">"
    echo "          <desc>$2</desc>"
    echo "          <set>$3</set>"
    echo "      </action>"
}

get_row_id() {
  local row_id=$(echo "$1" | cut -f1 -d ']')
  echo "${row_id/[/}"
}
get_row_title() {
    echo "$1" | cut -f2 -d ' ' | cut -f1 -d ':'
}
get_row_state() {
    echo "$1" | cut -f2 -d ':'
}

common_render() {
  switch_full "INFINIX BYPASS CHARGING" 'Enable or disable infinix bypass charging.' "cat $transchg" "$import_utils set_transchg"
  switch_full "USB OTG" 'Enable or disable USB OTG.' "cat $usbotg" "$import_utils set_usbotg"
}

xml_start
  resource 'file:///android_asset/kr-script/common'
  resource 'file:///android_asset/kr-script/infinix'

group_start 'OPTIONS'
  common_render
group_end

xml_end
