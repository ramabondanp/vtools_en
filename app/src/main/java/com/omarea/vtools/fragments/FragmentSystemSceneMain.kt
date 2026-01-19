package com.omarea.vtools.fragments

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.fragment.app.Fragment
import com.omarea.common.ui.DialogHelper
import com.omarea.library.calculator.GetUpTime
import com.omarea.model.TimingTaskInfo
import com.omarea.model.TriggerInfo
import com.omarea.scene_mode.TimingTaskManager
import com.omarea.scene_mode.TriggerManager
import com.omarea.store.SpfConfig
import com.omarea.ui.SceneTaskItem
import com.omarea.ui.SceneTriggerItem
import com.omarea.vtools.activities.ActivityTimingTask
import com.omarea.vtools.activities.ActivityTrigger
import com.omarea.vtools.databinding.FragmentSystemSceneMainBinding

class FragmentSystemSceneMain : Fragment() {
    private var _binding: FragmentSystemSceneMainBinding? = null
    private val binding get() = _binding!!
    private var nextTask: TimingTaskInfo? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentSystemSceneMainBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val chargeConfig = requireContext().getSharedPreferences(SpfConfig.CHARGE_SPF, Context.MODE_PRIVATE)
        if (chargeConfig.getBoolean(SpfConfig.CHARGE_SPF_BP, false)) {
            binding.systemSceneBp.visibility = View.VISIBLE
            val limit = chargeConfig.getInt(SpfConfig.CHARGE_SPF_BP_LEVEL, SpfConfig.CHARGE_SPF_BP_LEVEL_DEFAULT)
            binding.systemSceneBpLt.text = (limit - 20).toString() + "%"
            binding.systemSceneBpGt.text = limit.toString() + "%"
        }

        binding.systemSceneAddTask.setOnClickListener {
            startActivity(Intent(requireContext(), ActivityTimingTask::class.java))
        }

        binding.systemSceneAddTrigger.setOnClickListener {
            startActivity(Intent(requireContext(), ActivityTrigger::class.java))
        }
    }

    override fun onResume() {
        super.onResume()
        updateCustomList()
    }

    private fun updateCustomList() {
        nextTask = null
        binding.systemSceneTaskList.removeAllViews()
        TimingTaskManager(requireContext()).listTask().forEach {
            addCustomTaskItemView(it)
            checkNextTask(it)
        }
        updateNextTaskInfo()

        binding.systemSceneTriggerList.removeAllViews()
        TriggerManager(requireContext()).list().forEach {
            it?.run {
                addCustomTriggerView(it)
            }
        }
    }

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

    private fun buildCustomTaskItemView(timingTaskInfo: TimingTaskInfo): SceneTaskItem {
        val sceneTaskItem = SceneTaskItem(requireContext(), timingTaskInfo)
        sceneTaskItem.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        sceneTaskItem.isClickable = true
        return sceneTaskItem
    }

    private fun addCustomTaskItemView(timingTaskInfo: TimingTaskInfo) {
        val sceneTaskItem = buildCustomTaskItemView(timingTaskInfo)

        binding.systemSceneTaskList.addView(sceneTaskItem)
        sceneTaskItem.setOnClickListener {
            val intent = Intent(requireContext(), ActivityTimingTask::class.java)
            intent.putExtra("taskId", timingTaskInfo.taskId)
            startActivity(intent)
        }
        sceneTaskItem.setOnLongClickListener {
            DialogHelper.confirm(requireActivity(), "Delete this task?", "", {
                TimingTaskManager(requireContext()).removeTask(timingTaskInfo)
                updateCustomList()
            })
            true
        }
    }

    private fun addCustomTriggerView(triggerInfo: TriggerInfo) {
        val itemView = SceneTriggerItem(requireContext(), triggerInfo)
        itemView.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        itemView.isClickable = true

        binding.systemSceneTriggerList.addView(itemView)

        itemView.setOnClickListener {
            val intent = Intent(requireContext(), ActivityTrigger::class.java)
            intent.putExtra("id", triggerInfo.id)
            startActivity(intent)
        }
        itemView.setOnLongClickListener {
            DialogHelper.confirm(requireActivity(), "Delete this trigger?", "", {
                TriggerManager(requireContext()).removeTrigger(triggerInfo)
                updateCustomList()
            })
            true
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
