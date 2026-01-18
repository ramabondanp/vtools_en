package com.omarea.ui

import android.content.Context
import android.util.AttributeSet
import android.view.LayoutInflater
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import com.omarea.data.EventType
import com.omarea.model.TaskAction
import com.omarea.model.TriggerInfo
import com.omarea.vtools.R
import com.omarea.vtools.databinding.ListSceneTriggerItemBinding

class SceneTriggerItem : LinearLayout {
    private var binding: ListSceneTriggerItemBinding? = null

    constructor(context: Context) : super(context) {
        setLayout(context)
    }

    constructor(context: Context, triggerInfo: TriggerInfo) : super(context) {
        setLayout(context, triggerInfo)
    }

    constructor(context: Context?, attrs: AttributeSet?) : super(context, attrs) {}
    constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int) : super(context, attrs, defStyleAttr) {}
    constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int, defStyleRes: Int) : super(context, attrs, defStyleAttr, defStyleRes) {}

    private fun setLayout(context: Context) {
        binding = ListSceneTriggerItemBinding.inflate(LayoutInflater.from(context), this, true)
    }

    private fun setLayout(context: Context, triggerInfo: TriggerInfo) {
        setLayout(context)

        val binding = binding ?: return
        binding.systemSceneTaskTime.text = getEvents(triggerInfo)
        binding.systemSceneTaskContent.text = getTaskContentText(triggerInfo)
    }

    private fun getEvents(triggerInfo: TriggerInfo): String {
        val buffer = StringBuffer()
        if (triggerInfo.enabled) {
            buffer.append("● ")
        } else {
            buffer.append("○ ")
        }
        if (triggerInfo.events != null && triggerInfo.events.size > 0) {
            triggerInfo.events.forEach {
                when (it) {
                    EventType.BOOT_COMPLETED -> {
                        buffer.append("Boot completed")
                    }
                    EventType.APP_SWITCH -> {
                        buffer.append("App switch")
                    }
                    EventType.SCREEN_OFF -> {
                        buffer.append("Screen off")
                    }
                    EventType.SCREEN_ON -> {
                        buffer.append("Screen on")
                    }
                    EventType.BATTERY_CHANGED -> {
                        buffer.append("Battery changed")
                    }
                    EventType.BATTERY_LOW -> {
                        buffer.append("Low battery")
                    }
                    EventType.POWER_DISCONNECTED -> {
                        buffer.append("Charger disconnected")
                    }
                    EventType.POWER_CONNECTED -> {
                        buffer.append("Charger connected")
                    }
                    else -> {
                    }
                }
                buffer.append(", ")
            }
        } else {
            buffer.append("---")
        }
        if (triggerInfo.timeLimited) {
            buffer.append(String.format(context.getString(R.string.format_hh_mm), triggerInfo.timeStart / 60, triggerInfo.timeStart % 60))
            buffer.append(" ~ ")
            buffer.append(String.format(context.getString(R.string.format_hh_mm), triggerInfo.timeEnd / 60, triggerInfo.timeEnd % 60))
        }
        return buffer.toString()
    }

    private fun getTaskContentText(triggerInfo: TriggerInfo): String {
        val buffer = StringBuffer()
        if (triggerInfo.taskActions != null && triggerInfo.taskActions.size > 0) {
            triggerInfo.taskActions.forEach {
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

        if (triggerInfo.customTaskActions != null && triggerInfo.customTaskActions.size > 0) {
            triggerInfo.customTaskActions.forEach {
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
