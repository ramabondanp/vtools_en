package com.omarea.vtools.fragments

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.*
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.omarea.Scene
import com.omarea.common.shared.FilePathResolver
import com.omarea.common.shared.FileWrite
import com.omarea.common.shell.KeepShellPublic
import com.omarea.common.ui.DialogHelper
import com.omarea.common.ui.ThemeMode
import com.omarea.data.EventBus
import com.omarea.data.EventType
import com.omarea.krscript.model.PageNode
import com.omarea.library.shell.ThermalDisguise
import com.omarea.permissions.CheckRootStatus
import com.omarea.scene_mode.CpuConfigInstaller
import com.omarea.scene_mode.ModeSwitcher
import com.omarea.store.SpfConfig
import com.omarea.utils.AccessibleServiceHelper
import com.omarea.vtools.R
import com.omarea.vtools.activities.*
import com.projectkr.shell.OpenPageHelper
import com.omarea.vtools.databinding.FragmentCpuModesBinding
import java.io.File
import java.nio.charset.Charset
import java.util.*

class FragmentCpuModes : Fragment() {
    private var _binding: FragmentCpuModesBinding? = null
    private val binding get() = _binding!!

    private var author: String = ""
    private var configFileInstalled: Boolean = false
    private lateinit var modeSwitcher: ModeSwitcher
    private lateinit var globalSPF: SharedPreferences
    private lateinit var themeMode: ThemeMode

    companion object {
        fun createPage(themeMode: ThemeMode): Fragment {
            val fragment = FragmentCpuModes()
            fragment.themeMode = themeMode;
            return fragment
        }
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?,
                              savedInstanceState: Bundle?): View {
        _binding = FragmentCpuModesBinding.inflate(inflater, container, false)
        return binding.root
    }

    private fun startService() {
        AccessibleServiceHelper().stopSceneModeService(activity!!.applicationContext)
        Scene.toast(getString(R.string.accessibility_please_activate), Toast.LENGTH_SHORT)
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            startActivity(intent)
        } catch (e: Exception) {
        }
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        globalSPF = context!!.getSharedPreferences(SpfConfig.GLOBAL_SPF, Context.MODE_PRIVATE)
        modeSwitcher = ModeSwitcher()

        bindMode(binding.cpuConfigP0, ModeSwitcher.POWERSAVE)
        bindMode(binding.cpuConfigP1, ModeSwitcher.BALANCE)
        bindMode(binding.cpuConfigP2, ModeSwitcher.PERFORMANCE)
        bindMode(binding.cpuConfigP3, ModeSwitcher.FAST)

        binding.dynamicControl.setOnClickListener {
            val value = (it as Switch).isChecked
            if (value && !(modeSwitcher.modeConfigCompleted())) {
                it.isChecked = false
                DialogHelper.alert(context!!, getString(R.string.sorry), getString(R.string.schedule_unfinished))
            } else if (value && !AccessibleServiceHelper().serviceRunning(context!!)) {
                it.isChecked = false
                startService()
            } else {
                globalSPF.edit().putBoolean(SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL, value).apply()
                reStartService()
            }
        }
        binding.dynamicControlOpts2.initExpand(false)
        binding.dynamicControl.setOnCheckedChangeListener { _, isChecked ->
            binding.dynamicControlOpts.visibility = if (isChecked) View.VISIBLE else View.GONE
        }
        binding.dynamicControlToggle.setOnClickListener {
            binding.dynamicControlOpts2.toggleExpand()
            if (binding.dynamicControlOpts2.isExpand) {
                (it as ImageView).setImageDrawable(ContextCompat.getDrawable(context!!, R.drawable.arrow_up))
            } else {
                (it as ImageView).setImageDrawable(ContextCompat.getDrawable(context!!, R.drawable.arrow_down))
            }
        }

        binding.strictMode.isChecked = globalSPF.getBoolean(SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL_STRICT, false)
        binding.strictMode.setOnClickListener {
            val checked = (it as CompoundButton).isChecked
            globalSPF.edit().putBoolean(SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL_STRICT, checked).apply()
        }

        binding.delaySwitch.isChecked = globalSPF.getBoolean(SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL_DELAY, false)
        binding.delaySwitch.setOnClickListener {
            val checked = (it as CompoundButton).isChecked
            globalSPF.edit().putBoolean(SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL_DELAY, checked).apply()
        }

