package com.omarea.vtools.activities

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.LinearLayout
import com.omarea.common.ui.AdapterAppChooser
import com.omarea.common.ui.DialogAppChooser
import com.omarea.common.ui.DialogHelper
import com.omarea.common.ui.ProgressBarDialog
import com.omarea.library.calculator.GetUpTime
import com.omarea.model.AppInfo
import com.omarea.model.TimingTaskInfo
import com.omarea.model.TriggerInfo
import com.omarea.scene_mode.ModeSwitcher
import com.omarea.scene_mode.SceneStandbyMode
import com.omarea.scene_mode.TimingTaskManager
import com.omarea.scene_mode.TriggerManager
import com.omarea.store.SpfConfig
import com.omarea.ui.SceneTaskItem
import com.omarea.ui.SceneTriggerItem
import com.omarea.ui.TabIconHelper
import com.omarea.utils.AppListHelper
import com.omarea.vtools.R
import com.omarea.vtools.databinding.ActivitySystemSceneBinding

class ActivitySystemScene : ActivityBase() {
    private lateinit var processBarDialog: ProgressBarDialog
    private lateinit var globalSPF: SharedPreferences
    private lateinit var chargeConfig: SharedPreferences
    internal val myHandler: Handler = Handler(Looper.getMainLooper())
    private lateinit var binding: ActivitySystemSceneBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySystemSceneBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setBackArrow()
        onViewCreated()
    }

    private lateinit var modeSwitcher: ModeSwitcher

    override fun onResume() {
        super.onResume()
        title = getString(R.string.menu_system_scene)

        updateCustomList()
    }

    private fun updateCustomList() {
        nextTask = null
        binding.systemSceneTaskList.removeAllViews()
        TimingTaskManager(context).listTask().forEach {
            addCustomTaskItemView(it)
            checkNextTask(it)
        }
        updateNextTaskInfo()

        binding.systemSceneTriggerList.removeAllViews()
        TriggerManager(context).list().forEach {
            it?.run {
                addCustomTriggerView(it)
            }
        }
    }

    private var nextTask: TimingTaskInfo? = null // 下一个要执行的任务
    private fun checkNextTask(it: TimingTaskInfo) {
        if (it.enabled && (it.expireDate < 1 || it.expireDate > System.currentTimeMillis())) {
            if (nextTask == null || GetUpTime(it.triggerTimeMinutes).minutes < GetUpTime(nextTask!!.triggerTimeMinutes).minutes) {
                nextTask = it
            }
        }
    }

    private fun updateNextTaskInfo() {
        binding.systemSceneNextContent.removeAllViews()
        if (nextTask != null) {
            binding.systemSceneNextContent.addView(buildCustomTaskItemView(nextTask!!))
        }
    }

    private fun onViewCreated() {
        modeSwitcher = ModeSwitcher()
        processBarDialog = ProgressBarDialog(this)
        globalSPF = getSharedPreferences(SpfConfig.GLOBAL_SPF, Context.MODE_PRIVATE)
        chargeConfig = getSharedPreferences(SpfConfig.CHARGE_SPF, Context.MODE_PRIVATE)

        val tabIconHelper = TabIconHelper(binding.configlistTabhost, this)
        binding.configlistTabhost.setup()

        tabIconHelper.newTabSpec("System scenes", getDrawable(R.drawable.tab_security)!!, R.id.blacklist_tab3)
        tabIconHelper.newTabSpec("Settings", getDrawable(R.drawable.tab_settings)!!, R.id.configlist_tab5)
        binding.configlistTabhost.currentTab = 0
        binding.configlistTabhost.setOnTabChangedListener { tabId ->
            tabIconHelper.updateHighlight()
        }

        if (chargeConfig.getBoolean(SpfConfig.CHARGE_SPF_BP, false)) {
            binding.systemSceneBp.visibility = View.VISIBLE
            val limit = chargeConfig.getInt(SpfConfig.CHARGE_SPF_BP_LEVEL, SpfConfig.CHARGE_SPF_BP_LEVEL_DEFAULT)
            binding.systemSceneBpLt.text = (limit - 20).toString() + "%"
            binding.systemSceneBpGt.text = limit.toString() + "%"
        }

        binding.systemSceneAddTask.setOnClickListener {
            val intent = Intent(this, ActivityTimingTask::class.java)
            startActivity(intent)
        }

        binding.systemSceneAddTrigger.setOnClickListener {
            val intent = Intent(this, ActivityTrigger::class.java)
            startActivity(intent)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            binding.systemSceneStandbyApps.visibility = View.VISIBLE
            binding.systemSceneStandbyApps.setOnClickListener {
                standbyAppConfig()
            }
        } else {
            binding.systemSceneStandbyApps.visibility = View.GONE
        }

        binding.systemSceneCommand.setOnClickListener {
            val intent = Intent(this, ActivityCustomCommand::class.java)
            startActivity(intent)
        }
    }

    // 设置待机模式的应用
    private fun standbyAppConfig() {
        processBarDialog.showDialog()
        Thread {
            val configFile = context.getSharedPreferences(SceneStandbyMode.configSpfName, Context.MODE_PRIVATE)
            val whiteList = context.resources.getStringArray(R.array.scene_standby_white_list)
            val options = ArrayList(AppListHelper(context).getAll().filter {
                !whiteList.contains(it.packageName)
            }.sortedBy {
                it.appType
            }.map {
                it.apply {
                    selected = configFile.getBoolean(packageName.toString(), it.appType == AppInfo.AppType.USER && !it.updated)
                }
            })

            myHandler.post {
                processBarDialog.hideDialog()

                DialogAppChooser(themeMode.isDarkMode, ArrayList(options), true, object : DialogAppChooser.Callback {
                    override fun onConfirm(apps: List<AdapterAppChooser.AppInfo>) {
                        val items = apps.map { it.packageName }
                        options.forEach {
                            it.selected = items.contains(it.packageName)
                        }
                        saveStandbyAppConfig(options)
                    }
                }).show(supportFragmentManager, "standby_apps")
            }
        }.start()
    }

    // 保存休眠应用配置
    private fun saveStandbyAppConfig(apps: List<AppInfo>) {
        val configFile = getSharedPreferences(SceneStandbyMode.configSpfName, Context.MODE_PRIVATE).edit()
        configFile.clear()

        apps.forEach {
            if (it.selected && it.appType == AppInfo.AppType.SYSTEM) {
                configFile.putBoolean(it.packageName.toString(), true)
            } else if ((!it.selected) && it.appType == AppInfo.AppType.USER) {
                configFile.putBoolean(it.packageName.toString(), false)
            }
        }

        configFile.apply()
    }

    private fun buildCustomTaskItemView(timingTaskInfo: TimingTaskInfo): SceneTaskItem {
        val sceneTaskItem = SceneTaskItem(context, timingTaskInfo)
        sceneTaskItem.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        sceneTaskItem.isClickable = true
        return sceneTaskItem
    }

    private fun addCustomTaskItemView(timingTaskInfo: TimingTaskInfo) {
        val sceneTaskItem = buildCustomTaskItemView(timingTaskInfo)

        binding.systemSceneTaskList.addView(sceneTaskItem)
        sceneTaskItem.setOnClickListener {
            val intent = Intent(this, ActivityTimingTask::class.java)
            intent.putExtra("taskId", timingTaskInfo.taskId)
            startActivity(intent)
        }
        sceneTaskItem.setOnLongClickListener {
            DialogHelper.confirm(this, "Delete this task?", "", {
                TimingTaskManager(context).removeTask(timingTaskInfo)
                updateCustomList()
            })
            true
        }
    }

    private fun addCustomTriggerView(triggerInfo: TriggerInfo) {
        val itemView = SceneTriggerItem(context, triggerInfo)
        itemView.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        itemView.isClickable = true

        binding.systemSceneTriggerList.addView(itemView)

        itemView.setOnClickListener {
            val intent = Intent(this, ActivityTrigger::class.java)
            intent.putExtra("id", triggerInfo.id)
            startActivity(intent)
        }
        itemView.setOnLongClickListener {
            DialogHelper.confirm(this, "Delete this trigger?", "", {
                TriggerManager(context).removeTrigger(triggerInfo)
                updateCustomList()
            })
            true
        }
    }

    override fun onDestroy() {
        processBarDialog.hideDialog()
        super.onDestroy()
    }
}
