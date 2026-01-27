## 适用版本
- 本文档适用于Scene5.3.0 (framework版本号 `130` )

### framework 130 新增特性
- features 新的根配置
- features.high_rate 拓展特性，屏幕刷新率控制函数@high_rate的相关配置
- features.processes 拓展特性，用于指定重要安卓APP进程所属的cpuset
- features.charge_control 拓展特性，充电控制函数@charge的相关配置
- affiniy.cpuset_mode 让cpuset协同affiniy，形成更强力的线程放置约束
- affiniy.heavy_thread 指定重负载线程的名称
- affiniy.heavy_mask 指定重负载线程的affiniy mask
- affiniy.unity_main 指定UnityMain线程的affiniy mask
- cpuset 通过cpuset为应用的线程指定核心
- import 通过import，可将对app的配置拆分为单独文件
- booster.events 预设增加presets
- presets 新的根配置，用于创建一组预设，并可通过[@preset] [name]来使用
- sensor.props 指定一组将要修改的属性
- sensor.rules.values 指定一组属性的值
- sensor.rules.enter_once 只执行一次的Enter配置
- @governor 新的函数，用于同时切换所有cluster的调速器
- @high_rate 切换高刷/低刷状态
- @charge 充电控制函数

### framework 130 移除特性
- @refresh_rate 改变屏幕刷新率函数，现已被弃用
- stop_on 该配置已不再推荐使用，相关说明已从文档移除


## 创建一个配置文件
- 在开始之前，你起码应该稍微了解JSON的格式规范
- 如下所示，这是一个空的配置文件
> `platform` 属性标识该配置用于`msm8998`平台，是必需的<br>
> **platform_name** 是一个说明性属性，方便使用者理解**msm8998**是什么<br>
> `framework` 属性用于标注该配置适用的调度框架版本号<br>
> `schemes` 下则是对SCENE5中5个模式的配置

```json
{
  "platform": "msm8998",
  "platform_name": "骁龙835",
  "framework": 130,
  "schemes": {
    "powersave": {
      "call": []
    },
    "balance": {
      "call": []
    },
    "performance": {
      "call": []
    },
    "fast": {
      "call": []
    },
    "pedestal": {
      "call": []
    }
  }
}
```

| KEY | NAME |
| :- | :- |
| powersave | 省电模式 |
| balance | 均衡模式 |
| performance | 性能模式 |
| fast | 极速模式 |
| pedestal | 底座模式 |



## 内置函数
- Scene内置了一些常用的调度调节函数
- 并对(Qualcomm|MediaTek)设备做了兼容适配

### CPU频率范围 **`@cpu_freq`**
- 参数格式为 **@cpu_freq [clusterExpr] [freqExpr] [freqExpr]**
- 例如，我准备在省电模式下将CPU小核限制为最高900Mhz
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@cpu_freq", "cpu0", "min", "900MHz"]
      ]
    }
  }
}
```


#### CPU最小频率 **`@cpu_freq_min`**
- 参数格式为 **@cpu_freq_min [clusterExpr] [freqExpr]**
- 例如，我准备在省电模式下将CPU小核限制为最低300Mhz
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@cpu_freq_min", "cpu0", "300MHz"]
      ]
    }
  }
}
```

