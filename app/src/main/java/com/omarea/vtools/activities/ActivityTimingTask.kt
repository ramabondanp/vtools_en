package com.omarea.vtools.activities

import android.app.TimePickerDialog
import android.os.Build
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.CompoundButton
import android.widget.Toast
import com.omarea.common.model.SelectItem
import com.omarea.common.shared.FileWrite
import com.omarea.common.ui.DialogItemChooser2
import com.omarea.krscript.executor.ExtractAssets
import com.omarea.library.calculator.GetUpTime
import com.omarea.model.CustomTaskAction
import com.omarea.model.TaskAction
import com.omarea.model.TimingTaskInfo
import com.omarea.scene_mode.TimingTaskManager
import com.omarea.store.TimingTaskStorage
import com.omarea.vtools.R
import com.omarea.vtools.databinding.ActivityTimingTaskBinding
import java.io.File
import java.io.FilenameFilter
import java.net.URLDecoder
import java.util.*
import kotlin.collections.ArrayList

class ActivityTimingTask : ActivityBase() {
    private lateinit var timingTaskInfo: TimingTaskInfo
    private lateinit var binding: ActivityTimingTaskBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityTimingTaskBinding.inflate(layoutInflater)
        setContentView(binding.root)
        setBackArrow()

        // 读取或初始化任务模型
        var taskId: String = "SCENE_TASK_" + UUID.randomUUID().toString()
        intent?.run {
            if (hasExtra("taskId")) {
                intent.getStringExtra("taskId")?.run {
                    taskId = this
                }
            }
        }
        val task = TimingTaskStorage(this@ActivityTimingTask).load(taskId)
        timingTaskInfo = if (task == null) TimingTaskInfo(taskId) else task

        // 时间选择
        binding.taksTriggerTime.setOnClickListener {
            TimePickerDialog(this, TimePickerDialog.OnTimeSetListener { view, hourOfDay, minute ->
                binding.taksTriggerTime.setText(String.format(getString(R.string.format_hh_mm), hourOfDay, minute))
                timingTaskInfo.triggerTimeMinutes = hourOfDay * 60 + minute
            }, timingTaskInfo.triggerTimeMinutes / 60, timingTaskInfo.triggerTimeMinutes % 60, true).show()
        }

        // 设定单选关系
        oneOf(binding.taskStandbyOn, binding.taskStandbyOff)
        oneOf(binding.taskZenModeOn, binding.taskZenModeOff)
        oneOf(binding.taskAfterScreenOff, binding.taskBeforeExecuteConfirm)
        oneOf(binding.taskBatteryCapacityRequire, binding.taskChargeOnly)

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
                    val name = URLDecoder.decode(it.name)
                    title = name
                    value = it.absolutePath
                    selected = timingTaskInfo.customTaskActions?.find { it.Name == name } != null
                }
            }?.sortedBy { it.title }
            val selectedItems = ArrayList<SelectItem>()
            timingTaskInfo.customTaskActions?.forEach { item ->
                val name = item.Name
                val r = fileNames?.find { it.title == name }
                if (r != null) {
                    selectedItems.add(r)
                }
            }

            if (fileNames != null && fileNames.size > 0) {
                DialogItemChooser2(themeMode.isDarkMode, ArrayList(fileNames), ArrayList(selectedItems), true, object : DialogItemChooser2.Callback {
                    override fun onConfirm(selected: List<SelectItem>, status: BooleanArray) {
                        timingTaskInfo.customTaskActions = ArrayList(selected.map {
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
        timingTaskInfo.run {
            binding.systemSceneTaskEnable.isChecked = enabled && (expireDate < 1 || expireDate > System.currentTimeMillis())

            // 触发时间
            val hourOfDay = triggerTimeMinutes / 60
            val minute = triggerTimeMinutes % 60
            binding.taksTriggerTime.setText(String.format(getString(R.string.format_hh_mm), hourOfDay, minute))

            // 重复周期
            if (expireDate > 0) {
                binding.taksOnce.isChecked = true
            } else {
                binding.taksRepeat.isChecked = true
            }

            // 额外条件
            binding.taskAfterScreenOff.isChecked = afterScreenOff
            binding.taskBeforeExecuteConfirm.isChecked = beforeExecuteConfirm
            binding.taskBatteryCapacityRequire.isChecked = batteryCapacityRequire > -0
            binding.taskBatteryCapacity.text = batteryCapacityRequire.toString()
            binding.taskChargeOnly.isChecked = chargeOnly

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
        timingTaskInfo.enabled = binding.systemSceneTaskEnable.isChecked
        timingTaskInfo.expireDate = if (binding.taksRepeat.isChecked) 0 else (GetUpTime(timingTaskInfo.triggerTimeMinutes).nextGetUpTime)
        timingTaskInfo.afterScreenOff = binding.taskAfterScreenOff.isChecked
        timingTaskInfo.beforeExecuteConfirm = binding.taskBeforeExecuteConfirm.isChecked
        timingTaskInfo.chargeOnly = binding.taskChargeOnly.isChecked
        timingTaskInfo.batteryCapacityRequire = if (binding.taskBatteryCapacityRequire.isChecked) (binding.taskBatteryCapacity.text).toString().toInt() else 0
        timingTaskInfo.taskActions = ArrayList<TaskAction>().apply {
            binding.taskStandbyOn.isChecked && add(TaskAction.STANDBY_MODE_ON)
            binding.taskStandbyOff.isChecked && add(TaskAction.STANDBY_MODE_OFF)
            binding.taskZenModeOn.isChecked && add(TaskAction.ZEN_MODE_ON)
            binding.taskZenModeOff.isChecked && add(TaskAction.ZEN_MODE_OFF)
        }
        // timingTaskInfo.taskId = taskId

        TimingTaskManager(this).setTaskAndSave(timingTaskInfo)

        finish()
    }

    override fun onPause() {
        super.onPause()
    }
}
