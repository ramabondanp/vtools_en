package com.omarea.ui

import android.content.Context
import android.util.AttributeSet
import android.view.LayoutInflater
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import com.omarea.model.TaskAction
import com.omarea.model.TimingTaskInfo
import com.omarea.vtools.databinding.ListSceneTaskItemBinding

class SceneTaskItem : LinearLayout {
    private var binding: ListSceneTaskItemBinding? = null

    constructor(context: Context) : super(context) {
        setLayout(context)
    }

    constructor(context: Context, taskInfo: TimingTaskInfo) : super(context) {
        setLayout(context, taskInfo)
    }

    constructor(context: Context?, attrs: AttributeSet?) : super(context, attrs) {}
    constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int) : super(context, attrs, defStyleAttr) {}
    constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int, defStyleRes: Int) : super(context, attrs, defStyleAttr, defStyleRes) {}

    private fun setLayout(context: Context) {
        binding = ListSceneTaskItemBinding.inflate(LayoutInflater.from(context), this, true)
    }

    private fun setLayout(context: Context, taskInfo: TimingTaskInfo) {
        setLayout(context)

        val binding = binding ?: return
        if (taskInfo.taskName.isNullOrEmpty()) {
            binding.systemSceneTaskName.text = "Unnamed task"
        } else {
            binding.systemSceneTaskName.text = taskInfo.taskName
        }

        val timePrefix = if (taskInfo.expireDate < 1) ("Every day, ") else ""
        binding.systemSceneTaskTime.text = (if (taskInfo.enabled) "● " else "○ ") + timePrefix + getTimeStr(taskInfo)
        binding.systemSceneTaskContent.text = getTaskContentText(taskInfo)
    }

    private fun getTimeStr(taskInfo: TimingTaskInfo): String {
        val hours = taskInfo.triggerTimeMinutes / 60
        val minutes = taskInfo.triggerTimeMinutes % 60
        val hoursStr = if (hours < 10) ("0" + hours) else hours.toString()
        val minutesStr = if (minutes < 10) ("0" + minutes) else minutes.toString()
        val stuffix = if (taskInfo.afterScreenOff) " after screen off" else ""

        return hoursStr + ":" + minutesStr + stuffix
    }

    private fun getTaskContentText(taskInfo: TimingTaskInfo): String {
        val buffer = StringBuffer()
        if (taskInfo.taskActions != null && taskInfo.taskActions.size > 0) {
            taskInfo.taskActions.forEach {
                when (it) {
                    null -> {
                    }
                    TaskAction.STANDBY_MODE_ON -> {
                        buffer.append("Sleep mode ON")
                    }
                    TaskAction.STANDBY_MODE_OFF -> {
                        buffer.append("Sleep mode OFF")
                    }
                    TaskAction.FSTRIM -> {
                        buffer.append("FSTRIM ON")
                    }
                    TaskAction.POWER_OFF -> {
                        buffer.append("Auto shutdown ON")
                    }
                    TaskAction.ZEN_MODE_OFF -> {
                        buffer.append("Do Not Disturb OFF")
                    }
                    TaskAction.ZEN_MODE_ON -> {
                        buffer.append("Do Not Disturb ON")
                    }
                }
                buffer.append("     ")
            }
        }

        if (taskInfo.customTaskActions != null && taskInfo.customTaskActions.size > 0) {
            taskInfo.customTaskActions.forEach {
                buffer.append(it.Name)
                buffer.append("     ")
            }
        }

        if (buffer.length == 0) {
            buffer.append("---")
        }

        return buffer.toString()
    }

    val text: CharSequence
        get() = (findViewById<View>(android.R.id.title) as TextView).text

    override fun setEnabled(enabled: Boolean) {

    }
}