#### CPU最大频率 **`@cpu_freq_max`**
- 参数格式为 **@cpu_freq_max [clusterExpr] [freqExpr]**
- 例如，我准备在省电模式下将CPU小核限制为最高900Mhz
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@cpu_freq_max", "cpu0", "900MHz"]
      ]
    }
  }
}
```

#### 补充说明
- 频率范围冲突
  > 假设，CPU0此时已经被限制为 [600Mhz ~ 1.2Ghz]<br>
  > 我们调用 **`@cpu_freq_min` cpu0 1.5Ghz** 必然不会成功<br>
  > 因为 1.5Ghz 不符合 [600Mhz ~ 1.2Ghz]这个区间<br>
  > 建议使用 **`@cpu_freq` cpu0 1.5Ghz 2.0Ghz** 直接指定CPU频率范围

- clusterExpr说明
  > 我们修改CPU频率通常是以核心集群(Cluster)为单位进行的<br>
  > 例如，4+3+1的骁龙处理器，小、中、大核可以用以下几种格式来表示<br>
  > `cpu0`、`cpu4`、`cpu7`<br>
  > `policy0`、`policy4`、`policy7`<br>
  > `cluster0`、`cluster1`、`cluster2`<br>
  > 但是，千万不要用意义不明的数字来表示，例如 `0`、`4`、`7`，这是非常不利于理解

- freqExpr说明
  > 为了更方便的表示频率，Scene内置了多种格式兼容和特殊值<br>
  > 例：`min`、`max` 分别表示该核心(Cluster)支持的最小、最大频率<br>
  > 例：`1800Mhz`、`1.8Ghz` 均等同于 `1800000Khz` 或 直接写 `1800000`<br>
  > 如果你指定了一个不存在的频率，那么Scene会帮你选择低于指定频率的最大频率<br>
  > 又或者，指定的频率比核心支持的最高频率还要高，那么Scene会帮你选择支持的最高频率<br>
  > 又或者，指定的频率比核心支持的最低频率还低，那么Scene会帮你选择支持的最低频率<br>

  > 但是，小心！用`Ghz|Mhz`表示频率虽然非常方便，但你可能会掉进陷阱<br>
  > 因为CPU的频率经常不是 2.8Ghz(2800000Khz) 这样整齐的数字，更多是 2841600Khz这样<br>
  > 如果你写2.8Ghz，是不会匹配到2841600Khz这个频率的！<br>

  > 负值频率<br>
  > 这是Scene定义的一种表示频率的方式，它是指在 `max` 的基础上减去一个频率<br>
  > 例如 `-300Mhz`、`-0.3Ghz`、`-300000`<br>
  > 如果，小核最高频率为`1800Mhz`<br>
  > 那么 **`@cpu_freq` cpu0 -1200Mhz -300Mhz** 相当于 **`@cpu_freq` cpu0 600Mhz 1500Mhz**<br>
  > 如果，小核最高频率为`2000Mhz`<br>
  > 那么 **`@cpu_freq` cpu0 -1200Mhz -300Mhz** 相当于 **`@cpu_freq` cpu0 800Mhz 1700Mhz**

### GPU频率范围 `@gpu_freq`
- 参数格式为 **@gpu_freq [freqExpr] [freqExpr]**
- 例如，我准备在省电模式下将CPU小核限制为最高500Mhz
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@gpu_freq", "min", "500MHz"]
      ]
    }
  }
}
```

#### GPU最小频率 **`@gpu_freq_min`**
- 参数格式为 **@gpu_freq_min [freqExpr]**
- 例如，我准备在极速模式下将GPU最低频率限制为400Mhz
```json
{
  "platform": "msm8998",
  "schemes": {
    "fast": {
      "call": [
        ["@gpu_freq_min", "400MHz"]
      ]
    }
  }
}
```

