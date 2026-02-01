package com.omarea.vtools.activities

import android.app.ActivityManager
import android.content.Intent
import android.content.res.Configuration
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.os.PersistableBundle
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import com.omarea.Scene
import com.omarea.common.shell.KeepShellPublic
import com.omarea.common.ui.ThemeMode
import com.omarea.store.SpfConfig
import com.omarea.vtools.R

open class ActivityBase : AppCompatActivity() {
    public lateinit var themeMode: ThemeMode
    private var lastUiMode = Configuration.UI_MODE_NIGHT_UNDEFINED
    private var lastThemePref = Int.MIN_VALUE
    private val themePrefs: SharedPreferences by lazy {
        getSharedPreferences(SpfConfig.GLOBAL_SPF, Context.MODE_PRIVATE)
    }
    override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
        super.onCreate(savedInstanceState, persistentState)

        this.themeMode = ThemeSwitch.switchTheme(this)
        lastUiMode = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        lastThemePref = themePrefs.getInt(SpfConfig.GLOBAL_SPF_THEME, -1)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        this.themeMode = ThemeSwitch.switchTheme(this)
        lastUiMode = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        lastThemePref = themePrefs.getInt(SpfConfig.GLOBAL_SPF_THEME, -1)
    }

    protected val context: Context
        get() {
            return this
        }

    protected fun setBackArrow() {
        val toolbar = findViewById<View>(R.id.toolbar) as Toolbar
        setSupportActionBar(toolbar)

        // 显示返回按钮
        supportActionBar!!.setHomeButtonEnabled(true)
        supportActionBar!!.setDisplayHomeAsUpEnabled(true)
        toolbar.setNavigationOnClickListener {
            this.onBackPressed()
        }
    }

    override fun onBackPressed() {
        // If this activity is the task root, return to main instead of exiting.
        if (isTaskRoot && this !is ActivityMain) {
            val intent = Intent(this, ActivityMain::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra(ActivityMain.EXTRA_SELECT_TAB, ActivityMain.lastSelectedTab)
            }
            startActivity(intent)
        }
        // FIX: Activity(IRequestFinishCallback$Stub) 内存泄露
        finishAfterTransition()
    }

    protected fun excludeFromRecent() {
        try {
            val service = this.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            for (task in service.appTasks) {
                if (task.taskInfo.taskId == this.taskId) {
                    task.setExcludeFromRecents(true)
                }
            }
        } catch (ex: Exception) {
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Scene.postDelayed({
            System.gc()
        }, 500)
        if (isTaskRoot) {
            Scene.postDelayed({
                KeepShellPublic.doCmdSync("dumpsys meminfo " + context.packageName + " > /dev/null")
            }, 100)
        }
    }

    override fun onResume() {
        super.onResume()
        val currentThemePref = themePrefs.getInt(SpfConfig.GLOBAL_SPF_THEME, -1)
        if (currentThemePref != lastThemePref) {
            lastThemePref = currentThemePref
            themeMode = ThemeSwitch.switchTheme(this)
            if (!isFinishing && !isDestroyed) {
                recreate()
            }
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        val newUiMode = newConfig.uiMode and Configuration.UI_MODE_NIGHT_MASK
        if (newUiMode != lastUiMode) {
            lastUiMode = newUiMode
            themeMode = ThemeSwitch.switchTheme(this)
            if (!isFinishing && !isDestroyed) {
                recreate()
            }
        }
    }
}
