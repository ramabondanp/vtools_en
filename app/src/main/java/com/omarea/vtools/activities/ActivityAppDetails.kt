package com.omarea.vtools.activities

import android.annotation.SuppressLint
import android.content.Context
import android.content.SharedPreferences
import android.content.pm.PackageInfo
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.Checkable
import android.widget.Switch
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.widget.Toolbar
import com.omarea.common.ui.DialogHelper
import com.omarea.data.EventBus
import com.omarea.data.EventType
import com.omarea.library.permissions.NotificationListener
import com.omarea.library.shell.CGroupMemoryUtlis
import com.omarea.model.SceneConfigInfo
import com.omarea.permissions.WriteSettings
import com.omarea.scene_mode.ImmersivePolicyControl
import com.omarea.scene_mode.ModeSwitcher
import com.omarea.scene_mode.SceneMode
import com.omarea.store.SceneConfigStore
import com.omarea.store.SpfConfig
import com.omarea.utils.AccessibleServiceHelper
import com.omarea.vtools.R
import com.omarea.vtools.dialogs.DialogAppBoostPolicy
import com.omarea.vtools.dialogs.DialogAppCGroupMem
import com.omarea.vtools.dialogs.DialogAppOrientation
import com.omarea.vtools.dialogs.DialogAppPowerConfig
import com.omarea.vtools.databinding.ActivityAppDetailsBinding

class ActivityAppDetails : ActivityBase() {
    var app = ""
    lateinit var immersivePolicyControl: ImmersivePolicyControl
    lateinit var sceneConfigInfo: SceneConfigInfo
    private var dynamicCpu: Boolean = false
    private var _result = RESULT_CANCELED
    private lateinit var sceneBlackList: SharedPreferences
    private lateinit var spfGlobal: SharedPreferences
    private lateinit var binding: ActivityAppDetailsBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAppDetailsBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val toolbar = findViewById<View>(R.id.toolbar) as Toolbar
        setSupportActionBar(toolbar)
        // setTitle(R.string.app_name)

        // 显示返回按钮
        supportActionBar!!.setHomeButtonEnabled(true)
        supportActionBar!!.setDisplayHomeAsUpEnabled(true)
        toolbar.setNavigationOnClickListener { _ ->
            // finish()
            saveConfigAndFinish()
        }

        spfGlobal = getSharedPreferences(SpfConfig.GLOBAL_SPF, Context.MODE_PRIVATE)

        val intent = this.intent
        if (intent == null) {
            setResult(_result, this.intent)
            finish()
            return
        }
        val extras = this.intent.extras
        if (extras == null || !extras.containsKey("app")) {
            setResult(_result, this.intent)
            finish()
            return
        }

        app = extras.getString("app")!!

        if (app == "android" || app == "com.android.systemui" || app == "com.android.webview" || app == "mokee.platform" || app == "com.miui.rom") {
            binding.appDetailsPerf.visibility = View.GONE
            binding.appDetailsAuto.visibility = View.GONE
            binding.appDetailsAssist.visibility = View.GONE
            binding.appDetailsFreeze.isEnabled = false
            binding.sceneModeConfig.visibility = View.GONE
            binding.sceneModeAllow.visibility = View.GONE
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            binding.appDetailsAssist.visibility = View.GONE
        }

        // 场景模式白名单开关
        sceneBlackList = getSharedPreferences(SpfConfig.SCENE_BLACK_LIST, Context.MODE_PRIVATE);
        binding.sceneModeAllow.setOnClickListener {
            val checked = (it as Checkable).isChecked
            binding.sceneModeConfig.visibility = if (checked) View.VISIBLE else View.GONE
            if (checked) {
                sceneBlackList.edit().remove(app).apply()
            } else {
                sceneBlackList.edit().putBoolean(app, true).apply()
            }
        }

        immersivePolicyControl = ImmersivePolicyControl(contentResolver)

        dynamicCpu = spfGlobal.getBoolean(SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL, SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL_DEFAULT)