#### GPU最大频率 **`@gpu_freq_max`**
- 参数格式为 **@gpu_freq_max [freqExpr]**
- 例如，我准备在省电模式下将GPU最膏限制为最高300Mhz
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@gpu_freq_max", "400MHz"]
      ]
    }
  }
}
```

#### 补充说明
- 频率范围冲突
  与CPU频率设置类似，不再赘述
- clusterExpr说明
  与CPU频率设置类似，不再赘述

#### 补充说明
- 近似刷新率档位
> 在可以的情况下，会优先匹配完全一致的刷新率档位<br>
> 在无完全匹配档位时，择优匹配近似档位，逻辑如下<br>

> 趋大（T >= 61 时，取高于T的最低一档）<br>
> 例  T=90，设备只支持 [60, 120, 144]<br>
>	   会命中 120

> 趋小（T < 61 时，取低于T的最高一档）<br>
> 例  T=48，设备只支持 [30, 45, 60, 90, 120]<br>
>	  会命中 45<br>

> 注：T 指目标刷新率refreshRate

> 防抖处理<br>
> 某些情况下，刷新率并非整数。例如某些设备的60Hz可能实际是60.5Hz或59.8Hz<br>
> Scene已经对这种情况做了容错处理，最高允许 ±2Hz 的刷新率误差

### 优先级 `@set_priority`
- 严格意义来说，这个参数改变的处理器的升降频、大小核迁移策略，而非进程抢占CPU资源的优先级
- 参数格式为 **@set_priority [group] [level]**
- `group` 可指定 `background`、`foreground`、`top-app`，或简写为 `bg`、`fg`、`top`
- `level` 按积极性分别为 `min`、`low`、`normal`、`high`、`max`、`turbo` 6个档
  > Scene会根据你指定的`level`自动调整 <br>
    **cpu.uclamp.min**、<br>
    **schedtune.boost**、<br>
    **cpuset**、<br>
    **sched_boost**、<br>
    **sched_upmigrate**、<br>
    **up_rate_limit_us**、<br>
    **schedtune.util.max** <br>
    等一系列参数(具体取决于内核支持情况)

- 例如，在性能模式下我们希望处理器尽可能积极点，同时限制后台进程的CPU占用
- 则可以像这样配置
```json
{
  "platform": "lahaina",
  "platform_name": "骁龙888",
  "schemes": {
    "performance": {
      "call": [
        ["@set_priority", "top-app", "high"],
        ["@set_priority", "foreground", "normal"],
        ["@set_priority", "background", "low"]
      ]
    }
  }
}
```

- 又或者，极速模式下，我们想让处理器升频变的非常积极，同时让后台进程也可以比较正常的保持运行
- 则可以像这样配置
```json
{
  "platform": "lahaina",
  "platform_name": "骁龙888",
  "schemes": {
    "performance": {
      "call": [
        ["@set_priority", "top-app", "max"],
        ["@set_priority", "foreground", "high"],
        ["@set_priority", "background", "normal"]
      ]
    }
  }
}
```

#### 补充说明
- 关乎处理器升降频积极性的全局参数，只会在调用 **`@set_priority` top-app [level]** 时修改
- `high`、`max`、`turbo` 均会提高处理器升频积极性和重负载任务向大核迁移的积极性
  > 注意：`turbo`级别会无条件的优先使用大核<br>
  > 优先使用大核，在负载不高的情况下，能显著提高流畅度和响应速度<br>
  > `但`在高帧率的游戏和大型游戏中，单核性能要求往往非常之高，<br>
  > 将过多的任务迁移至大核，可能会压垮本就负载极高的大核



### Realme GT模式 `@realme_gt`
- 参数格式为 **@realme_gt [on|off]**
- 例如，我准备在极速模式下自动开启GT模式
```json
{
  "platform": "msm8998",
  "schemes": {
    "fast": {
      "call": [
        ["@realme_gt", "on"]
      ]
    }
  }
}
```


### 设置值 `@set_value`
- 参数格式为 **@set_value [path] [value]**
- 例如，我准备在省电模式下向指定路径写入值(示例中为意图关闭CPU7)
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@set_value", "/sys/devices/system/cpu/cpu7/online", "0"]
      ]
    }
  }
}
```

#### 补充说明
> `@set_value` 函数的拓展用法非常复杂，如果你还没有遇到需要特殊用法的场景，可以先略过本节，继续阅读其它说明<br>
> 留意，所有特殊用法都是在 [value] 上加特殊标识符

- 特殊用法：多次写入 `|`符号
> 下面这个例子是我们通过PPM，修改MTK处理器频率<br>
> 是指分两次分别写入`0 1991000`和`"1 2025000`
```
"call": [
  ["@set_value", "/proc/ppm/policy/hard_userlimit_max_cpu_freq", "0 1991000|1 2025000"]
]
```

- 所有特殊用法

```
多个值 如 123|223|323
只调大 如 ^223 或 >223，说明：如属性当前值为 123, value指定^122 则不会执行写入，如果 value指定^124 会执行写入
只调小 如 <123，说明：如属性当前值为 123, value指定^124 则不会执行写入，如果 value指定^122 会执行写入
锁定值 如 #123，说明：向指定属性写入123，完成将属性改为只读状态
校验值 如 true(enabled:true)，说明：如果属性当前值 是 enabled:true，则不执行写入
模糊校验 如 true(~enabled:true)，说明：如果属性当前值 包含 enabled:true，则不执行写入
不校验 如 =123，表示跳过比对属性当前值，即使属性当前值与value相等，也会执行写入
			* 框架默认会有比对逻辑，value直接写 111 等同于 111(111),
			* 但是注意，value包含 | 符号时无法执行校验，例如 1500|1700|1899 等同于 =1500|=1700|=1899

values 特殊格式 标识符特殊用法
正确示例
#^223 只上调数值，并锁定数值
#^1600000(boost_cluster_0:1600000) 只上调数值，并锁定数值
0 1600000|1 1400000|#1 1400000 分别向属性写入 0 1600000, 1 1400000, 1 1400000, 并在完成后锁定

错误示例
^#223 锁定标识符(#)和其它标识符共同使用时，#必须永远放在最前面
```

