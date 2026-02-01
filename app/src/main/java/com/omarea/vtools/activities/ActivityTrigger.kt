package com.omarea.vtools.activities

import android.app.TimePickerDialog
import android.os.Build
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.Checkable
import android.widget.CompoundButton
import android.widget.Toast
import com.omarea.common.model.SelectItem
import com.omarea.common.shared.FileWrite
import com.omarea.common.ui.DialogItemChooser2
import com.omarea.data.EventType
import com.omarea.krscript.executor.ExtractAssets
import com.omarea.model.CustomTaskAction
import com.omarea.model.TaskAction
import com.omarea.model.TriggerInfo
import com.omarea.scene_mode.TriggerManager
import com.omarea.store.TriggerStorage
import com.omarea.vtools.R
import com.omarea.vtools.databinding.ActivityTriggerBinding
import java.io.File
import java.io.FilenameFilter
import java.net.URLDecoder
import java.nio.charset.StandardCharsets
import java.util.*
import kotlin.collections.ArrayList

class ActivityTrigger : ActivityBase() {
    private lateinit var triggerInfo: TriggerInfo
    private lateinit var binding: ActivityTriggerBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityTriggerBinding.inflate(layoutInflater)
        setContentView(binding.root)
        setBackArrow()

        // 读取或初始化任务模型
        var id: String = "SCENE_TRIGGER_" + UUID.randomUUID().toString()
        intent?.run {
            if (hasExtra("id")) {
                intent.getStringExtra("id")?.run {
                    id = this
                }
            }
        }
        val task = TriggerStorage(this@ActivityTrigger).load(id)
        triggerInfo = if (task == null) TriggerInfo(id) else task

        // 时间选择
        binding.triggerTimeStart.setOnClickListener {
            TimePickerDialog(this, TimePickerDialog.OnTimeSetListener { view, hourOfDay, minute ->
                binding.triggerTimeStart.setText(String.format(getString(R.string.format_hh_mm), hourOfDay, minute))
                triggerInfo.timeStart = hourOfDay * 60 + minute
            }, triggerInfo.timeStart / 60, triggerInfo.timeStart % 60, true).show()
        }
        binding.triggerTimeEnd.setOnClickListener {
            TimePickerDialog(this, TimePickerDialog.OnTimeSetListener { view, hourOfDay, minute ->
                binding.triggerTimeEnd.setText(String.format(getString(R.string.format_hh_mm), hourOfDay, minute))
                triggerInfo.timeEnd = hourOfDay * 60 + minute
            }, triggerInfo.timeEnd / 60, triggerInfo.timeEnd % 60, true).show()
        }
        binding.triggerTimeLimit.setOnClickListener {
            triggerInfo.timeLimited = (it as Checkable).isChecked
        }

        // 设定单选关系
        oneOf(binding.triggerScreenOn, binding.triggerScreenOff)
        oneOf(binding.triggerPowerConnected, binding.triggerPowerDisconnected)

        oneOf(binding.taskStandbyOn, binding.taskStandbyOff)
        oneOf(binding.taskZenModeOn, binding.taskZenModeOff)

