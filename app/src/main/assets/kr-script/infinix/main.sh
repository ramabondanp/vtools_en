
import_utils="source $START_DIR/kr-script/infinix/utils.sh;"
run="sh $START_DIR/kr-script/infinix"

enablesc=/sys/devices/platform/charger/enable_sc
tuisoc=/sys/devices/platform/charger/sc_tuisoc
usbotg=/sys/devices/platform/odm/odm:tran_battery/OTG_CTL
transchg=/sys/devices/platform/charger/tran_aichg_disable_charger

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
  echo "  <group id=\"@$1\" title=\"$2\">"
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
  echo "          <desc>$2</desc>"
  echo "          <get>$3</get>"
  echo "          <set>$4</set>"
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

bypass() {
  switch_hidden "BYPASS CHARGING ENABLE" "Enable or Disable Infinix bypass charging globally.  It will turn off when the charger is unplugged.\n\nAktifkan atau Nonaktifkan pengisian daya bypass Infinix secara global.  Fitur ini akan mati saat pengisi daya dicabut." "cat $transchg" "$import_utils set_bypasschg"
  switch_hidden "LIMIT CHARGING ENABLE" "Enable or Disable limit charging.\n\nAktifkan atau Nonaktifkan batas pengisian." "cat $enablesc" "$import_utils set_limitchg"
  echo "      <picker title=\"LIMIT BATTERY LEVEL\" shell=\"hidden\" reload=\"@BYPASS\" summary-sh=\"$import_utils get_maxchg\">"
  echo "          <desc>Set the maximum battery percentage level for limit charging. If the battery falls below this level, it will resume charging.\n\nTetapkan tingkat persentase baterai maksimum untuk batas pengisian daya. Jika baterai turun di bawah level ini, baterai akan melanjutkan pengisian daya.</desc>"
  echo "          <options>"
  echo '<option value="99">100</option>
<option value="98">99</option>
<option value="97">98</option>
<option value="96">97</option>
<option value="95">96</option>
<option value="94">95</option>
<option value="93">94</option>
<option value="92">93</option>
<option value="91">92</option>
<option value="90">91</option>
<option value="89">90</option>
<option value="88">89</option>
<option value="87">88</option>
<option value="86">87</option>
<option value="85">86</option>
<option value="84">85</option>
<option value="83">84</option>
<option value="82">83</option>
<option value="81">82</option>
<option value="80">81</option>
<option value="79">80</option>
<option value="78">79</option>
<option value="77">78</option>
<option value="76">77</option>
<option value="75">76</option>
<option value="74">75</option>
<option value="73">74</option>
<option value="72">73</option>
<option value="71">72</option>
<option value="70">71</option>
<option value="69">70</option>
<option value="68">69</option>
<option value="67">68</option>
<option value="66">67</option>
<option value="65">66</option>
<option value="64">65</option>
<option value="63">64</option>
<option value="62">63</option>
<option value="61">62</option>
<option value="60">61</option>
<option value="59">60</option>
<option value="58">59</option>
<option value="57">58</option>
<option value="56">57</option>
<option value="55">56</option>
<option value="54">55</option>
<option value="53">54</option>
<option value="52">53</option>
<option value="51">52</option>
<option value="50">51</option>
<option value="49">50</option>
<option value="48">49</option>
<option value="47">48</option>
<option value="46">47</option>
<option value="45">46</option>
<option value="44">45</option>
<option value="43">44</option>
<option value="42">43</option>
<option value="41">42</option>
<option value="40">41</option>
<option value="39">40</option>
<option value="38">39</option>
<option value="37">38</option>
<option value="36">37</option>
<option value="35">36</option>
<option value="34">35</option>
<option value="33">34</option>
<option value="32">33</option>
<option value="31">32</option>
<option value="30">31</option>
<option value="29">30</option>
<option value="28">29</option>
<option value="27">28</option>
<option value="26">27</option>
<option value="25">26</option>
<option value="24">25</option>
<option value="23">24</option>
<option value="22">23</option>
<option value="21">22</option>
<option value="20">21</option>
<option value="19">20</option>
<option value="18">19</option>
<option value="17">18</option>
<option value="16">17</option>
<option value="15">16</option>
<option value="14">15</option>
<option value="13">14</option>
<option value="12">13</option>
<option value="11">12</option>
<option value="10">11</option>
<option value="9">10</option>
<option value="8">9</option>
<option value="7">8</option>
<option value="6">7</option>
<option value="5">6</option>
<option value="4">5</option>
<option value="3">4</option>
<option value="2">3</option>
<option value="1">2</option>'
  echo "          </options>"
  echo "          <get>cat $tuisoc</get>"
  echo "          <set>$import_utils set_maxchg</set>"
  echo "      </picker>"
}

xml_start
resource 'file:///android_asset/kr-script/common'
resource 'file:///android_asset/kr-script/infinix'

group_start 'BYPASS' "BYPASS/LIMIT CHARGING"
  bypass
group_end

group_start 'OTG' "USB OTG"
  switch_hidden "USB OTG ENABLE" "Enable or Disable USB OTG.\n\nAktifkan atau Nonaktifkan USB OTG." "cat $usbotg" "$import_utils set_usbotg"
group_end

xml_end