### 锁定值 `@lock_value`
- 参数格式为 **@lock_value [path] [value]**
- 例如，我准备在省电模式下向指定路径写入值(示例中为意图关闭CPU7)，并在写入后将属性改为只读状态
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@lock_value", "/sys/devices/system/cpu/cpu7/online", "0"]
      ]
    }
  }
}
```

#### 补充说明
- `@lock_value` 的锁定效果与`@set_value`特殊用法的`#[value]`是相同的
- 并且`@lock_value`也支持对[value]增加特殊用法修饰符


## 进阶(场景)
- 虽然基础的5个模式已经足够应对绝大多数场景
- 但如果能针对特定应用，做特定的优化，那不是更好吗？

- 举个例子：
```json
{
  "platform": "mt6893",
  "platform_name": "D1200",
  "apps": [
    {
      "friendly": "原神",
      "scene": "Scene-For-YS",
      "packages": [
        "com.miHoYo.Yuanshen",
        "com.miHoYo.ys.mi",
        "com.miHoYo.ys.bilibili",
        "com.miHoYo.GenshinImpact"
      ],
      "call": [],
      "sensors": [],
      "affinity": {},
      "booster": {}
    }
  ]
}
```

> 这个示例中，添加了一个没有执行任何特殊行为的场景<br>
> 其中[packages]指定该场景会命中哪些应用(写的包名)<br>
> 而[scene]属性的`Scene-For-YS`是一个自定义的场景ID<br>
> [friendly]是一个说明性属性，主要用于改善配置可读性<br>
> [call]中可以像前面配置5个模式一样，调用Scene内置函数

- 如果你需要定义一组场景配置，并适用于所有APP的话
- 那么 可以用 `"packages": ["*"]` 来实现通配，例：
```json
{
  "platform": "mt6893",
  "platform_name": "D1200",
  "apps": [
    {
      "friendly": "通用",
      "scene": "Scene-For-Any",
      "packages": ["*"],
      "call": []
    }
  ]
}
```
- 不过，`场景`的匹配过程是自上而下进行的，所以你应当把通配的场景设定放在最后

### 传感器 `sensors`
- Scene实现录简单的数值监听。注意，是数值，也就是说监听的值必须是个数字！
- 它的作用是，定时轮询(读取)指定路径，并根据所得的值决定要修改什么参数

- 完整用法 如：
```json
{
  "friendly": "原神",
  "scene": "Scene-For-YS",
  "packages": [
    "com.miHoYo.Yuanshen",
    "com.miHoYo.ys.mi",
    "com.miHoYo.ys.bilibili",
    "com.miHoYo.GenshinImpact"
  ],
  "sensors": [
    {
      "sensor": "/sys/devices/platform/charger/power_supply/battery/capacity",
      "logger": false,
      "disable": false,
      "interval": 5000,
      "props": [],
      "rules": [
        {
          "threshold": [-1, 15],
          "note": "[capacity] < MAX && [capacity] >= 15, Removing GPU restrictions",
          "enter_once" : [],
          "enter": [
            ["/proc/mali/dvfs_enable", "1"],
            ["/proc/gpufreq/gpufreq_opp_freq", "0"]
          ],
          "values": []
        },
        {
          "threshold": [16, -1],
          "note": "[capacity] < 16 && [capacity] >= MIN, GPU limited to 370MHz",
          "enter_once" : [],
          "enter": [
            ["/proc/mali/dvfs_enable", "0"],
            ["/proc/gpufreq/gpufreq_opp_freq", "370000"]
          ],
          "values": []
        }
      ]
    }
  ]
}
```

> 这个示例说的是，每5秒读取一次电池电量百分比<br>
> 如果电量百分比 >= 15，恢复GPU频率<br>
> 如果电量百分比 < 16，限制GPU频率为370Mhz<br>

> threshold是个范围，由两个值组成，判断逻辑为 ＜ [value1] && >= [value2]，其中 `-1` 表示无限制<br>
> interval指轮询间隔，单位是毫秒<br>
> enter 规则命中时执行的属性修改和函数调用，连续命中同一规则会重复执行<br>
> enter_once 规则命中时执行的属性修改和函数调用，连续命中同一规则时只会执行一次<br>
> note是个注释属性，与运行逻辑无关<br>
> props 规则将要修改的属性 *该配置只与values相关，与enter和enter_once无关<br>
> values 与props对应的各个值<br>

