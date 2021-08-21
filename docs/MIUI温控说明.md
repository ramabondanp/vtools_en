## MIUI temperature control modifier description
-Here are some tips for modifying MIUI temperature control
-As for the grammatical format of the temperature control configuration file, you can search and learn it on Baidu, which is common to all Qualcomm models
-In addition, although it is known that Redmi 10x is a Dimensity processor, it can also use a similar syntax to configure temperature control

### Configure storage
-Usually, there will be multiple temperature control configuration files similar to the following list under MIUI system
-Depending on the number of SOC and adapted scenes, there may be an increase or decrease. The file names are also slightly different, but they all appear with names similar to `thermal-*tgame.conf`
  ```
  thermal-engine-sdm845-normal.conf
  thermal-engine-sdm845-nolimits.conf
  thermal-engine-sdm845-tgame.conf
  thermal-engine-sdm845-sgame.conf
  thermal-engine-sdm845-extreme.conf
  thermal-engine-sdm845.conf
  ```
-Temperature control configuration files are generally stored under `/vendor/etc`, older versions (before Android 8.0) may be stored under `/system/etc`
-In addition, the temperature control profile may also appear in
  > `/data/vendor/thermal/config`, usually issued by the cloud, if available, it will be used first<br />
  > When we modify the temperature control, we can directly replace it in `/vendor/etc` or put it in `/data/vendor/thermal/config`
  >

### Document Interpretation
-It is not difficult to see from the file name that each configuration file corresponds to a different usage scenario
-For example, `*-normal.conf` means the default temperature control, which is the temperature control configuration used by most common applications
  > Some models do not have the file `*-normal.conf`, for example:<br />
  > The default temperature control of sdm845 is `thermal-engine-sdm845.conf`<br />
  > sdm710 default temperature control is `thermal-engine-sdm710.conf`

-Interpretation of several common temperature control configuration names
  ```
  -normal.conf # Default temperature control
  -nolimits.conf # Unlimited (run points)
  -tgame.conf # Game
  -sgame.conf # King of Glory
  -extreme.conf # Extreme power saving
  -pubgmhd.conf # Stimulate the battlefield
  ```

### Illustrative example
####-Example ①
-The following is the first clip of Mi 10 Pro's default temperature control
  ```conf
  [VIRTUAL-SENSOR]
  algo_type virtual
  sensors cam_therm1 battery conn_therm quiet_therm wireless_therm xo_therm
  weight 1149 147 -193 408 -228 -385
  polling 1000
  weight_sum 1000
  compensation 2222
  ```
-algo_type `virtual` means a virtual sensor, `[VIRTUAL-SENSOR]` is the name of this group of configurations
-Sensors defines up to 6 sensors in `cam_therm1`, `battery`, `conn_therm`, `quiet_therm`, `wireless_therm`, `xo_therm`, weight represents the numerical weight of each sensor, and polling represents polling every 1000ms
-Simply put, by reading the values ​​of multiple sensors, using different weights, and finally calculating a virtual temperature value

#### Example ②
-The following is an example of a CPU temperature control configuration of Mi 10 Pro
  ```conf
  [SS-CPU4]
  algo_type ss
  sensor VIRTUAL-SENSOR
  device cpu4
  polling 1000
  trig 37000 38000 39000 41000 43000 49000
  clr 35000 37000 38000 39000 41000 47000
  target 1862400 1766400 1574400 1478400 1286400 710400
  ```
-You can see that the sensor here is `VIRTUAL-SENSOR`, which is the virtual sensor defined in the previous clip
-Of course, the sensors used in the definition of temperature control can be replaced (but not recommended), for example:
  ```conf
  [SS-CPU4]
  algo_type ss
  sensor battery
  device cpu4
  polling 1000
  trig 37000 38000 39000 41000 43000 49000
  clr 35000 37000 38000 39000 41000 47000
  target 1862400 1766400 1574400 1478400 1286400 710400
  ```

-It should be noted that different sensors may have different temperature units. There may be 37000 indicating 37°C, or 37, or even 370. If you want to replace the sensor, be careful! `

#### Example ③
-The following is an example of a low-battery core-down frequency reduction configuration of Mi 10 Pro
  ```conf
  [MONITOR-BCL]
  algo_type monitor
  sensor BAT_SOC
  device cpu4+hotplug_cpu6+hotplug_cpu7
  polling 2000
  trig 5
  clr 6
  target 1286400+1+1
  reverse 1
  ```
-The sensor here is `BAT_SOC`, which is still a virtual sensor, and its definition is
  ```conf
  [BAT_SOC]
  algo_type simulated
  path /sys/class/power_supply/battery/capacity
  polling 10000
  ```
-trig `5` means that the limit is triggered when `power <= 5%`, clr `6` means that the limitation is cleared when `power >= 5%`
-This configuration indicates that when the battery power is <=5%, the frequency of cpu4 is reduced to 1.2Ghz, and cpu6 and cpu7 are turned off

#### Example ④
-The following is a temperature configuration example of Mi 10 Pro
  ```conf
  [MONITOR-TEMP_STATE]
  algo_type monitor
  sensor VIRTUAL-SENSOR
  device temp_state
  polling 2000
  trig 45000 53000
  clr 44000 51000
  target 10100000 12400001
  ```
-The temperature status represents a series of limits triggered after the temperature reaches a specified value
-For example, if the temperature is too high, the use of camera, flash, HBM, etc. may be prohibited at the same time
-However, since the value pointed to by `target` is not defined here, it is not known what kind of restriction will be triggered.

### Other tips
-At present, the new version of MIUI for some models already supports instant replacement of temperature control
-Just copy the modified temperature control configuration to `/data/vendor/thermal/config`
-The system will automatically apply the configuration corresponding to the currently hit scene
-The simplest, you can pay attention to whether `/data/vendor/thermal/decrypt.txt` has changed to determine whether the temperature control has taken effect


### Tests and logs
-In most cases, MIUI will record the temperature control switch log and the temperature limit trigger and clear log under `/data/vendor/thermal/`, and you can directly view and understand the operating process of the temperature control
-You can also get the real-time status via `thermal-engine -o> /cache/thermal.conf`
-Of course, thermal-engine has other commands, such as:
```sh
# thermal-engine --help
Temperature sensor daemon
Optional arguments:
  --config-file/-c <file> config file
  --debug/-d debug output
  --soc_id/-s <target> target soc_id
  --norestorebrightness/-r disable restore brightness functionality
  --output-conf/-o dump config file of active settings
  --trace/-t enable ftrace tracing
  --dump-bcl/-i BCL ibat/imax file
  --help/-h this help screen
```


### Related Information
-https://blog.csdn.net/LoongEmbedded/article/details/55049975?utm_source=blogxgwz8
-https://blog.csdn.net/bs66702207/article/details/72782431?utm_source=blogxgwz0
-https://www.geek-share.com/detail/2700066916.html
-http://www.mamicode.com/info-detail-2022213.html