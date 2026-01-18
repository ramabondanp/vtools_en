package com.omarea.vtools.activities

import android.Manifest
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.Switch
import androidx.core.content.PermissionChecker
import com.omarea.common.shell.KeepShellPublic
import com.omarea.common.ui.DialogHelper
import com.omarea.data.EventBus
import com.omarea.data.EventType
import com.omarea.shell_utils.AppErrorLogcatUtils
import com.omarea.store.SpfConfig
import com.omarea.utils.CommonCmds
import com.omarea.vtools.R
import com.omarea.vtools.databinding.ActivityOtherSettingsBinding

class ActivityOtherSettings : ActivityBase() {
    private lateinit var spf: SharedPreferences
    private var myHandler = Handler(Looper.getMainLooper())
    private lateinit var binding: ActivityOtherSettingsBinding

    override fun onPostResume() {
        super.onPostResume()
        delegate.onPostResume()

        binding.settingsDisableSelinux.isChecked = spf.getBoolean(SpfConfig.GLOBAL_SPF_DISABLE_ENFORCE, false)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        spf = getSharedPreferences(SpfConfig.GLOBAL_SPF, Context.MODE_PRIVATE)
        super.onCreate(savedInstanceState)
        binding = ActivityOtherSettingsBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setBackArrow()

        binding.settingsDisableSelinux.setOnClickListener {
            if (binding.settingsDisableSelinux.isChecked) {
                KeepShellPublic.doCmdSync(CommonCmds.DisableSELinux)
                myHandler.postDelayed({
                    spf.edit().putBoolean(SpfConfig.GLOBAL_SPF_DISABLE_ENFORCE, binding.settingsDisableSelinux.isChecked).apply()
                }, 10000)
            } else {
                KeepShellPublic.doCmdSync(CommonCmds.ResumeSELinux)
                spf.edit().putBoolean(SpfConfig.GLOBAL_SPF_DISABLE_ENFORCE, binding.settingsDisableSelinux.isChecked).apply()
            }
        }
        binding.settingsLogcat.setOnClickListener {
            val log = AppErrorLogcatUtils().catLogInfo()
            binding.settingsLogContent.visibility = View.VISIBLE
            binding.settingsLogContent.setText(log)
            binding.settingsLogContent.setSelection(0, log.length)
        }

        binding.settingsDebugLayer.isChecked = spf.getBoolean(SpfConfig.GLOBAL_SPF_SCENE_LOG, false)
        binding.settingsDebugLayer.setOnClickListener {
            spf.edit().putBoolean(SpfConfig.GLOBAL_SPF_SCENE_LOG, (it as Switch).isChecked).apply()

            EventBus.publish(EventType.SERVICE_DEBUG)
        }

        binding.settingsHelpIcon.isChecked = spf.getBoolean(SpfConfig.GLOBAL_SPF_HELP_ICON, true)
        binding.settingsHelpIcon.setOnClickListener {
            spf.edit().putBoolean(SpfConfig.GLOBAL_SPF_HELP_ICON, (it as Switch).isChecked).apply()
        }

        binding.settingsAutoExit.isChecked = spf.getBoolean(SpfConfig.GLOBAL_SPF_AUTO_EXIT, true)
        binding.settingsAutoExit.setOnClickListener {
            spf.edit().putBoolean(SpfConfig.GLOBAL_SPF_AUTO_EXIT, (it as Switch).isChecked).apply()
        }

        binding.settingsBlackNotification.isChecked = spf.getBoolean(SpfConfig.GLOBAL_NIGHT_BLACK_NOTIFICATION, false)
        binding.settingsBlackNotification.setOnClickListener {
            spf.edit().putBoolean(SpfConfig.GLOBAL_NIGHT_BLACK_NOTIFICATION, (it as Switch).isChecked).apply()
        }
    }

    private fun checkPermission(context: Context, permission: String): Boolean = PermissionChecker.checkSelfPermission(context, permission) == PermissionChecker.PERMISSION_GRANTED

    private fun hasRWPermission(): Boolean {
        return checkPermission(this.applicationContext, Manifest.permission.READ_EXTERNAL_STORAGE)
                &&
                checkPermission(this.applicationContext, Manifest.permission.WRITE_EXTERNAL_STORAGE)
    }

    fun onThemeClick(view: View) {
        val tag = view.tag.toString().toInt()
        if (tag == 10 && spf.getInt(SpfConfig.GLOBAL_SPF_THEME, 1) == 10) {
            spf.edit().remove(SpfConfig.GLOBAL_SPF_THEME).apply()
            this.recreate()
        } else {
            if (tag == 10 && !hasRWPermission()) {
                DialogHelper.helpInfo(view.context, "", getString(R.string.wallpaper_rw_permission))
                (view as Switch).isChecked = false
            } else {
                spf.edit().putInt(SpfConfig.GLOBAL_SPF_THEME, tag).apply()
                this.recreate()
            }
        }

    }

    override fun onDestroy() {
        super.onDestroy()

        spf.edit().putBoolean(SpfConfig.GLOBAL_SPF_DISABLE_ENFORCE, binding.settingsDisableSelinux.isChecked).apply()
    }

    public override fun onPause() {
        super.onPause()
    }
}