#### sensor rule配置改进写法
- 大多数情况下，rule所做的事都是对同一属性进行修改
- 因此enter配置这种需要重复指定属性和值的做法略显啰嗦
- 因此它可以被简化为单独指定props，和不同rule下的values
- 例如，我想根据电池温度来改变处理器性能，可以

```json
{
  "sensor": "/sys/class/power_supply/battery/temp",
  "interval": 2000,
  "props": ["$gpu_freq", "$ddr_freq_min", "$cpu_max_0", "$cpu_max_4", "$cpu_max_7"],
  "rules": [
    { "threshold": [ -1, 491], "values": ["3200000000", "1800000", "1700000", "1800000"] },
    { "threshold": [490, 471], "values": ["3200000000", "1800000", "1800000", "2000000"] },
    { "threshold": [470, 441], "values": ["4266000000", "1900000", "2000000", "2100000"] },
    { "threshold": [440,  -1], "values": ["4266000000", "2000000", "2150000", "2300000"] }
  ]
}
```



### 线程CPU亲和 `affinity`
- 你可能听说过，绝大多数书Unity游戏，都有个叫`UnityMain`的线程CPU占用极高
- 大多数情况下，内核会根据实际负载需要决定要不要将任务迁移到`Big`核心
- 但不排除有些时候，系统会为了节省电力故意降低调用`Big`核心的积极性
- 对于这种情况，我们可能会手动改变线程的放置来提高游戏流畅性
- Scene提供的CPU亲和设置配置格式如下：

```json
{
  "friendly": "原神",
  "scene": "Scene-For-YS",
  "packages": ["com.miHoYo.Yuanshen"],
  "affinity": {
    "repeat": 0,
    "interval": 5000,
    "cpuset_mode": "off",
    "unity_main": "80",
    "heavy_thread": "UnityGfx",
    "heavy_mask": "70",
    "comm": {
      "70": ["UnityMultiRende", "mali-cmar-backe"],
      "F": ["Worker Thread", "AudioTrack", "Audio"]
    },
    "other": "7f"
  }
}
```

- `other` 配置是可选的，为空或不配置时将略过名称未出现在`comm`配置中的线程
- `unity_main` 配置也是可选的，用于指定UnityMain线程的Affinity mask。如果进程中存在多个UnityMain线程，则只会命中负载最高的那一个。
- `heavy_thread` 配置也是可选的，需与heavy_thread配合使用，用于指定重负载线程的名称。如果进程中存在多个同名线程，则只会命中负载最高的那一个。
- `heavy_mask` 需与heavy_thread配合使用，用于指定重负载线程的Affinity mask。
- `repeat` 是重复检查线程亲和设置的最大次数，配置为`0`表示无限次，默认为0
- `interval` 是线程亲和设置检查时间间隔，最小值为`50` 默认值为`5000`，单位是毫秒
- `cpuset_mode` 是framework 130中新增的属性，可设为 coexist | always | off
> coexist 使用affinity设置的同时，同时使用cpuset加强约束，二者协同让线程放置更加稳固 <br>
> always 使用cpuset代替affinity，相当于自动翻译成cpuset配置 <br>
> off 默认

- 你没看懂上面这些 `80`、`70`、`F`、`7f` 是什么意思？
  > 这是一个16进制数，表示的是用哪些核心，比如<br>
  > 把`80`转成2进制，就是 `10000000`，8位数字，这下是否明白了呢？<br>
  > 把`70`转成2进制，就是 `1110000`，7位数，补1个0，补够8位即`01110000`<br>
  > 把`f`转成2进制，就是 `1111`，4位数，补4个0，补够8位即`00001111`<br>

- 想必这下你已经看明白了，它其实是用`0`和`1`来表示是否使用某个核心<br>
  > `80`即`10000000`，表示`CPU7`<br>
  > `70`即`01110000`，表示`CPU6~4`<br>
  > `f`即`00001111`，表示`CPU3~0`


### 线程CPU核心配置 `cpuset`
- 它的作用与affinity类似，都是用于限制或指定线程使用的CPU核心
- 而区别在于cpuset模式具有更强的约束，用于对抗系统自身对affinity的修改
- 它的配置方式与affinity非常相似，
- 它使用类似于0-7的方式表示核心，而非像affinity一样使用16进制的mask