        // 更新选中状态
        updateUI()
        // 勿扰模式
        binding.taskZenMode.visibility = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) View.VISIBLE else View.GONE
        // 待机模式
        binding.taskStandbyMode.visibility = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) View.VISIBLE else View.GONE

        // 自定义动作点击
        binding.taskCustomEdit.setOnClickListener {
            customEditClick()
        }
    }

    private fun customEditClick() {
        ExtractAssets(this).extractResources("custom-command")

        val dirPath = FileWrite.getPrivateFilePath(this, "custom-command")
        val dir = File(dirPath)
        if (dir.exists()) {
            val files = dir.listFiles(object : FilenameFilter {
                override fun accept(dir: File?, name: String?): Boolean {
                    return name?.endsWith(".sh") == true
                }
            })

            val fileNames = files?.map {
                SelectItem().apply {
                    val name = URLDecoder.decode(it.name, StandardCharsets.UTF_8.name())
                    title = name
                    value = it.absolutePath
                    selected = triggerInfo.customTaskActions?.find { it.Name == name } != null
                }
            }?.sortedBy { it.title }
            val selectedItems = ArrayList<SelectItem>()
            triggerInfo.customTaskActions?.forEach { item ->
                val name = item.Name
                val r = fileNames?.find { it.title == name }
                if (r != null) {
                    selectedItems.add(r)
                }
            }

            if (fileNames != null && fileNames.size > 0) {
                DialogItemChooser2(themeMode.isDarkMode, ArrayList(fileNames), ArrayList(selectedItems), true, object : DialogItemChooser2.Callback {
                    override fun onConfirm(selected: List<SelectItem>, status: BooleanArray) {
                        triggerInfo.customTaskActions = ArrayList(selected.map {
                            CustomTaskAction().apply {
                                Name = it.title
                                Command = "sh '" + it.value + "'"
                            }
                        })
                        updateUI()
                    }
                }).setTitle("Select command to execute").show(supportFragmentManager, "custom-action-picker")
            } else {
                Toast.makeText(this, "You haven't created any custom commands yet.", Toast.LENGTH_SHORT).show()
            }
        } else {
            Toast.makeText(this, "You haven't created any custom commands yet.", Toast.LENGTH_SHORT).show()
        }
    }

    private fun updateUI() {
        triggerInfo.run {
            binding.systemSceneTaskEnable.isChecked = enabled
            binding.triggerTimeLimit.isChecked = triggerInfo.timeLimited
            // 触发时间
            binding.triggerTimeStart.setText(String.format(getString(R.string.format_hh_mm), triggerInfo.timeStart / 60, triggerInfo.timeStart % 60))
            binding.triggerTimeEnd.setText(String.format(getString(R.string.format_hh_mm), triggerInfo.timeEnd / 60, triggerInfo.timeEnd % 60))

            // 触发事件
            events?.run {
                binding.triggerBootCompleted.isChecked = contains(EventType.BOOT_COMPLETED)
                binding.triggerScreenOn.isChecked = contains(EventType.SCREEN_ON)
                binding.triggerScreenOff.isChecked = contains(EventType.SCREEN_OFF)
                binding.triggerBatteryLow.isChecked = contains(EventType.BATTERY_LOW)
                binding.triggerPowerConnected.isChecked = contains(EventType.POWER_CONNECTED)
                binding.triggerPowerDisconnected.isChecked = contains(EventType.POWER_DISCONNECTED)
            }

            // 功能动作
            taskActions?.run {
                binding.taskStandbyOn.isChecked = contains(TaskAction.STANDBY_MODE_ON)
                binding.taskStandbyOff.isChecked = contains(TaskAction.STANDBY_MODE_OFF)
                binding.taskZenModeOn.isChecked = contains(TaskAction.ZEN_MODE_ON)
                binding.taskZenModeOff.isChecked = contains(TaskAction.ZEN_MODE_OFF)
            }

            customTaskActions?.run {
                val str = this.map { it.Name }.toTypedArray().joinToString("\n\n").trim()
                binding.taskCustomActions.text = str
            }
        }
    }

    private fun oneOf(radioButton1: CompoundButton, radioButton2: CompoundButton) {
        radioButton1.setOnClickListener {
            if ((it as CompoundButton).isChecked && it.tag == true) {
                it.tag = false
                it.isChecked = false
            } else {
                it.tag = it.isChecked
                radioButton2.tag = false
                radioButton2.isChecked = false
            }
        }
        radioButton2.setOnClickListener {
            if ((it as CompoundButton).isChecked && it.tag == true) {
                it.tag = false
                it.isChecked = false
            } else {
                it.tag = it.isChecked
                radioButton1.tag = false
                radioButton1.isChecked = false
            }
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

    // 保存并关闭界面
    private fun saveConfigAndFinish() {
        triggerInfo.enabled = binding.systemSceneTaskEnable.isChecked

        // triggerInfo.expireDate = if (taks_repeat.isChecked) 0 else (GetUpTime(timingTaskInfo.triggerTimeMinutes).nextGetUpTime)
        // triggerInfo.afterScreenOff = task_after_screen_off.isChecked
        // triggerInfo.beforeExecuteConfirm = task_before_execute_confirm.isChecked
        // triggerInfo.chargeOnly = task_charge_only.isChecked
        // triggerInfo.batteryCapacityRequire = if(task_battery_capacity_require.isChecked) (task_battery_capacity.text).toString().toInt() else 0

        triggerInfo.taskActions = ArrayList<TaskAction>().apply {
            binding.taskStandbyOn.isChecked && add(TaskAction.STANDBY_MODE_ON)
            binding.taskStandbyOff.isChecked && add(TaskAction.STANDBY_MODE_OFF)
            binding.taskZenModeOn.isChecked && add(TaskAction.ZEN_MODE_ON)
            binding.taskZenModeOff.isChecked && add(TaskAction.ZEN_MODE_OFF)
        }

        triggerInfo.events = ArrayList<EventType>().apply {
            binding.triggerBootCompleted.isChecked && add(EventType.BOOT_COMPLETED)
            binding.triggerScreenOn.isChecked && add(EventType.SCREEN_ON)
            binding.triggerScreenOff.isChecked && add(EventType.SCREEN_OFF)
            binding.triggerBatteryLow.isChecked && add(EventType.BATTERY_LOW)
            binding.triggerPowerConnected.isChecked && add(EventType.POWER_CONNECTED)
            binding.triggerPowerDisconnected.isChecked && add(EventType.POWER_DISCONNECTED)
        }

        // timingTaskInfo.taskId = taskId

        TriggerManager(this).setTriggerAndSave(triggerInfo)

        finish()
    }

    override fun onPause() {
        super.onPause()
    }
}
