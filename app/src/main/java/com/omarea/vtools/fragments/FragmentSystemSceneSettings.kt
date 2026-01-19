package com.omarea.vtools.fragments

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import com.omarea.common.ui.AdapterAppChooser
import com.omarea.common.ui.DialogAppChooser
import com.omarea.common.ui.ProgressBarDialog
import com.omarea.model.AppInfo
import com.omarea.scene_mode.SceneStandbyMode
import com.omarea.utils.AppListHelper
import com.omarea.vtools.activities.ActivityBase
import com.omarea.vtools.activities.ActivityCustomCommand
import com.omarea.vtools.databinding.FragmentSystemSceneSettingsBinding

class FragmentSystemSceneSettings : Fragment() {
    private var _binding: FragmentSystemSceneSettingsBinding? = null
    private val binding get() = _binding!!
    private val uiHandler = Handler(Looper.getMainLooper())
    private lateinit var processBarDialog: ProgressBarDialog

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentSystemSceneSettingsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        processBarDialog = ProgressBarDialog(requireActivity())

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            binding.systemSceneStandbyApps.visibility = View.VISIBLE
            binding.systemSceneStandbyApps.setOnClickListener {
                standbyAppConfig()
            }
        } else {
            binding.systemSceneStandbyApps.visibility = View.GONE
        }

        binding.systemSceneCommand.setOnClickListener {
            startActivity(Intent(requireContext(), ActivityCustomCommand::class.java))
        }
    }

    private fun standbyAppConfig() {
        processBarDialog.showDialog()
        Thread {
            val context = requireContext()
            val configFile = context.getSharedPreferences(SceneStandbyMode.configSpfName, Context.MODE_PRIVATE)
            val whiteList = context.resources.getStringArray(com.omarea.vtools.R.array.scene_standby_white_list)
            val options = ArrayList(AppListHelper(context).getAll().filter {
                !whiteList.contains(it.packageName)
            }.sortedBy {
                it.appType
            }.map {
                it.apply {
                    selected = configFile.getBoolean(packageName.toString(), it.appType == AppInfo.AppType.USER && !it.updated)
                }
            })

            uiHandler.post {
                processBarDialog.hideDialog()

                val isDark = (requireActivity() as ActivityBase).themeMode.isDarkMode
                DialogAppChooser(isDark, ArrayList(options), true, object : DialogAppChooser.Callback {
                    override fun onConfirm(apps: List<AdapterAppChooser.AppInfo>) {
                        val items = apps.map { it.packageName }
                        options.forEach {
                            it.selected = items.contains(it.packageName)
                        }
                        saveStandbyAppConfig(options)
                    }
                }).show(parentFragmentManager, "standby_apps")
            }
        }.start()
    }

    private fun saveStandbyAppConfig(apps: List<AppInfo>) {
        val configFile = requireContext().getSharedPreferences(SceneStandbyMode.configSpfName, Context.MODE_PRIVATE).edit()
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

    override fun onDestroyView() {
        processBarDialog.hideDialog()
        super.onDestroyView()
        _binding = null
    }
}