```json
{
  "friendly": "原神",
  "scene": "Scene-For-YS",
  "packages": ["com.miHoYo.Yuanshen"],
  "cpuset": {
    "repeat": 0,
    "interval": 5000,
    "comm": {
      "7": ["UnityMain"],
      "4-6": ["UnityGfxDevice", "UnityMultiRende", "mali-cmar-backe"],
      "0-3": ["Worker Thread", "AudioTrack", "Audio"]
    },
    "other": "0-6"
  }
}
```

- `other` 配置是可选的，为空或不配置时将略过名称未出现在`comm`配置中的线程
- `unity_main` 配置也是可选的，用于指定UnityMain线程可以使用的cpu核心。如果进程中存在多个UnityMain线程，则只会命中负载最高的那一个。
- `heavy_thread` 配置也是可选的，需与heavy_thread配合使用，用于指定重负载线程的名称。如果进程中存在多个同名线程，则只会命中负载最高的那一个。
- `heavy_mask` 需与heavy_thread配合使用，用于指定重负载线程可以使用的cpu核心。
- `repeat` 是重复检查线程亲和设置的最大次数，配置为`0`表示无限次，默认为0
- `interval` 是线程亲和设置检查时间间隔，最小值为`50` 默认值为`5000`，单位是毫秒


> 需要注意的是，cpuset并非affinity的完美替代 <br>
> 例如，我们指定一个线程可以运行在0-6，但系统可以设定该线程affinity mask为f<br>
> 因此，该线程可能会一直运行在小核上，而不是我们预期的使用核心0-6


### 辅助升频 `booster`
- Scene提供了辅助升频，不过目前只实现了监听`InputDevice`作为触发条件(也就是增强版的触摸升频)
- 使用方法例如：

```json
{
  "booster": {
    "events": ["presets"],
    "duration": 3000,
    "idle_delay": 5000,
    "enter": [
      ["/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq", "951000"]
    ],
    "exit": [
      ["/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq", "255000"]
    ]
  }
}
```
- 配置格式一目了然，通过[events]指定设备触发升频的事件
> 其中 `touch`、`buttons`、`presets` 是Scene预设的输入事件，分别代表 触摸、按键按下、触摸和按键按下，<br>
> 某些时候，Scene可能会无法正确找到`touch`、`buttons`对应的输入设备<br>
> 因此，你还可以在[events]中指定具体输入设备名称，让Scene去监听它来响应输入升频
- [duration] 是boost持续时长，单位为毫秒
- [enter] 用于配置进入boost状态要执行的属性修改，支持像[Call]一样调用内置函数(但不建议使用)
- [exit] 用于配置退出boost状态要执行的属性修改，支持像[Call]一样调用内置函数(但不建议使用)
- [idle_delay] 指定用户打开应用多少毫秒后，从未有过触摸/按键操作，执行退出boost状态的修改

##### 自动备份/恢复
- Scene在执行进入boost状态执行[enter]指定的修改前，
- 会尽量读取备份对应当前值，并在执行[exit]修改时自动恢复
-  不支持备份/恢复调用内置函数造成的修改
- 由于系统往往有自己的boost逻辑，Scene可能会备份到错误的值
- 因此，如果你愿意勤快点的话，建议保持[exit]与[enter]指定的属性对应

##### 使用函数
- [enter]和[exit]均支持像配置[call]一样，调用Scene内置函数
- 但调用内置函数框架不具备自动备份还原机制
- 因此如果你在[enter]里调用函数做了什么修改
- 务必[exit]中调用相同的函数来还原参数，例如：

```json
{
  "booster": {
    "events": ["presets"],
    "duration": 3000,
    "enter": [
      ["@cpu_freq_min", "1.4Ghz"]
    ],
    "exit": [
      ["@cpu_freq_min", "300MHz"]
    ]
  }
}
```


### 场景下的模式细分 `modes`
- 我们准备对`原神`做一些针对性调整，并应用于`powersave`和`balance`模式
- 针对一个场景下的某一个模式(powersave、balance等)，
- 可以配置`call`, `booster`, `affinity`, `sensors`
- 示例如下：

