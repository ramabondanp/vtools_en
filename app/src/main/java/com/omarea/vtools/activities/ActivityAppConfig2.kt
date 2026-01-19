package com.omarea.vtools.activities

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ActivityInfo
import android.os.Bundle
import android.util.Log
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.AdapterView
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import com.omarea.Scene
import com.omarea.common.ui.DialogHelper
import com.omarea.common.ui.OverScrollListView
import com.omarea.common.ui.ProgressBarDialog
import com.omarea.data.EventBus
import com.omarea.data.EventType
import com.omarea.model.AppInfo
import com.omarea.scene_mode.ModeSwitcher
import com.omarea.store.SceneConfigStore
import com.omarea.store.SpfConfig
import com.omarea.ui.AdapterSceneMode
import com.omarea.utils.AppListHelper
import com.omarea.vtools.R
import com.omarea.vtools.databinding.ActivityAppConfig2Binding
import com.omarea.vtools.dialogs.DialogAppOrientation
import com.omarea.vtools.dialogs.DialogAppPowerConfig
import java.util.*
import kotlin.collections.ArrayList


class ActivityAppConfig2 : ActivityBase() {
    private lateinit var processBarDialog: ProgressBarDialog
    private lateinit var spfPowercfg: SharedPreferences
    private lateinit var globalSPF: SharedPreferences
    private lateinit var applistHelper: AppListHelper
    private var installedList: ArrayList<AppInfo>? = null
    private var displayList: ArrayList<AppInfo>? = null
    private lateinit var sceneConfigStore: SceneConfigStore
    private lateinit var binding: ActivityAppConfig2Binding
    private var lastClickRow: View? = null

