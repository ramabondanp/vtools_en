package com.omarea.vtools.activities

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import com.omarea.common.shell.KeepShellPublic
import com.omarea.library.shell.GAppsUtilis
import com.omarea.permissions.CheckRootStatus
import com.omarea.scene_mode.SceneMode
import com.omarea.store.SpfConfig
import com.omarea.utils.WindowCompatHelper
import com.omarea.vtools.R
import com.omarea.vtools.databinding.ActivityQuickStartBinding
import java.lang.ref.WeakReference

class ActivityQuickStart : Activity() {
    lateinit var appPackageName: String
    private lateinit var binding: ActivityQuickStartBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityQuickStartBinding.inflate(layoutInflater)
        setContentView(binding.root)
        actionBar?.setDisplayHomeAsUpEnabled(true)

        //  得到当前界面的装饰视图
        if (Build.VERSION.SDK_INT >= 21) {
            //让应用主题内容占用系统状态栏的空间,注意:下面两个参数必须一起使用 stable 牢固的
            WindowCompatHelper.applyEdgeToEdge(window, lightStatusBars = false, lightNavBars = false)
            WindowCompatHelper.setSystemBarColors(window, Color.TRANSPARENT, null)
        }

        val extras = intent.extras
        if (extras == null || !extras.containsKey("packageName")) {
            updateStartStateText("Invalid shortcut!")
        } else {
            appPackageName = intent.getStringExtra("packageName")!!;
            val pm = packageManager

            var appInfo: ApplicationInfo? = null
            try {
                appInfo = pm.getApplicationInfo(appPackageName, 0)
            } catch (ex: Exception) {
            }
            // SysApi Target Api28(Android P) 但普通应用无法访问
            // val isPackageSuspended = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && pm.isPackageSuspended(appPackageName)
            if (appInfo != null && appInfo.enabled && (appInfo.flags and ApplicationInfo.FLAG_SUSPENDED) == 0) {
                startApp()
            } else {
                checkRoot(CheckRootSuccess(this, appPackageName))
            }
        }
    }

    private class CheckRootSuccess(context: ActivityQuickStart, private var appPackageName: String) : Runnable {
        private var context: WeakReference<ActivityQuickStart>;
        override fun run() {
            context.get()?.updateStartStateText("Launching app...")
            context.get()!!.hasRoot = true

            if (appPackageName.equals("com.android.vending")) {
                GAppsUtilis().enable(KeepShellPublic.secondaryKeepShell);
            } else {
                KeepShellPublic.doCmdSync("pm unsuspend ${appPackageName}\npm unhide ${appPackageName}\npm enable ${appPackageName}\n")
            }
            context.get()!!.startApp()
        }

        init {
            this.context = WeakReference(context)
        }
    }

    private fun startApp() {
        val pm = packageManager
        try {
            val appIntent = pm.getLaunchIntentForPackage(appPackageName)
            if (appIntent != null) {
                Thread {
                    // LauncherApps().startMainActivity()
                    appIntent.flags = Intent.FLAG_ACTIVITY_NO_ANIMATION or Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(appIntent)
                    // overridePendingTransition(0, 0)
                    SceneMode.getCurrentInstance()?.setFreezeAppStartTime(appPackageName)
                }.start()
                return
            }
        } catch (ex: Exception) {
            updateStartStateText("Failed to launch app!")
        }

        var appInfo: ApplicationInfo? = null
        try {
            appInfo = pm.getApplicationInfo(appPackageName, 0)
        } catch (ex: Exception) {
        }
        if (appInfo == null) {
            updateStartStateText("The app seems to be uninstalled!")
        } else {
            updateStartStateText("Failed to launch app!")
        }
    }

    override fun onPause() {
        super.onPause()
        this.finish()
    }

    private var hasRoot = false

    @SuppressLint("ApplySharedPref", "CommitPrefEdits")
    private fun checkRoot(next: Runnable) {
        val globalConfig = getSharedPreferences(SpfConfig.GLOBAL_SPF, Context.MODE_PRIVATE)

        val disableSeLinux = globalConfig.getBoolean(SpfConfig.GLOBAL_SPF_DISABLE_ENFORCE, false)
        CheckRootStatus(this, next, disableSeLinux).forceGetRoot()
    }

    private fun updateStartStateText(text: String) {
        binding.startStateText.text = text
    }
}
