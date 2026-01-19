package com.omarea.vtools.popup

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Rect
import android.os.Build
import android.provider.Settings
import android.view.*
import android.view.WindowManager.LayoutParams
import android.widget.*
import com.omarea.Scene
import com.omarea.common.shared.FileWrite
import com.omarea.common.shell.KeepShellPublic
import com.omarea.data.EventBus
import com.omarea.data.EventType
import com.omarea.library.permissions.NotificationListener
import com.omarea.library.shell.LocationHelper
import com.omarea.scene_mode.ModeSwitcher
import com.omarea.store.SceneConfigStore
import com.omarea.store.SpfConfig
import com.omarea.utils.AccessibleServiceHelper
import com.omarea.vtools.R
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch

/**
 * 弹窗辅助类
 *
 * @ClassName WindowUtils
 */
class FloatPowercfgSelector(context: Context) {
    private val mContext: Context = context.applicationContext
    private var mView: View? = null
    private var modeSwitcher = ModeSwitcher()
    private data class RefreshMode(val id: Int, val label: String)

    /**
     * 显示弹出框
     *
     * @param context
     */
    fun open(packageName: String) {
        if (isShown!!) {
            return
        }

        isShown = true
        // 获取WindowManager
        mWindowManager = mContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager

        this.mView = setUpView(mContext, packageName)

        val params = LayoutParams()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (Settings.canDrawOverlays(this.mContext)) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {//6.0+
                    params.type = LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    params.type = LayoutParams.TYPE_SYSTEM_ALERT
                }
            } else {
                params.type = LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
            }
        } else {
            params.type = LayoutParams.TYPE_SYSTEM_ALERT
        }

        // 设置flag

        val flags = LayoutParams.FLAG_ALT_FOCUSABLE_IM
        flags.and(LayoutParams.FLAG_FULLSCREEN)
        // | LayoutParams.FLAG_NOT_FOCUSABLE;
        // 如果设置了LayoutParams.FLAG_NOT_FOCUSABLE，弹出的View收不到Back键的事件
        params.flags = flags
        // 不设置这个弹出框的透明遮罩显示为黑色
        params.format = PixelFormat.TRANSLUCENT
        // FLAG_NOT_TOUCH_MODAL不阻塞事件传递到后面的窗口
        // 设置 FLAG_NOT_FOCUSABLE 悬浮窗口较小时，后面的应用图标由不可长按变为可长按
        // 不设置这个flag的话，home页的划屏会有问题

        params.width = LayoutParams.MATCH_PARENT
        params.height = LayoutParams.MATCH_PARENT

        params.gravity = Gravity.CENTER
        params.windowAnimations = R.style.windowAnim

        mWindowManager!!.addView(mView, params)
    }

    /**
     * 隐藏弹出框
     */
    fun close() {
        if (isShown!! &&
                null != this.mView) {
            mWindowManager!!.removeView(mView)
            isShown = false
        }
    }

    /**
     * 重启辅助服务
     */
    private fun reStartService(app: String, mode: String) {
        if (AccessibleServiceHelper().serviceRunning(mContext)) {
            EventBus.publish(EventType.SCENE_APP_CONFIG, HashMap<String, Any>().apply {
                put("app", app)
                put("mode", mode)
            })
        }
    }

    private fun setUpView(context: Context, packageName: String): View {
        val store = SceneConfigStore(context)
        val appConfig = store.getAppConfig(packageName)

        val view = LayoutInflater.from(context).inflate(R.layout.fw_powercfg_selector, null)
        val titleView = view.findViewById<TextView>(R.id.fw_title)

        val powerCfgSPF = context.getSharedPreferences(SpfConfig.POWER_CONFIG_SPF, Context.MODE_PRIVATE)
        val globalSPF = context.getSharedPreferences(SpfConfig.GLOBAL_SPF, Context.MODE_PRIVATE)
        val serviceRunning = AccessibleServiceHelper().serviceRunning(context)
        var dynamic = serviceRunning && globalSPF.getBoolean(SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL, SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL_DEFAULT)
        val defaultMode = globalSPF.getString(SpfConfig.GLOBAL_SPF_POWERCFG_FIRST_MODE, ModeSwitcher.BALANCE)
        var selectedMode = (if (dynamic) powerCfgSPF.getString(packageName, defaultMode) else ModeSwitcher.getCurrentPowerMode())!!
        val modeConfigCompleted = modeSwitcher.modeConfigCompleted()

        try {
            val pm = context.packageManager
            val packageInfo = pm.getPackageInfo(packageName, 0)
            val appInfo = packageInfo.applicationInfo
            titleView.text = appInfo?.loadLabel(pm)?.toString() ?: packageName
        } catch (ex: Exception) {
            titleView.text = packageName
        }

        val btn_powersave = view.findViewById<TextView>(R.id.btn_powersave)
        val btn_defaultmode = view.findViewById<TextView>(R.id.btn_defaultmode)
        val btn_gamemode = view.findViewById<TextView>(R.id.btn_gamemode)
        val btn_fastmode = view.findViewById<TextView>(R.id.btn_fastmode)
        val btn_ignore = view.findViewById<TextView>(R.id.btn_ignore)
        val refreshRateRow = view.findViewById<LinearLayout>(R.id.fw_refresh_rate_row)
        val refreshRateButtons = view.findViewById<LinearLayout>(R.id.fw_refresh_rate_buttons)
        val refreshRateViewRow = view.findViewById<LinearLayout>(R.id.fw_refresh_rate_view_row)
        val refreshRateViewButtons = view.findViewById<LinearLayout>(R.id.fw_refresh_rate_view_buttons)

        if (!context.getSharedPreferences(SpfConfig.GLOBAL_SPF, Context.MODE_PRIVATE).getBoolean(SpfConfig.GLOBAL_SPF_NIGHT_MODE, false)) {
            view.findViewById<LinearLayout>(R.id.popup_window).setBackgroundColor(Color.WHITE)
            titleView.setTextColor(Color.BLACK)
        }

        GlobalScope.launch(Dispatchers.IO) {
            val modes = loadRefreshModes(context)
            GlobalScope.launch(Dispatchers.Main) {
                if (modes.isNotEmpty()) {
                    refreshRateButtons.removeAllViews()
                    val paddingH = (6 * context.resources.displayMetrics.density).toInt()
                    val paddingV = (4 * context.resources.displayMetrics.density).toInt()
                    var selectedId = getActiveRefreshModeId() ?: modes.firstOrNull()?.id

                    val updateSelection = {
                        for (i in 0 until refreshRateButtons.childCount) {
                            val button = refreshRateButtons.getChildAt(i) as TextView
                            val isSelected = (button.tag as? Int) == selectedId
                            button.setTextColor(if (isSelected) Color.WHITE else 0x66ffffff)
                        }
                    }

                    modes.forEach { mode ->
                        val button = TextView(context)
                        button.text = mode.label
                        button.tag = mode.id
                        button.setPadding(paddingH, paddingV, paddingH, paddingV)
                        button.setBackgroundResource(R.drawable.powercfg_balance)
                        button.textSize = 12f
                        button.setTextColor(0x66ffffff)
                        button.setOnClickListener {
                            selectedId = mode.id
                            updateSelection()
                            KeepShellPublic.doCmdSync("service call SurfaceFlinger 1035 i32 ${mode.id}")
                        }
                        val params = LinearLayout.LayoutParams(
                            LinearLayout.LayoutParams.WRAP_CONTENT,
                            LinearLayout.LayoutParams.WRAP_CONTENT
                        )
                        params.marginEnd = (6 * context.resources.displayMetrics.density).toInt()
                        button.layoutParams = params
                        refreshRateButtons.addView(button)
                    }
                    updateSelection()
                } else {
                    refreshRateRow.visibility = View.GONE
                }
                refreshRateViewButtons.removeAllViews()
                val paddingH = (6 * context.resources.displayMetrics.density).toInt()
                val paddingV = (4 * context.resources.displayMetrics.density).toInt()
                val offButton = TextView(context)
                offButton.text = "OFF"
                offButton.setPadding(paddingH, paddingV, paddingH, paddingV)
                offButton.setBackgroundResource(R.drawable.powercfg_balance)
                offButton.textSize = 12f
                offButton.setTextColor(Color.WHITE)
                offButton.setOnClickListener {
                    KeepShellPublic.doCmdSync("service call SurfaceFlinger 1034 i32 0")
                }

                val onButton = TextView(context)
                onButton.text = "ON"
                onButton.setPadding(paddingH, paddingV, paddingH, paddingV)
                onButton.setBackgroundResource(R.drawable.powercfg_balance)
                onButton.textSize = 12f
                onButton.setTextColor(Color.WHITE)
                onButton.setOnClickListener {
                    KeepShellPublic.doCmdSync("service call SurfaceFlinger 1034 i32 1")
                }

                val params = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
                params.marginEnd = (6 * context.resources.displayMetrics.density).toInt()
                offButton.layoutParams = params
                onButton.layoutParams = params
                refreshRateViewButtons.addView(offButton)
                refreshRateViewButtons.addView(onButton)
            }
        }

        val updateUI = Runnable {
            btn_powersave.setTextColor(0x66ffffff)
            btn_defaultmode.setTextColor(0x66ffffff)
            btn_gamemode.setTextColor(0x66ffffff)
            btn_fastmode.setTextColor(0x66ffffff)
            btn_ignore.setTextColor(0x66ffffff)
            when (selectedMode) {
                ModeSwitcher.BALANCE -> btn_defaultmode.setTextColor(Color.WHITE)
                ModeSwitcher.PERFORMANCE -> btn_gamemode.setTextColor(Color.WHITE)
                ModeSwitcher.POWERSAVE -> btn_powersave.setTextColor(Color.WHITE)
                ModeSwitcher.FAST -> btn_fastmode.setTextColor(Color.WHITE)
                ModeSwitcher.IGONED -> btn_ignore.setTextColor(Color.WHITE)
            }
        }

        val switchMode = Runnable {
            updateUI.run()
            modeSwitcher.executePowercfgMode(selectedMode, packageName)
            if (dynamic) {
                if (!packageName.equals(context.packageName)) {
                    if (selectedMode == defaultMode) {
                        powerCfgSPF.edit().remove(packageName).apply()
                    } else {
                        powerCfgSPF.edit().putString(packageName, selectedMode).apply()
                    }
                    reStartService(packageName, selectedMode)
                }
                EventBus.publish(EventType.SCENE_MODE_ACTION)
            }
        }

        // 性能调节（动态响应）
        view.findViewById<CompoundButton>(R.id.fw_dynamic_state).run {
            isChecked = dynamic
            isEnabled = serviceRunning && modeConfigCompleted
            setOnClickListener {
                globalSPF.edit().putBoolean(SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL, (it as Switch).isChecked).apply()
                EventBus.publish(EventType.SCENE_CONFIG)
                dynamic = isChecked

                btn_ignore.visibility = if (dynamic) View.VISIBLE else View.GONE

                if (dynamic) {
                    val mode = powerCfgSPF.getString(packageName, defaultMode)
                    if (mode != null && selectedMode != mode) {
                        selectedMode = mode
                        switchMode.run()
                    }
                } else {
                    selectedMode = ModeSwitcher.getCurrentPowerMode()
                    updateUI.run()
                }
            }
        }
        btn_ignore.visibility = if (dynamic) View.VISIBLE else View.GONE

        // 震动反馈
        val hapticFeedback = Runnable {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                GlobalScope.launch(Dispatchers.IO) {
                    try {
                        view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                    } catch (ex: Exception) {}
                }
            }
        }

        if (modeConfigCompleted) {
            btn_powersave.setOnClickListener {
                hapticFeedback.run()
                selectedMode = ModeSwitcher.POWERSAVE
                switchMode.run()
            }
            btn_defaultmode.setOnClickListener {
                hapticFeedback.run()
                selectedMode = ModeSwitcher.BALANCE
                switchMode.run()
            }
            btn_gamemode.setOnClickListener {
                hapticFeedback.run()
                selectedMode = ModeSwitcher.PERFORMANCE
                switchMode.run()
            }
            btn_fastmode.setOnClickListener {
                hapticFeedback.run()
                selectedMode = ModeSwitcher.FAST
                switchMode.run()
            }
            btn_ignore.setOnClickListener {
                hapticFeedback.run()
                if (dynamic) {
                    if (selectedMode != ModeSwitcher.IGONED) {
                        selectedMode = ModeSwitcher.IGONED
                        switchMode.run()
                        Toast.makeText(context, "Please return to the desktop and reopen the currently active application to make the configuration effective~", Toast.LENGTH_LONG).show()
                    }
                } else {
                    Toast.makeText(context, "This option can only be set for a single application when [Dynamic Response] is turned on~", Toast.LENGTH_LONG).show()
                }
            }
        }

        // 独立亮度
        val fw_app_light = view.findViewById<CheckBox>(R.id.fw_app_light).apply {
            isChecked = appConfig.aloneLight
            setOnClickListener {
                val isChecked = (it as CheckBox).isChecked
                appConfig.aloneLight = isChecked
                store.setAppConfig(appConfig)

                notifyAppConfigChanged(packageName)
            }
        }
        // 禁止通知
        val fw_app_dis_notice = view.findViewById<CheckBox>(R.id.fw_app_dis_notice).apply {
            isChecked = appConfig.disNotice
            setOnClickListener {
                val isChecked = (it as CheckBox).isChecked

                if (isChecked) {
                    if (!NotificationListener().getPermission(context)) {
                        NotificationListener().setPermission(context)
                        Toast.makeText(context, context.getString(R.string.scene_need_notic_listing), Toast.LENGTH_SHORT).show()
                        it.isChecked = false
                        return@setOnClickListener
                    }
                }
                appConfig.disNotice = isChecked
                store.setAppConfig(appConfig)

                notifyAppConfigChanged(packageName)
            }
        }

        // GPS开关
        val fw_app_gps = view.findViewById<CheckBox>(R.id.fw_app_gps).apply {
            isChecked = appConfig.gpsOn
            setOnClickListener {
                val isChecked = (it as CheckBox).isChecked
                appConfig.gpsOn = isChecked
                store.setAppConfig(appConfig)
                if (isChecked) {
                    LocationHelper().enableGPS()
                } else {
                    LocationHelper().disableGPS()
                }
                notifyAppConfigChanged(packageName)
            }
        }

        // 设置悬浮窗状态
        setDialogState(view)

        // 设置监视器开关按钮
        setMonitor(view)

        if (!serviceRunning || packageName.equals(context.packageName)) {
            fw_app_light.isEnabled = false
            fw_app_dis_notice.isEnabled = false
            fw_app_gps.isEnabled = false
        }


        updateUI.run()
        return view
    }

    private fun loadRefreshModes(context: Context): List<RefreshMode> {
        val scriptPath = FileWrite.writePrivateShellFile("kr-script/display/display_modes.sh", "display_modes.sh", context)
        if (scriptPath.isNullOrEmpty()) {
            return emptyList()
        }
        val output = KeepShellPublic.doCmdSync("sh $scriptPath 2>/dev/null").trim()
        if (output.isEmpty()) {
            return emptyList()
        }
        return output.split("\n").mapNotNull { line ->
            val parts = line.split("|", limit = 2)
            if (parts.size != 2) {
                return@mapNotNull null
            }
            val id = parts[0].trim().toIntOrNull() ?: return@mapNotNull null
            val label = parts[1].trim()
            RefreshMode(id, label)
        }
    }

    private fun getActiveRefreshModeId(): Int? {
        val output = KeepShellPublic.doCmdSync("dumpsys display").trim()
        val activeSf = Regex("mActiveSfDisplayMode=DisplayMode\\{id=([0-9]+)").find(output)?.groupValues?.getOrNull(1)?.toIntOrNull()
        return activeSf
    }


    // 设置悬浮窗状态
    private fun setDialogState (view: View) {
        // 点击窗口外部区域可消除
        // 这点的实现主要将悬浮窗设置为全屏大小，外层有个透明背景，中间一部分视为内容区域
        // 所以点击内容区域外部视为点击悬浮窗外部
        val popupWindowView = view.findViewById<View>(R.id.popup_window)// 非透明的内容区域

        view.setOnTouchListener { v, event ->
            val x = event.x.toInt()
            val y = event.y.toInt()
            val rect = Rect()
            popupWindowView.getGlobalVisibleRect(rect)
            if (!rect.contains(x, y)) {
                close()
            }
            false
        }

        // 点击back键可消除
        view.setOnKeyListener { v, keyCode, event ->
            when (keyCode) {
                KeyEvent.KEYCODE_BACK -> {
                    close()
                    true
                }
                else -> false
            }
        }

        view.findViewById<ImageButton>(R.id.fw_float_close).setOnClickListener {
            close()
        }
    }

    // 设置监视器开关按钮
    private fun setMonitor (view: View) {
        // 性能监视悬浮窗开关
        view.findViewById<View>(R.id.fw_float_monitor).run {
            alpha = if (FloatMonitor.show == true) 1f else 0.5f
            setOnClickListener {
                if (FloatMonitor.show == true) {
                    FloatMonitor(context).hidePopupWindow()
                    it.alpha = 0.3f
                } else {
                    FloatMonitor(context).showPopupWindow()
                    it.alpha = 1f
                }
            }
        }

        // mini监视悬浮窗开关
        view.findViewById<View>(R.id.fw_float_monitor_mini).run {
            alpha = if (FloatMonitorMini.show == true) 1f else 0.5f
            setOnClickListener {
                if (FloatMonitorMini.show == true) {
                    FloatMonitorMini(context).hidePopupWindow()
                    it.alpha = 0.3f
                } else {
                    FloatMonitorMini(context).showPopupWindow()
                    it.alpha = 1f
                }
            }
        }

        // 进程管理器
        view.findViewById<View>(R.id.fw_float_task).run {
            alpha = if (FloatTaskManager.show) 1f else 0.5f
            setOnClickListener {
                if (FloatTaskManager.show) {
                    FloatTaskManager(context).hidePopupWindow()
                    it.alpha = 0.3f
                } else {
                    val floatTaskManager = FloatTaskManager(context)
                    if (floatTaskManager.supported) {
                        floatTaskManager.showPopupWindow()
                        it.alpha = 1f
                    } else {
                        Scene.toast(context.getString(R.string.monitor_process_unsupported), Toast.LENGTH_SHORT)
                    }
                }
            }
        }
    }

    private fun notifyAppConfigChanged(app: String) {
        EventBus.publish(EventType.SCENE_APP_CONFIG, HashMap<String, Any>().apply {
            put("app", app)
        })
    }

    companion object {
        private var mWindowManager: WindowManager? = null
        var isShown: Boolean? = false
    }
}