```json
{
  "friendly": "原神",
  "scene": "Scene-For-YS",
  "packages": [
    "com.miHoYo.Yuanshen",
    "com.miHoYo.ys.mi",
    "com.miHoYo.ys.bilibili",
    "com.miHoYo.GenshinImpact"
  ],
  "modes": [
    {
      "mode": ["powersave", "balance"],
      "logger": false,
      "disable": false,
      "call": [],
      "affinity": {
        "comm": {
          "80": ["UnityMain"],
          "70": ["UnityGfxDevice", "UnityMultiRende"],
          "F": ["Worker Thread", "AudioTrack", "Audio"]
        },
        "other": "7f"
      },
      "booster": {
        "events": ["touch", "buttons"],
        "duration": 2000,
        "enter": [],
        "exit": []
      }
    }
  ]
}
```

#### 精确到[mode]的affinity配置
- 如果同时存在场景级(`app`)的`affinity`配置和[mode]级的`affinity`配置，那么会优先使用[mode]级的配置
- 你也可以配置场景级的`affinity`，再针对某个`mode`单独设置`affinity`，例如
```json
{
  "friendly": "原神",
  "scene": "Scene-For-YS",
  "packages": ["com.miHoYo.Yuanshen"],
  "affinity": {
    "comm": {
      "80": ["UnityMain"],
      "40": ["UnityGfxDevice"],
      "3F": ["UnityMultiRende"],
      "F": ["Worker Thread", "AudioTrack", "Audio"]
    },
    "other": "7f"
  },
  "modes": [
    {
      "mode": ["powersave", "balance"],
      "affinity": {
        "comm": {
          "80": ["UnityMain"],
          "70": ["UnityGfxDevice", "UnityMultiRende"],
          "F": ["Worker Thread", "AudioTrack", "Audio"]
        },
        "other": "7f"
      }
    }
  ]
}
```

#### 精确到[mode]的sensors配置
- 如果同时存在场景级(`app`)的`sensors`配置和[mode]级的`sensors`配置，那么会优先使用[mode]级的配置
- 你也可以配置场景级的`sensors`，再针对某个`mode`单独设置`sensors`，例如
```json
{
  "friendly": "原神",
  "scene": "Scene-For-YS",
  "packages": ["com.miHoYo.Yuanshen"],
  "sensors": [],
  "modes": [
    {
      "mode": ["powersave", "balance"],
      "sensors": []
    }
  ]
}
```

#### 精确到[mode]的booster配置
- 如果同时存在场景级(`app`)的`booster`配置和[mode]级的`booster`配置，那么会优先使用[mode]级的配置
- 你也可以配置场景级的`booster`，再针对某个`mode`单独设置`booster`，例如
```json
{
  "friendly": "原神",
  "scene": "Scene-For-YS",
  "packages": ["com.miHoYo.Yuanshen"],
  "booster": {},
  "modes": [
    {
      "mode": ["powersave", "balance"],
      "booster": {},
    }
  ]
}
```

#### 模式通配
- `mode` 属性可以指定多个模式，但如果你想让这组配置匹配所有模式，可不用五个模式都写上去，你可以直接写["*"]
```json
{
  "modes": [
    {
      "mode": ["powersave", "balance"],
      "affinity": {
      }
    },
    {
      "mode": ["*"],
      "affinity": {
      }
    }
  ]
}
```


### Utilization Clamping @uclamp
- uclamp作为schedtune的替代方案，在Linux Kernel中引入
- 因此，并非所有设备都能使用该特性
- @uclamp具有至多3个参数，用法非常简单
- 例如：
```json
["@uclamp", "0.00~max", "0.00~max", "0.00~max"]
```
- 3个参数分别对应cpuctl中background、foreground、top-app的cpu.uclamp.min和cpu.uclamp.max，两个值之间以 ~ 符号分隔

### 经典调速器 @classical
- 该函数用于降指定核心的调速器切换为`conservative`或相似的调速器，并设定相关参数
- 用法如：
```json
["@classical", "cpu0", "70", "60", "3", "1"]
```
- 5个参数分别代表 [CPU核心或丛集] [up_threshold] [down_threshold] [freq_step] [sampling_down_factor]
- 此处[CPU核心或丛集] 的表述方式与@cpufreq相同，支持 `cpu4` `policy4` `cluster1`这些格式
- 该函数会将conservative调速器的sampling_rate会统一设为8ms，ignore_nice_load 设为0