        binding.appDetailsDynamic.setOnClickListener {
            if (!dynamicCpu) {
                DialogHelper.helpInfo(this, "", "Go back to the feature list, open [Performance config], and enable [Dynamic Response].")
                return@setOnClickListener
            }

            val spfPowercfg = getSharedPreferences(SpfConfig.POWER_CONFIG_SPF, Context.MODE_PRIVATE)

            DialogAppPowerConfig(this,
                    spfPowercfg.getString(app, ""),
                    object : DialogAppPowerConfig.IResultCallback {
                        override fun onChange(mode: String?) {
                            spfPowercfg.edit().run {
                                if (mode.isNullOrEmpty()) {
                                    remove(app)
                                } else {
                                    putString(app, mode)
                                }
                            }.apply()

                            (it as TextView).text = ModeSwitcher.getModName("" + mode)
                            _result = RESULT_OK
                            notifyService(app, "" + mode)
                        }
                    }).show()
        }

        binding.appDetailsCgroupMem.setOnClickListener {
            val utlis = CGroupMemoryUtlis(this)
            if (!utlis.isSupported) {
                DialogHelper.helpInfo(this, "", "Sorry, your kernel does not support this feature.")
                return@setOnClickListener
            }
            DialogAppCGroupMem(this, sceneConfigInfo.fgCGroupMem, object : DialogAppCGroupMem.IResultCallback {
                override fun onChange(group: String?, name: String?) {
                    sceneConfigInfo.fgCGroupMem = group
                    (it as TextView).text = name
                    _result = RESULT_OK
                }
            }).show()
        }


        binding.appDetailsCgroupMem2.setOnClickListener {
            val utlis = CGroupMemoryUtlis(this)
            if (!utlis.isSupported) {
                DialogHelper.helpInfo(this, "", "Sorry, your kernel does not support this feature.")
                return@setOnClickListener
            }

            DialogAppCGroupMem(this, sceneConfigInfo.bgCGroupMem, object : DialogAppCGroupMem.IResultCallback {
                override fun onChange(group: String?, name: String?) {
                    sceneConfigInfo.bgCGroupMem = group
                    (it as TextView).text = name
                    _result = RESULT_OK
                }
            }).show()
        }

        binding.appDetailsBoostMem.setOnClickListener {
            DialogAppBoostPolicy(this, sceneConfigInfo.dynamicBoostMem, object : DialogAppBoostPolicy.IResultCallback {
                override fun onChange(enabled: Boolean) {
                    sceneConfigInfo.dynamicBoostMem = enabled
                    (it as TextView).text = if (enabled) "Enabled" else "Disabled"
                    _result = RESULT_OK
                }
            }).show()
        }

        binding.appDetailsHidenav.setOnClickListener {
            if (!WriteSettings().checkPermission(this)) {
                WriteSettings().requestPermission(this)
                Toast.makeText(applicationContext, getString(R.string.scene_need_write_sys_settings), Toast.LENGTH_SHORT).show()
                (it as Switch).isChecked = !(it as Switch).isChecked
                return@setOnClickListener
            }
            val isSelected = (it as Switch).isChecked
            if (isSelected && binding.appDetailsHidestatus.isChecked) {
                immersivePolicyControl.hideAll(app)
            } else if (isSelected) {
                immersivePolicyControl.hideNavBar(app)
            } else {
                immersivePolicyControl.showNavBar(app)
            }
        }
        binding.appDetailsHidestatus.setOnClickListener {
            if (!WriteSettings().checkPermission(this)) {
                WriteSettings().requestPermission(this)
                Toast.makeText(applicationContext, getString(R.string.scene_need_write_sys_settings), Toast.LENGTH_SHORT).show()
                (it as Switch).isChecked = !it.isChecked
                return@setOnClickListener
            }
            val isSelected = (it as Switch).isChecked
            if (isSelected && binding.appDetailsHidenav.isChecked) {
                immersivePolicyControl.hideAll(app)
            } else if (isSelected) {
                immersivePolicyControl.hideStatusBar(app)
            } else {
                immersivePolicyControl.showStatusBar(app)
            }
        }