    private val appConfigLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        val data = result.data
        if (result.resultCode == AppCompatActivity.RESULT_OK && data != null && displayList != null) {
            try {
                val adapter = (binding.sceneAppList.adapter as AdapterSceneMode)
                var index = -1
                val packageName = data.extras!!.getString("app")
                for (i in 0 until displayList!!.size) {
                    if (displayList!![i].packageName == packageName) {
                        index = i
                    }
                }
                if (index < 0) {
                    return@registerForActivityResult
                }
                val item = adapter.getItem(index)
                setAppRowDesc(item)
                (binding.sceneAppList.adapter as AdapterSceneMode?)?.run {
                    updateRow(index, lastClickRow!!)
                }
            } catch (ex: Exception) {
                Log.e("update-list", "" + ex.message)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAppConfig2Binding.inflate(layoutInflater)
        setContentView(binding.root)

        setBackArrow()
        globalSPF = getSharedPreferences(SpfConfig.GLOBAL_SPF, Context.MODE_PRIVATE)

        this.onViewCreated()
    }

    private lateinit var modeSwitcher: ModeSwitcher

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.scene_apps, menu)
        return true
    }

    //右上角菜单
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            R.id.action_reset -> {
                DialogHelper.confirm(this, "Reset settings?", "This will clear your per-app settings for performance tuning, per-app brightness, screen rotation, memory (cgroup), auto boost, and the performance monitor.", {
                    sceneConfigStore.resetAll()
                    spfPowercfg.all.clear()
                    initDefaultConfig()
                    recreate()
                })
            }
        }
        return true
    }

    private fun onViewCreated() {
        modeSwitcher = ModeSwitcher()
        processBarDialog = ProgressBarDialog(this)
        applistHelper = AppListHelper(this, false)
        spfPowercfg = getSharedPreferences(SpfConfig.POWER_CONFIG_SPF, Context.MODE_PRIVATE)
        globalSPF = getSharedPreferences(SpfConfig.GLOBAL_SPF, Context.MODE_PRIVATE)
        sceneConfigStore = SceneConfigStore(this.context)

        if (spfPowercfg.all.isEmpty()) {
            initDefaultConfig()
        }


        binding.sceneAppList.setOnItemClickListener { parent, view2, position, _ ->
            try {
                val item = (parent.adapter.getItem(position) as AppInfo)
                val intent = Intent(this.context, ActivityAppDetails::class.java)
                intent.putExtra("app", item.packageName)
                appConfigLauncher.launch(intent)
                lastClickRow = view2
            } catch (ex: Exception) {
            }
        }

        // 动态响应检测
        val dynamicControl = globalSPF.getBoolean(SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL, SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL_DEFAULT)

        if (dynamicControl) {
            binding.sceneAppList.setOnItemLongClickListener { parent, view, position, _ ->
                val item = (parent.adapter.getItem(position) as AppInfo)
                val app = item.packageName.toString()
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

                                setAppRowDesc(item)
                                (parent.adapter as AdapterSceneMode).updateRow(position, view)
                                notifyService(app, "" + mode)
                            }
                        }).show()
                true
            }
        } else {
            binding.sceneAppList.setOnItemLongClickListener { _, _, _, _ ->
                DialogHelper.helpInfo(this, "", "Go back to the feature list, open [Performance config], and enable [Dynamic Response].")
                true
            }
        }

        binding.configSearchBox.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_SEARCH || actionId == EditorInfo.IME_ACTION_DONE) {
                loadList()
                return@setOnEditorActionListener true
            }
            false
        }

        binding.configlistModes.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onNothingSelected(parent: AdapterView<*>?) {
            }

            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, unusedId: Long) {
                loadList()
            }
        }
        binding.configlistType.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onNothingSelected(parent: AdapterView<*>?) {
            }

            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, unusedId: Long) {
                loadList()
            }
        }

        loadList()
    }

    // 通知辅助服务配置变化
    private fun notifyService(app: String, mode: String) {
        EventBus.publish(EventType.SCENE_APP_CONFIG, HashMap<String, Any>().apply {
            put("app", app)
            put("mode", mode)
        })
    }

    private fun initDefaultConfig() {
        for (item in resources.getStringArray(R.array.powercfg_igoned)) {
            spfPowercfg.edit().putString(item, ModeSwitcher.IGONED).apply()
        }
        for (item in resources.getStringArray(R.array.powercfg_fast)) {
            spfPowercfg.edit().putString(item, ModeSwitcher.FAST).apply()
        }
        for (item in resources.getStringArray(R.array.powercfg_game)) {
            spfPowercfg.edit().putString(item, ModeSwitcher.PERFORMANCE).apply()
        }
        for (item in context.resources.getStringArray(R.array.powercfg_powersave)) {
            spfPowercfg.edit().putString(item, ModeSwitcher.POWERSAVE).apply()
        }
    }

    private fun sortAppList(list: ArrayList<AppInfo>): ArrayList<AppInfo> {
        list.sortWith { l, r ->
            try {
                val les = l.stateTags.toString()
                val res = r.stateTags.toString()
                when {
                    les < res -> -1
                    les > res -> 1
                    else -> {
                        val lp = l.packageName.toString()
                        val rp = r.packageName.toString()
                        when {
                            lp < rp -> -1
                            lp > rp -> 1
                            else -> 0
                        }
                    }
                }
            } catch (ex: Exception) {
                0
            }
        }
        return list
    }

    private fun setListData(dl: ArrayList<AppInfo>?, lv: OverScrollListView) {
        Scene.post {
            lv.adapter = AdapterSceneMode(
                    this,
                    dl!!,
                    globalSPF.getString(SpfConfig.GLOBAL_SPF_POWERCFG_FIRST_MODE, ModeSwitcher.DEFAULT)!!
            )
            processBarDialog.hideDialog()
        }
    }

    private var onLoading = false

    @SuppressLint("ApplySharedPref")
    private fun loadList(foreceReload: Boolean = false) {
        if (onLoading) {
            return
        }
        processBarDialog.showDialog()

        Thread(Runnable {
            onLoading = true
            if (foreceReload || installedList == null || installedList!!.size == 0) {
                installedList = ArrayList()/*在数组中存放数据*/
                installedList = applistHelper.getAll()
            }
            val keyword = binding.configSearchBox.text.toString().lowercase(Locale.getDefault())
            val search = keyword.isNotEmpty()
            var filterMode = ""
            var filterAppType = ""
            when (binding.configlistType.selectedItemPosition) {
                0 -> filterAppType = "/data"
                1 -> filterAppType = "/system"
                2 -> filterAppType = "*"
            }
            when (binding.configlistModes.selectedItemPosition) {
                0 -> filterMode = "*"
                1 -> filterMode = ModeSwitcher.POWERSAVE
                2 -> filterMode = ModeSwitcher.BALANCE
                3 -> filterMode = ModeSwitcher.PERFORMANCE
                4 -> filterMode = ModeSwitcher.FAST
                5 -> filterMode = ""
                6 -> filterMode = ModeSwitcher.IGONED
            }
            displayList = ArrayList()
            for (i in installedList!!.indices) {
                val item = installedList!![i]
                setAppRowDesc(item)
                val packageName = item.packageName.toString()
                if (search && !(packageName.lowercase(Locale.getDefault()).contains(keyword) || item.appName.toString().lowercase(Locale.getDefault()).contains(keyword))) {
                    continue
                } else {
                    if (filterMode == "*" || filterMode == spfPowercfg.getString(packageName, "")) {
                        if (filterAppType == "*" || item.path.startsWith(filterAppType)) {
                            displayList!!.add(item)
                        }
                    }
                }
            }
            sortAppList(displayList!!)
            Scene.post {
                processBarDialog.hideDialog()
                setListData(displayList, binding.sceneAppList)
            }
            onLoading = false
        }).start()
    }

    private fun setAppRowDesc(item: AppInfo) {
        item.selected = false
        val packageName = item.packageName
        item.stateTags = spfPowercfg.getString(packageName, "")
        val configInfo = sceneConfigStore.getAppConfig(packageName)
        item.sceneConfigInfo = configInfo
        val desc = StringBuilder()
        if (configInfo.aloneLight) {
            desc.append("Per-app brightness ")
        }
        if (configInfo.disNotice) {
            desc.append("Block notifications  ")
        }
        if (configInfo.disButton) {
            desc.append("Block keys  ")
        }
        if (configInfo.freeze) {
            desc.append("Auto freeze  ")
        }
        if (configInfo.gpsOn) {
            desc.append("Enable GPS  ")
        }
        if (configInfo.screenOrientation != ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED) {
            DialogAppOrientation.Transform(this).getName(configInfo.screenOrientation).run {
                if (isNotEmpty()) {
                    desc.append(this)
                    desc.append("  ")
                }
            }
        }
        item.desc = desc.toString()
    }

    override fun onDestroy() {
        processBarDialog.hideDialog()
        super.onDestroy()
    }

    override fun onResume() {
        super.onResume()
        title = getString(R.string.menu_app_scene)
    }
}