### 高刷切换 `@high_rate`
- 通过 @high_rate "on"|"off"在高低刷新率之间切换
- 这对某些刷新率管理不完善的系统非常有用，但只建议在搭载LTPS OLED屏幕的设备上使用
- 但在使用该函数之前，你需要通过features按设备(device)配置高/低刷新率状态对应的DisplayModeID

```json
{
  "platform": "mt6895",
  "platform_name": "D8100",
  "framework": 130,
  "features": {
    "high_rate": {
      "enable": true,
      "enable_control": "/data/local/tmp/scene_refresh_rate",
      "device_policy": [
        { "device": "rubens", "enable": true, "mode_high_rate": "1", "mode_low_rate": "0" },
        { "device": "OP5565", "enable": true, "mode_high_rate": "1", "mode_low_rate": "0" }
      ]
    }
  }
}
```

- device 可以通过 `getprop ro.product.device` 获取
- mode_high_rate 高刷状态的DisplayModeID
- mode_low_rate 低刷状态的DisplayModeID
- enable_control 指定一个控制@high_rate函数启用状态的额外控制文件
    > enable_control 通常固定为 /data/local/tmp/scene_refresh_rate<br>
    > 如果指定了文件则必须向该文件写入1才能启用@high_rate函数


### 充电控制 `@charge_control`
- 通过 @charge "suspend"|"normal"切换两种模式
- 但该函数并未提供具体的实现，因此你需要在suspend和normal节点配置实际要进行的修改操作

```json
{
  "platform": "mt6895",
  "platform_name": "D8100",
  "framework": 130,
  "features": {
    "charge_control": {
      "enable": true,
      "enable_control": "/data/local/tmp/scene_charge_control",
      "suspend": [
        ["$charge_limit", "15"],
        ["$night_charging", "1"]
      ],
      "normal": [
        ["$charge_limit", "0"],
        ["$night_charging", "0"]
      ]
    }
  },
  "schemes": {
    "powersave": {
      "call": [
        ["@charge", "normal"]
      ]
    }
  }
}
```

- enable_control 指定一个控制@high_rate函数启用状态的额外控制文件
    > enable_control 通常固定为 /data/local/tmp/scene_charge_control<br>
    > 如果指定了文件则必须向该文件写入1才能启用@high_rate函数


### 预设 `@preset`
- 如果你有一些需要重复使用的公共设定，那么通过预设引用将会非常方便
- 例如，这是一段不使用预设的原始配置：
```json
{
  "schemes": {
    "powersave": {
      "call": [
        ["$cpufreq", "0 450000 2000000"],
        ["$cpufreq", "4 200000 2850000"],
        ["$cpufreq", "7 500000 2850000"],
        ["@uclamp", "0.00~max", "0.00~max", "0.1~max"],
        ["@cpuset", "2-3", "0-4", "0-6", "0-7"]
      ]
    },
    "balance": {
      "call": [
        ["$cpufreq", "0 450000 2000000"],
        ["$cpufreq", "4 200000 2850000"],
        ["$cpufreq", "7 500000 2850000"],
        ["@uclamp", "0.00~max", "0.00~max", "0.1~max"],
        ["@cpuset", "0-3", "0-4", "0-6", "0-7"]
      ]
    },
  }
}
```
- 你看，这里有非常多的重复代码。因此，你为这些重复的内容创建一组预设，就像这样：
```json
{
  "presets": {
    "set_001": [
      ["$cpufreq", "0 450000 2000000"],
      ["$cpufreq", "4 200000 2850000"],
      ["$cpufreq", "7 500000 2850000"],
      ["@uclamp", "0.00~max", "0.00~max", "0.1~max"]
    ]
  },
  "schemes": {
    "powersave": {
      "call": [
        ["@preset", "set_001"],
        ["@cpuset", "2-3", "0-4", "0-6", "0-7"]
      ]
    },
    "balance": {
      "call": [
        ["@preset", "set_001"],
        ["@cpuset", "0-3", "0-4", "0-6", "0-7"]
      ]
    },
  }
}
```
- 看起来是不是好多了，同时`@preset`函数还支持一次性使用多个预设，像 `["@preset", "set_001", "set_002"]` 这样


### 非核心函数
- 出现于SCENE自带配置中且未列入文档的函数，通常由严格的设备和SOC幸好要求
- 该类函数不作为框架的主要特性，也不保证其用法和作用会始终保持一致

## 结尾
- 注意，文中所有示例代码，仅用于展示框架功能，并非性能优化最佳实践