        binding.firstMode.run {
            when (globalSPF.getString(SpfConfig.GLOBAL_SPF_POWERCFG_FIRST_MODE, ModeSwitcher.BALANCE)) {
                ModeSwitcher.POWERSAVE -> setSelection(0)
                ModeSwitcher.BALANCE -> setSelection(1)
                ModeSwitcher.PERFORMANCE -> setSelection(2)
                ModeSwitcher.FAST -> setSelection(3)
                ModeSwitcher.IGONED -> setSelection(4)
            }

            onItemSelectedListener = ModeOnItemSelectedListener(globalSPF) {
                reStartService()
            }
        }

        binding.sleepMode.run {
            when (globalSPF.getString(SpfConfig.GLOBAL_SPF_POWERCFG_SLEEP_MODE, ModeSwitcher.POWERSAVE)) {
                ModeSwitcher.POWERSAVE -> setSelection(0)
                ModeSwitcher.BALANCE -> setSelection(1)
                ModeSwitcher.PERFORMANCE -> setSelection(2)
                ModeSwitcher.IGONED -> setSelection(3)
            }
            onItemSelectedListener = ModeOnItemSelectedListener2(globalSPF) {
            }
        }

        val sourceClick = object : View.OnClickListener {
            override fun onClick(it: View) {
                if (configInstaller.outsideConfigInstalled()) {
                    if (configInstaller.dynamicSupport(context!!)) {
                        DialogHelper.warning(
                            activity!!,
                            getString(R.string.make_choice),
                            getString(R.string.schedule_remove_outside),
                            {
                                configInstaller.removeOutsideConfig()
                                reStartService()
                                updateState()
                                chooseConfigSource()
                            })
                    } else {
                        Scene.toast(getString(R.string.schedule_unofficial), Toast.LENGTH_LONG)
                    }
                } else if (configInstaller.dynamicSupport(context!!)) {
                    chooseConfigSource()
                } else {
                    Scene.toast(getString(R.string.schedule_unsupported), Toast.LENGTH_LONG)
                }
            }
        }
        binding.configAuthorIcon.setOnClickListener(sourceClick)
        binding.configAuthor.setOnClickListener(sourceClick)

        binding.navBatteryStats.setOnClickListener {
            val intent = Intent(context, ActivityPowerUtilization::class.java)
            startActivity(intent)
        }
        binding.navAppScene.setOnClickListener {
            if (!AccessibleServiceHelper().serviceRunning(context!!)) {
                startService()
            } else if (binding.dynamicControl.isChecked) {
                val intent = Intent(context, ActivityAppConfig2::class.java)
                startActivity(intent)
            } else {
                DialogHelper.warning(
                        activity!!,
                        getString(R.string.please_notice),
                        getString(R.string.schedule_dynamic_off), {
                    val intent = Intent(context, ActivityAppConfig2::class.java)
                    startActivity(intent)
                })
            }
        }
        // 激活辅助服务按钮
        binding.navSceneServiceNotActive.setOnClickListener {
            startService()
        }
        // 自动跳过广告
        binding.navSkipAd.setOnClickListener {
            if (AccessibleServiceHelper().serviceRunning(context!!)) {
                val intent = Intent(context, ActivityAutoClick::class.java)
                startActivity(intent)
            } else {
                startService()
            }
        }
        if (CheckRootStatus.lastCheckResult) {
            binding.navMore.visibility = View.VISIBLE
            if (Build.MANUFACTURER.lowercase(Locale.getDefault()) == "xiaomi") {
                binding.navThermal.setOnClickListener {
                    val pageNode = PageNode("").apply {
                        title = "MIUI only"
                        pageConfigPath = "file:///android_asset/kr-script/miui/miui.xml"
                    }
                    OpenPageHelper(activity!!).openPage(pageNode)
                }
            } else {
                binding.navThermal.visibility = View.GONE
            }
            binding.navProcesses.setOnClickListener {
                val intent = Intent(context, ActivityProcess::class.java)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
            binding.navFreeze.setOnClickListener {
                if (AccessibleServiceHelper().serviceRunning(context!!)) {
                    val intent = Intent(Intent.ACTION_VIEW)
                    intent.setClassName(
                        "com.omarea.vtools", "com.omarea.vtools.activities.ActivityFreezeApps2"
                    )
                    startActivity(intent)
                } else {
                    startService()
                }
            }
        }

        if (!modeSwitcher.modeConfigCompleted() && configInstaller.dynamicSupport(context!!)) {
            installConfig(false)
        }
        // 卓越性能 目前仅限888处理器开放
        binding.extremePerformance.visibility = if (ThermalDisguise().supported()) View.VISIBLE else View.GONE
        binding.extremePerformanceOn.setOnClickListener {
            val isChecked = (it as CompoundButton).isChecked
            if (isChecked) {
                ThermalDisguise().disableMessage()
            } else {
                ThermalDisguise().resumeMessage()
            }
        }
    }