        binding.appDetailsIcon.setOnClickListener {
            try {
                saveConfig()
                startActivity(getPackageManager().getLaunchIntentForPackage(app))
            } catch (ex: Exception) {
                Toast.makeText(applicationContext, getString(R.string.start_app_fail), Toast.LENGTH_SHORT).show()
            }
        }

        sceneConfigInfo = SceneConfigStore(this).getAppConfig(app)

        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.LOLLIPOP) {
            binding.appDetailsHidenotice.isEnabled = false
        } else {
            binding.appDetailsHidenotice.setOnClickListener {
                if (!NotificationListener().getPermission(this)) {
                    NotificationListener().setPermission(this)
                    Toast.makeText(applicationContext, getString(R.string.scene_need_notic_listing), Toast.LENGTH_SHORT).show()
                    (it as Switch).isChecked = !it.isChecked
                    return@setOnClickListener
                }
                sceneConfigInfo.disNotice = (it as Switch).isChecked
            }
        }
        binding.sceneOrientation.setOnClickListener {
            DialogAppOrientation(this, sceneConfigInfo.screenOrientation, object : DialogAppOrientation.IResultCallback {
                override fun onChange(value: Int, name: String?) {
                    sceneConfigInfo.screenOrientation = value
                    (it as TextView).text = "" + name
                }
            }).show()
        }
        binding.appDetailsAloowlight.setOnClickListener {
            if (!WriteSettings().checkPermission(this)) {
                WriteSettings().requestPermission(this)
                Toast.makeText(applicationContext, getString(R.string.scene_need_write_sys_settings), Toast.LENGTH_SHORT).show()
                (it as Switch).isChecked = false
                return@setOnClickListener
            }
            sceneConfigInfo.aloneLight = (it as Switch).isChecked
        }
        binding.appDetailsGps.setOnClickListener {
            sceneConfigInfo.gpsOn = (it as Switch).isChecked
        }

        binding.appDetailsFreeze.setOnClickListener {
            sceneConfigInfo.freeze = (it as Switch).isChecked
            if (!sceneConfigInfo.freeze) {
                SceneMode.unfreezeApp(sceneConfigInfo.packageName)
            }
        }

        binding.appMonitor.setOnClickListener {
            sceneConfigInfo.showMonitor = (it as Switch).isChecked
        }
    }

    // 通知辅助服务配置变化
    private fun notifyService(app: String, mode: String? = null) {
        if (AccessibleServiceHelper().serviceRunning(this)) {
            EventBus.publish(EventType.SCENE_APP_CONFIG, HashMap<String, Any>().apply {
                put("app", app)
                if (mode != null) {
                    put("mode", mode)
                }
            })
        }
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.save, menu)
        return true
    }

    //右上角菜单
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            R.id.action_save -> {
                saveConfigAndFinish()
            }
        }
        return super.onOptionsItemSelected(item)
    }

    @SuppressLint("SetTextI18n")
    override fun onResume() {
        super.onResume()
        val powercfg = getSharedPreferences(SpfConfig.POWER_CONFIG_SPF, Context.MODE_PRIVATE)

        var packageInfo: PackageInfo? = null
        try {
            packageInfo = packageManager.getPackageInfo(app, 0)
        } catch (ex: Exception) {
            Toast.makeText(applicationContext, "Selected app has been uninstalled!", Toast.LENGTH_SHORT).show()
        }
        if (packageInfo == null) {
            finish()
            return
        }
        val applicationInfo = packageInfo.applicationInfo
        binding.appDetailsName.text = applicationInfo.loadLabel(packageManager)
        binding.appDetailsPackagename.text = packageInfo.packageName
        binding.appDetailsIcon.setImageDrawable(applicationInfo.loadIcon(packageManager))

        val firstMode = spfGlobal.getString(SpfConfig.GLOBAL_SPF_POWERCFG_FIRST_MODE, "")
        binding.appDetailsDynamic.text = ModeSwitcher.getModName(powercfg.getString(app, firstMode)!!)

        binding.appDetailsCgroupMem.text = DialogAppCGroupMem.Transform(this).getName(sceneConfigInfo.fgCGroupMem)
        binding.appDetailsCgroupMem2.text = DialogAppCGroupMem.Transform(this).getName(sceneConfigInfo.bgCGroupMem)
        binding.appDetailsBoostMem.text = if (sceneConfigInfo.dynamicBoostMem) "Enabled" else "Disabled"

        if (immersivePolicyControl.isFullScreen(app)) {
            binding.appDetailsHidenav.isChecked = true
            binding.appDetailsHidestatus.isChecked = true
        } else {
            binding.appDetailsHidenav.isChecked = immersivePolicyControl.isHideNavbarOnly(app)
            binding.appDetailsHidestatus.isChecked = immersivePolicyControl.isHideStatusOnly(app)
        }

        binding.appDetailsHidenotice.isChecked = sceneConfigInfo.disNotice
        binding.appDetailsAloowlight.isChecked = sceneConfigInfo.aloneLight
        binding.appDetailsGps.isChecked = sceneConfigInfo.gpsOn
        binding.appDetailsFreeze.isChecked = sceneConfigInfo.freeze
        binding.appMonitor.isChecked = sceneConfigInfo.showMonitor

        binding.sceneModeAllow.isChecked = !sceneBlackList.contains(app)
        binding.sceneModeConfig.visibility = if (binding.sceneModeConfig.visibility == View.VISIBLE && binding.sceneModeAllow.isChecked) View.VISIBLE else View.GONE

        val screenOrientation = sceneConfigInfo.screenOrientation
        binding.sceneOrientation.text = DialogAppOrientation.Transform(this).getName(screenOrientation)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            saveConfigAndFinish()
        }
        return false
    }

    private fun saveConfigAndFinish() {
        saveConfig()
        this.finish()
    }

    private fun saveConfig() {
        val originConfig = SceneConfigStore(this).getAppConfig(sceneConfigInfo.packageName)

        if (
                sceneConfigInfo.screenOrientation != originConfig.screenOrientation ||
                sceneConfigInfo.aloneLight != originConfig.aloneLight ||
                sceneConfigInfo.disNotice != originConfig.disNotice ||
                sceneConfigInfo.disButton != originConfig.disButton ||
                sceneConfigInfo.gpsOn != originConfig.gpsOn ||
                sceneConfigInfo.freeze != originConfig.freeze ||
                sceneConfigInfo.fgCGroupMem != originConfig.fgCGroupMem ||
                sceneConfigInfo.bgCGroupMem != originConfig.bgCGroupMem ||
                sceneConfigInfo.dynamicBoostMem != originConfig.dynamicBoostMem ||
                sceneConfigInfo.showMonitor != originConfig.showMonitor
        ) {
            setResult(RESULT_OK, this.intent)
        } else {
            setResult(_result, this.intent)
        }
        if (!SceneConfigStore(this).setAppConfig(sceneConfigInfo)) {
            Toast.makeText(applicationContext, getString(R.string.config_save_fail), Toast.LENGTH_LONG).show()
        } else {
            if (sceneConfigInfo.fgCGroupMem != originConfig.fgCGroupMem ||
                    sceneConfigInfo.bgCGroupMem != originConfig.bgCGroupMem ||
                    sceneConfigInfo.dynamicBoostMem != originConfig.dynamicBoostMem) {
                notifyService(app)
            }

            if (sceneConfigInfo.freeze != originConfig.freeze) {
                if (sceneConfigInfo.freeze) {
                    SceneMode.getCurrentInstance()?.setFreezeAppLeaveTime(sceneConfigInfo.packageName)
                }
            }
        }
    }

    override fun finish() {
        super.finish()
    }

    override fun onPause() {
        super.onPause()
    }
}
