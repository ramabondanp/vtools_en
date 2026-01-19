package com.omarea.vtools.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.PowerManager.PARTIAL_WAKE_LOCK
import android.widget.Toast
import androidx.core.app.NotificationCompat
import com.omarea.Scene
import com.omarea.common.shared.FileWrite
import com.omarea.common.shell.KeepShell
import com.omarea.vtools.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.nio.charset.Charset
import java.util.*

/**
 * 后台编译应用
 */
class CompileService : Service() {
    companion object {
        var compiling = false
    }

    private val serviceJob = SupervisorJob()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)

    private var compileCanceled = false
    private var keepShell = KeepShell(true)
    private lateinit var nm: NotificationManager
    private var compile_method = "speed"
    private var channelCreated = false

    private fun getAllPackageNames(): ArrayList<String> {
        val packageManager: PackageManager = packageManager
        val packageInfos = packageManager.getInstalledApplications(0)
        val list = ArrayList<String>()/*在数组中存放数据*/
        for (i in packageInfos.indices) {
            list.add(packageInfos[i].packageName)
        }
        list.remove(packageName)
        // Google gms服务，每次编译都会重新编译，不知什么情况！
        list.remove("com.google.android.gms")
        return list
    }

    private fun updateNotification(title: String, text: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(NotificationChannel("vtool-compile", "Background compile", NotificationManager.IMPORTANCE_LOW))
        }
        nm.notify(990, NotificationCompat.Builder(this, "vtool-compile").setSmallIcon(R.drawable.process)
                .setContentTitle(title)
                .setContentText(text)
                .build())
    }

    private fun updateNotification(title: String, text: String, total: Int, current: Int, autoCancel: Boolean = true) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !channelCreated) {
            nm.createNotificationChannel(NotificationChannel("vtool-compile", "Background compile", NotificationManager.IMPORTANCE_LOW))
            channelCreated = true
        }
        val builder = NotificationCompat.Builder(this, "vtool-compile")

        nm.notify(990, builder
                .setSmallIcon(R.drawable.process)
                .setContentTitle(title)
                .setContentText(text)
                .setAutoCancel(autoCancel)
                .setProgress(total, current, false)
                .build())
    }

    private lateinit var mPowerManager: PowerManager
    private lateinit var mWakeLock: PowerManager.WakeLock

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        serviceScope.launch {
            handleIntent(intent)
            stopSelfResult(startId)
        }
        return START_NOT_STICKY
    }

    private fun handleIntent(intent: Intent?) {
        mPowerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        /*
            标记值                   CPU  屏幕  键盘
            PARTIAL_WAKE_LOCK       开启  关闭  关闭
            SCREEN_DIM_WAKE_LOCK    开启  变暗  关闭
            SCREEN_BRIGHT_WAKE_LOCK 开启  变亮  关闭
            FULL_WAKE_LOCK          开启  变亮  变亮
        */
        mWakeLock = mPowerManager.newWakeLock(PARTIAL_WAKE_LOCK, "scene:CompileService")
        mWakeLock.acquire(60 * 60 * 1000) // 默认限制60分钟

        nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

        if (compiling) {
            compileCanceled = true
            this.hideNotification()
            return
        }

        if (intent != null) {
            if (intent.action == getString(R.string.scene_speed_compile)) {
                compile_method = "speed"
            } else if (intent.action == getString(R.string.scene_speed_profile_compile)) {
                compile_method = "speed-profile"
            } else if (intent.action == getString(R.string.scene_everything_compile)) {
                compile_method = "everything"
            } else if (intent.action == getString(R.string.scene_reset_compile)) {
                compile_method = "reset"
            }
        }

        compiling = true

        val packageNames = getAllPackageNames()
        val total = packageNames.size
        var current = 0
        if (compile_method == "reset") {
            val cmdBuilder = StringBuilder()
            for (packageName in packageNames) {
                if (true) {
                    updateNotification(getString(R.string.dex2oat_reset_running), packageName, total, current)
                    cmdBuilder.append("am broadcast -n com.omarea.vtools/com.omarea.vtools.ReceiverCompileState --ei current $current --ei total $total --es packageName $packageName\n")
                    cmdBuilder.append("cmd package compile --reset ${packageName}\n")
                    current++
                } else {
                    break
                }
            }
            cmdBuilder.append("am broadcast -n com.omarea.vtools/com.omarea.vtools.ReceiverCompileState --ei current $total --ei total $total --es packageName OK\n")
            val cache = "/dex2oat/reset.sh"
            if (FileWrite.writePrivateFile(cmdBuilder.toString().toByteArray(Charset.defaultCharset()), cache, this.applicationContext)) {
                val shellFile = FileWrite.getPrivateFilePath(this.applicationContext, cache)
                keepShell.doCmdSync("sh " + shellFile + " >/dev/null 2>&1 &")
            }
            keepShell.tryExit()
            compileCanceled = true
            Scene.Companion.toast("The phone may lag during reset. Please wait...", Toast.LENGTH_LONG)
        } else {
            for (packageName in packageNames) {
                if (true) {
                    updateNotification(getString(R.string.dex2oat_compiling) + "[" + compile_method + "]", "[$current/$total]$packageName", total, current)
                    keepShell.doCmdSync("cmd package compile -m ${compile_method} ${packageName}")
                    current++
                } else {
                    break
                }
            }
            keepShell.doCmdSync("cmd package compile -m ${compile_method} ${packageName}")
        }
        this.hideNotification()
        keepShell.tryExit()
        compiling = false
    }

    private fun hideNotification() {
        if (compileCanceled) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                nm.cancel(990)
            } else {
                nm.cancel(990)
            }
        } else {
            updateNotification("complete!", getString(R.string.dex2oat_completed), 100, 100, true)
        }
        // System.exit(0)
    }

    override fun onDestroy() {
        this.hideNotification()
        if (this::mWakeLock.isInitialized && mWakeLock.isHeld) {
            mWakeLock.release()
        }

        serviceScope.cancel()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