    // 选择配置来源
    private fun chooseConfigSource() {
        val view = layoutInflater.inflate(R.layout.dialog_powercfg_source, null)
        val dialog = DialogHelper.customDialog(activity!!, view)

        val conservative = view.findViewById<View>(R.id.source_official_conservative)
        val active = view.findViewById<View>(R.id.source_official_active)

        val cpuConfigInstaller = CpuConfigInstaller()
        if (cpuConfigInstaller.dynamicSupport(context!!)) {
            conservative.setOnClickListener {
                if (configInstaller.outsideConfigInstalled()) {
                    configInstaller.removeOutsideConfig()
                }
                installConfig(false)

                dialog.dismiss()
            }
            active.setOnClickListener {
                if (configInstaller.outsideConfigInstalled()) {
                    configInstaller.removeOutsideConfig()
                }
                installConfig(true)

                dialog.dismiss()
            }
        } else {
            conservative.visibility = View.GONE
            active.visibility = View.GONE
        }

        view.findViewById<View>(R.id.source_import).setOnClickListener {
            chooseLocalConfig()

            dialog.dismiss()
        }
        view.findViewById<View>(R.id.source_download).setOnClickListener {
            // TODO:改为清空此前的所有自定义配置，而不仅仅是外部配置
            if (outsideOverrode()) {
                configInstaller.removeOutsideConfig()
            }

            getOnlineConfig()

            dialog.dismiss()
        }
        view.findViewById<View>(R.id.source_custom).setOnClickListener {
            // TODO:改为清空此前的所有自定义配置，而不仅仅是外部配置
            if (outsideOverrode()) {
                configInstaller.removeOutsideConfig()
            }
            globalSPF.edit().putString(SpfConfig.GLOBAL_SPF_PROFILE_SOURCE, ModeSwitcher.SOURCE_SCENE_CUSTOM).apply()
            updateState()

            dialog.dismiss()
        }
    }

    private fun bindSPF(checkBox: CompoundButton, spf: SharedPreferences, prop: String, defValue: Boolean = false, restartService: Boolean = false) {
        checkBox.isChecked = spf.getBoolean(prop, defValue)
        checkBox.setOnCheckedChangeListener { _, isChecked ->
            spf.edit().putBoolean(prop, isChecked).apply()
            if (restartService) {
                reStartService()
            }
        }
    }

    private class ModeOnItemSelectedListener(private var globalSPF: SharedPreferences, private var runnable: Runnable) : AdapterView.OnItemSelectedListener {
        override fun onNothingSelected(parent: AdapterView<*>?) {
        }

