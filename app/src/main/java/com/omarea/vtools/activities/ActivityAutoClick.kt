package com.omarea.vtools.activities

import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.CompoundButton
import com.omarea.common.ui.AdapterAppChooser
import com.omarea.common.ui.DialogAppChooser
import com.omarea.common.ui.ProgressBarDialog
import com.omarea.data.EventBus
import com.omarea.data.EventType
import com.omarea.store.SpfConfig
import com.omarea.utils.AppListHelper
import com.omarea.utils.AutoSkipCloudData
import com.omarea.vtools.R
import com.omarea.vtools.databinding.ActivityAutoClickBinding


class ActivityAutoClick : ActivityBase() {
    private lateinit var processBarDialog: ProgressBarDialog
    private lateinit var globalSPF: SharedPreferences
    internal val myHandler: Handler = Handler(Looper.getMainLooper())
    private lateinit var binding: ActivityAutoClickBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAutoClickBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setBackArrow()
        processBarDialog = ProgressBarDialog(this)

        globalSPF = getSharedPreferences(SpfConfig.GLOBAL_SPF, Context.MODE_PRIVATE)

        bindSPF(binding.settingsAutoInstall, globalSPF, SpfConfig.GLOBAL_SPF_AUTO_INSTALL, false)
        bindSPF(binding.settingsSkipAd, globalSPF, SpfConfig.GLOBAL_SPF_SKIP_AD, false)
        bindSPF(binding.settingsSkipAdPrecise, globalSPF, SpfConfig.GLOBAL_SPF_SKIP_AD_PRECISE, false)

        binding.settingsSkipAd.setOnCheckedChangeListener { _, isChecked ->
            if (isChecked) {
                if (globalSPF.getBoolean(SpfConfig.GLOBAL_SPF_SKIP_AD_PRECISE, false)) {
                    AutoSkipCloudData().updateConfig(context, true)
                }
            }
        }

        binding.settingsSkipAdPrecise.setOnCheckedChangeListener { _, isChecked ->
            if (isChecked) {
                AutoSkipCloudData().updateConfig(context, true)
            }
        }

        binding.adSkipBlacklist.setOnClickListener {
            adBlackListConfig()
        }
    }

    override fun onResume() {
        super.onResume()
        title = getString(R.string.menu_auto_click)
    }

    private fun bindSPF(checkBox: CompoundButton, spf: SharedPreferences, prop: String, defValue: Boolean = false) {
        checkBox.isChecked = spf.getBoolean(prop, defValue)
        checkBox.setOnClickListener { view ->
            spf.edit().putBoolean(prop, (view as CompoundButton).isChecked).apply()
            EventBus.publish(EventType.SERVICE_UPDATE)
        }
    }


    // 跳过广告黑名单应用
    private fun adBlackListConfig() {
        processBarDialog.showDialog()
        Thread {
            val configFile = context.getSharedPreferences(SpfConfig.AUTO_SKIP_BLACKLIST, Context.MODE_PRIVATE)
            val options = AppListHelper(context).getBootableApps(null, true).sortedBy {
                it.packageName
            }.map {
                it.apply {
                    selected = configFile.getBoolean(packageName, false)
                }
            }

            myHandler.post {
                processBarDialog.hideDialog()

                DialogAppChooser(
                        themeMode.isDarkMode,
                        ArrayList(options),
                        true,
                        object : DialogAppChooser.Callback {
                    override fun onConfirm(apps: List<AdapterAppChooser.AppInfo>) {
                        val items = apps.map { it.packageName }
                        options.forEach {
                            it.selected = items.contains(it.packageName)
                        }
                        configFile.edit().clear().run {
                            apps.forEach {
                                if (it.selected) {
                                    putBoolean(it.packageName, true)
                                }
                            }
                            apply()
                        }

                    }
                }).show(supportFragmentManager, "standby_apps")
            }
        }.start()
    }

}