        @SuppressLint("ApplySharedPref")
        override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
            var mode = ModeSwitcher.DEFAULT
            when (position) {
                0 -> mode = ModeSwitcher.POWERSAVE
                1 -> mode = ModeSwitcher.BALANCE
                2 -> mode = ModeSwitcher.PERFORMANCE
                3 -> mode = ModeSwitcher.FAST
                4 -> mode = ModeSwitcher.IGONED
            }
            if (globalSPF.getString(SpfConfig.GLOBAL_SPF_POWERCFG_FIRST_MODE, ModeSwitcher.DEFAULT) != mode) {
                globalSPF.edit().putString(SpfConfig.GLOBAL_SPF_POWERCFG_FIRST_MODE, mode).commit()
                runnable.run()
            }
        }
    }

    private class ModeOnItemSelectedListener2(private var globalSPF: SharedPreferences, private var runnable: Runnable) : AdapterView.OnItemSelectedListener {
        override fun onNothingSelected(parent: AdapterView<*>?) {
        }

        @SuppressLint("ApplySharedPref")
        override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
            var mode = ModeSwitcher.POWERSAVE
            when (position) {
                0 -> mode = ModeSwitcher.POWERSAVE
                1 -> mode = ModeSwitcher.BALANCE
                2 -> mode = ModeSwitcher.PERFORMANCE
                3 -> mode = ModeSwitcher.IGONED
            }
            if (globalSPF.getString(SpfConfig.GLOBAL_SPF_POWERCFG_SLEEP_MODE, ModeSwitcher.POWERSAVE) != mode) {
                globalSPF.edit().putString(SpfConfig.GLOBAL_SPF_POWERCFG_SLEEP_MODE, mode).commit()
                runnable.run()
            }
        }
    }

    private fun bindMode(button: View, mode: String) {
        button.setOnClickListener {
            val binding = _binding ?: return@setOnClickListener
            if (mode == ModeSwitcher.FAST && ModeSwitcher.getCurrentSource() == ModeSwitcher.SOURCE_OUTSIDE_UPERF) {
                DialogHelper.warning(
                        activity!!,
                        getString(R.string.please_notice),
                        getString(R.string.schedule_uperf_fast),
                        {
                            modeSwitcher.executePowercfgMode(mode, context!!.packageName)
                            updateState(binding.cpuConfigP3, ModeSwitcher.FAST)
                        }
                )
            } else {
                modeSwitcher.executePowercfgMode(mode, context!!.packageName)
                updateState(binding.cpuConfigP0, ModeSwitcher.POWERSAVE)
                updateState(binding.cpuConfigP1, ModeSwitcher.BALANCE)
                updateState(binding.cpuConfigP2, ModeSwitcher.PERFORMANCE)
                updateState(binding.cpuConfigP3, ModeSwitcher.FAST)
            }
        }
    }

    private fun updateState() {
        val binding = _binding ?: return
        val outsideInstalled = configInstaller.outsideConfigInstalled()
        configFileInstalled = outsideInstalled || configInstaller.insideConfigInstalled()
        author = ModeSwitcher.getCurrentSource()

        binding.configAuthor.text = ModeSwitcher.getCurrentSourceName()

        updateState(binding.cpuConfigP0, ModeSwitcher.POWERSAVE)
        updateState(binding.cpuConfigP1, ModeSwitcher.BALANCE)
        updateState(binding.cpuConfigP2, ModeSwitcher.PERFORMANCE)
        updateState(binding.cpuConfigP3, ModeSwitcher.FAST)
        val serviceState = AccessibleServiceHelper().serviceRunning(context!!)
        val dynamicControl = globalSPF.getBoolean(SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL, SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL_DEFAULT)
        binding.dynamicControl.isChecked = dynamicControl && serviceState
        binding.navSceneServiceNotActive.visibility = if (serviceState) View.GONE else View.VISIBLE

        if (dynamicControl && !modeSwitcher.modeConfigCompleted()) {
            globalSPF.edit().putBoolean(SpfConfig.GLOBAL_SPF_DYNAMIC_CONTROL, false).apply()
            binding.dynamicControl.isChecked = false
            reStartService()
        }
        binding.dynamicControlOpts.postDelayed({
            val binding = _binding ?: return@postDelayed
            binding.dynamicControlOpts.visibility = if (binding.dynamicControl.isChecked) View.VISIBLE else View.GONE
        }, 15)
        binding.extremePerformanceOn.isChecked = ThermalDisguise().isDisabled()
    }

    private fun updateState(button: View, mode: String) {
        val isCurrent = ModeSwitcher.getCurrentPowerMode() == mode
        button.alpha = if (configFileInstalled && isCurrent) 1f else 0.4f
    }

    override fun onResume() {
        super.onResume()

        val currentAuthor = author
        updateState()

        // 如果开启了动态响应 并且配置作者变了，重启后台服务
        val binding = _binding
        if (binding != null && binding.dynamicControl.isChecked && !currentAuthor.isEmpty() && currentAuthor != author) {
            reStartService()
        }
    }

    private val configInstaller = CpuConfigInstaller()

    private val REQUEST_POWERCFG_FILE = 1
    private val REQUEST_POWERCFG_ONLINE = 2
    // 是否使用内置的文件选择器
    private var useInnerFileChooser = false
    private fun chooseLocalConfig() {
        val action = REQUEST_POWERCFG_FILE
        if (Build.VERSION.SDK_INT >= 30 && !Environment.isExternalStorageManager()) {
            useInnerFileChooser = false
            val intent = Intent(Intent.ACTION_GET_CONTENT)
            intent.type = "*/*"
            intent.addCategory(Intent.CATEGORY_OPENABLE)
            startActivityForResult(intent, action)
        } else {
            useInnerFileChooser = true
            try {
                val intent = Intent(this.context, ActivityFileSelector::class.java)
                intent.putExtra("extension", "sh")
                startActivityForResult(intent, action)
            } catch (ex: Exception) {
                Toast.makeText(context, "Failed to launch built-in file picker!", Toast.LENGTH_SHORT).show()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_POWERCFG_FILE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                // 安卓原生文件选择器
                if (Build.VERSION.SDK_INT >= 30 && !useInnerFileChooser) {
                    val absPath = FilePathResolver().getPath(this.activity, data.data)
                    if (absPath != null) {
                        if (absPath.endsWith(".sh")) {
                            installLocalConfig(absPath)
                        } else {
                            Toast.makeText(context, "Invalid file (should be a .sh file)!", Toast.LENGTH_SHORT).show()
                        }
                    } else {
                        Toast.makeText(context, "Selected file not found!", Toast.LENGTH_SHORT).show()
                    }
                } else { // Scene内置文件选择器
                    if (data.extras?.containsKey("file") != true) {
                        return
                    }
                    val path = data.extras!!.getString("file")!!
                    installLocalConfig(path)
                }
            }
            return
        } else if (requestCode == REQUEST_POWERCFG_ONLINE) {
            if (resultCode == Activity.RESULT_OK) {
                configInstalled()
            }
        }
    }

    private fun openUrl(link: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(link))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (ex: Exception) {
        }
    }

    private fun readFileLines(file: File): String? {
        if (file.canRead()) {
            return file.readText(Charset.defaultCharset()).trimStart().replace("\r", "")
        } else {
            val innerPath = FileWrite.getPrivateFilePath(context!!, "powercfg.tmp")
            KeepShellPublic.doCmdSync("cp \"${file.absolutePath}\" \"$innerPath\"\nchmod 777 \"$innerPath\"")
            val tmpFile = File(innerPath)
            if (tmpFile.exists() && tmpFile.canRead()) {
                val lines = tmpFile.readText(Charset.defaultCharset()).trimStart().replace("\r", "")
                KeepShellPublic.doCmdSync("rm \"$innerPath\"")
                return lines
            }
        }
        return null
    }

    private fun getOnlineConfig() {
        DialogHelper.alert(this.activity!!,
                "Notice",
                "Scene no longer provides online config scripts. If needed, use the optimization module by \"yc9559\" and flash it with Magisk, then reboot to use scheduling switches in Scene.") {
            openUrl("https://github.com/yc9559/uperf")
        }

        /*
        var i = 0
        DialogHelper.animDialog(AlertDialog.Builder(context)
                .setTitle(getString(R.string.config_online_options))
                .setCancelable(true)
                .setSingleChoiceItems(
                        arrayOf(
                                getString(R.string.online_config_v1),
                                getString(R.string.online_config_v2)
                        ), 0) { _, which ->
                    i = which
                }
                .setNegativeButton(R.string.btn_confirm) { _, _ ->
                    if (i == 0) {
                        getOnlineConfigV1()
                    } else if (i == 1) {
                        getOnlineConfigV2()
                    }
                })
         */
    }

    private fun installLocalConfig(path: String) {
        if (!path.endsWith(".sh")) {
            Toast.makeText(context, "This seems to be an invalid script file!", Toast.LENGTH_LONG).show()
            return
        }

        val file = File(path)
        if (file.exists()) {
            if (file.length() > 200 * 1024) {
                Toast.makeText(context, "File too large; config scripts must be <= 200KB!", Toast.LENGTH_LONG).show()
                return
            }
            val lines = readFileLines(file)
            if (lines == null) {
                Toast.makeText(context, "Scene cannot read this file!", Toast.LENGTH_LONG).show()
                return
            }
            val configStar = lines.split("\n").firstOrNull()
            if (configStar != null && (configStar.startsWith("#!/") || lines.contains("echo "))) {
                if (configInstaller.installCustomConfig(context!!, lines, ModeSwitcher.SOURCE_SCENE_IMPORT)) {
                    configInstalled()
                } else {
                    Toast.makeText(context, "Failed to install config script. Please retry.", Toast.LENGTH_LONG).show()
                }
            } else {
                Toast.makeText(context, "This seems to be an invalid script file!", Toast.LENGTH_LONG).show()
            }
        } else {
            Toast.makeText(context, "Selected file not found!", Toast.LENGTH_LONG).show()
        }
    }

    //安装调频文件
    private fun installConfig(active: Boolean) {
        if (!configInstaller.dynamicSupport(context!!)) {
            Scene.toast(R.string.not_support_config, Toast.LENGTH_LONG)
            return
        }

        configInstaller.installOfficialConfig(context!!, "", active)
        configInstalled()
    }

    private fun configInstalled() {
        updateState()
        reStartService()
    }

    private fun outsideOverrode(): Boolean {
        if (configInstaller.outsideConfigInstalled()) {
            DialogHelper.helpInfo(activity!!, "You need to delete the external config first because Scene will prioritize it.")
            return true
        }
        return false
    }

    /**
     * 重启辅助服务
     */
    private fun reStartService() {
        EventBus.publish(EventType.SERVICE_UPDATE)
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
