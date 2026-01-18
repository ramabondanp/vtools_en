package com.omarea.vtools.workers

import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.ForegroundInfo
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.omarea.common.shared.RawText
import com.omarea.common.shell.KeepShell
import com.omarea.common.shell.KernelProrp
import com.omarea.data.EventBus
import com.omarea.data.EventType
import com.omarea.library.shell.BatteryUtils
import com.omarea.library.shell.LMKUtils
import com.omarea.library.shell.PropsUtils
import com.omarea.library.shell.SwapUtils
import com.omarea.scene_mode.ModeSwitcher
import com.omarea.scene_mode.SceneMode
import com.omarea.store.CpuConfigStorage
import com.omarea.store.SceneConfigStore
import com.omarea.store.SpfConfig
import com.omarea.utils.CommonCmds
import com.omarea.vtools.R

class BootWorker(
    private val appContext: Context,
    params: WorkerParameters
) : Worker(appContext, params) {
    companion object {
        private const val NOTIFICATION_ID = 900
        private const val CHANNEL_ID = "vtool-boot"
    }

    private lateinit var swapConfig: SharedPreferences
    private lateinit var globalConfig: SharedPreferences
    private var isFirstBoot = true
    private var bootCancel = false
    private lateinit var nm: NotificationManager
    private var channelCreated = false
    private var foregroundStarted = false

    override fun doWork(): Result {
        nm = appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        swapConfig = appContext.getSharedPreferences(SpfConfig.SWAP_SPF, Context.MODE_PRIVATE)
        globalConfig = appContext.getSharedPreferences(SpfConfig.GLOBAL_SPF, Context.MODE_PRIVATE)

        if (globalConfig.getBoolean(SpfConfig.GLOBAL_SPF_START_DELAY, false)) {
            Thread.sleep(25 * 1000L)
        } else {
            Thread.sleep(2000L)
        }
        val r = PropsUtils.getProp("vtools.boot")
        if (r.isNotEmpty()) {
            isFirstBoot = false
            bootCancel = true
            hideNotification()
            return Result.success()
        }

        setForegroundNotice(appContext.getString(R.string.boot_script_running))
        EventBus.publish(EventType.BOOT_COMPLETED)
        autoBoot()
        return Result.success()
    }

    private fun autoBoot() {
        val keepShell = KeepShell()

        if (globalConfig.getBoolean(SpfConfig.GLOBAL_SPF_DISABLE_ENFORCE, false)) {
            keepShell.doCmdSync(CommonCmds.DisableSELinux)
        }

        val cpuConfigStorage = CpuConfigStorage(appContext)
        val cpuState = cpuConfigStorage.load()
        if (cpuState != null) {
            updateNotification(appContext.getString(R.string.boot_cpuset))
            cpuConfigStorage.applyCpuConfig(cpuConfigStorage.default())
        }

        val macChangeMode = globalConfig.getInt(SpfConfig.GLOBAL_SPF_MAC_AUTOCHANGE_MODE, 0)
        val mac = globalConfig.getString(SpfConfig.GLOBAL_SPF_MAC, "")
        if (!mac.isNullOrEmpty()) {
            when (macChangeMode) {
                SpfConfig.GLOBAL_SPF_MAC_AUTOCHANGE_MODE_1 -> {
                    updateNotification(appContext.getString(R.string.boot_modify_mac))
                    keepShell.doCmdSync("mac=\"$mac\"\n" + RawText.getRawText(appContext, R.raw.change_mac_1))
                }
                SpfConfig.GLOBAL_SPF_MAC_AUTOCHANGE_MODE_2 -> {
                    updateNotification(appContext.getString(R.string.boot_modify_mac))
                    keepShell.doCmdSync("mac=\"$mac\"\n" + RawText.getRawText(appContext, R.raw.change_mac_2))
                }
            }
        }

        val chargeConfig = appContext.getSharedPreferences(SpfConfig.CHARGE_SPF, Context.MODE_PRIVATE)
        if (chargeConfig.getBoolean(SpfConfig.CHARGE_SPF_QC_BOOSTER, false) || chargeConfig.getBoolean(SpfConfig.CHARGE_SPF_BP, false)) {
            updateNotification(appContext.getString(R.string.boot_charge_booster))
            BatteryUtils().setChargeInputLimit(
                chargeConfig.getInt(SpfConfig.CHARGE_SPF_QC_LIMIT, SpfConfig.CHARGE_SPF_QC_LIMIT_DEFAULT),
                appContext
            )
        }

        val globalPowercfg = globalConfig.getString(SpfConfig.GLOBAL_SPF_POWERCFG, "")
        if (!globalPowercfg.isNullOrEmpty()) {
            updateNotification(appContext.getString(R.string.boot_use_powercfg))

            val modeSwitcher = ModeSwitcher()
            if (modeSwitcher.modeConfigCompleted()) {
                modeSwitcher.executePowercfgMode(globalPowercfg, appContext.packageName)
            }
        }

        if (!keepShell.doCmdSync("getprop vtools.swap.controller").equals("magisk")) {
            if (swapConfig.getBoolean(SpfConfig.SWAP_SPF_SWAP, false)) {
                enableSwap(keepShell, appContext)
            }

            if (swapConfig.getBoolean(SpfConfig.SWAP_SPF_ZRAM, false)) {
                val sizeVal = swapConfig.getInt(SpfConfig.SWAP_SPF_ZRAM_SIZE, 0)
                val algorithm = swapConfig.getString(SpfConfig.SWAP_SPF_ALGORITHM, "")

                updateNotification(appContext.getString(R.string.boot_resize_zram))
                resizeZram(sizeVal, algorithm ?: "", keepShell, true)
            }

            if (swapConfig.contains(SpfConfig.SWAP_SPF_SWAPPINESS)) {
                keepShell.doCmdSync("echo 65 > /proc/sys/vm/swappiness\n")
                keepShell.doCmdSync("echo " + swapConfig.getInt(SpfConfig.SWAP_SPF_SWAPPINESS, 65) + " > /proc/sys/vm/swappiness\n")
            }

            if (swapConfig.contains(SpfConfig.SWAP_SPF_EXTRA_FREE_KBYTES)) {
                keepShell.doCmdSync("echo ${swapConfig.getInt(SpfConfig.SWAP_SPF_EXTRA_FREE_KBYTES, 29615)} > /proc/sys/vm/extra_free_kbytes\n")
            }

            if (swapConfig.contains(SpfConfig.SWAP_SPF_WATERMARK_SCALE)) {
                keepShell.doCmdSync("echo ${swapConfig.getInt(SpfConfig.SWAP_SPF_WATERMARK_SCALE, 100)} > /proc/sys/vm/watermark_scale_factor\n")
            }

            if (swapConfig.getBoolean(SpfConfig.SWAP_SPF_AUTO_LMK, false)) {
                updateNotification(appContext.getString(R.string.boot_lmk))

                val activityManager = appContext.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val info = ActivityManager.MemoryInfo()
                activityManager.getMemoryInfo(info)
                LMKUtils().autoSetLMK(info.totalMem, keepShell)
            }
        }

        updateNotification(appContext.getString(R.string.boot_freeze))
        val launchedFreezeApp = SceneMode.getCurrentInstance()?.getLaunchedFreezeApp()
        val suspendMode = globalConfig.getBoolean(SpfConfig.GLOBAL_SPF_FREEZE_SUSPEND, Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
        for (item in SceneConfigStore(appContext).freezeAppList) {
            if (launchedFreezeApp == null || !launchedFreezeApp.contains(item)) {
                if (suspendMode) {
                    SceneMode.suspendApp(item)
                } else {
                    SceneMode.freezeApp(item)
                }
            }
        }

        keepShell.tryExit()
        hideNotification()
    }

    private var compAlgorithm: String
        get() {
            val compAlgorithmItems = KernelProrp.getProp("/sys/block/zram0/comp_algorithm").split(" ")
            val result = compAlgorithmItems.find {
                it.startsWith("[") && it.endsWith("]")
            }
            if (result != null) {
                return result.replace("[", "").replace("]", "").trim()
            }
            return ""
        }
        set(value) {
            KernelProrp.setProp("/sys/block/zram0/comp_algorithm", value)
        }

    private fun enableSwap(keepShell: KeepShell, context: Context) {
        updateNotification(appContext.getString(R.string.boot_swapon))
        val swapPriority = swapConfig.getInt(SpfConfig.SWAP_SPF_SWAP_PRIORITY, -2)
        val useLoop = swapConfig.getBoolean(SpfConfig.SWAP_SPF_SWAP_USE_LOOP, false)
        SwapUtils(context).swapOn(swapPriority, useLoop, keepShell)
    }

    private fun resizeZram(sizeVal: Int, algorithm: String = "", keepShell: KeepShell, swapFirst: Boolean = false) {
        keepShell.doCmdSync(
            "if [[ ! -e /dev/block/zram0 ]] && [[ -e /sys/class/zram-control ]]; then\n" +
                "  cat /sys/class/zram-control/hot_add\n" +
                "fi"
        )
        val currentSize = keepShell.doCmdSync("cat /sys/block/zram0/disksize")
        if (currentSize != "" + (sizeVal * 1024 * 1024L) || (algorithm.isNotEmpty() && algorithm != compAlgorithm)) {
            val sb = StringBuilder()
            sb.append("swappiness_bak=`cat /proc/sys/vm/swappiness`\n")
            if (!swapFirst) {
                sb.append("echo 0 > /proc/sys/vm/swappiness\n")
            }

            sb.append("echo 4 > /sys/block/zram0/max_comp_streams\n")
            sb.append("sync\n")

            sb.append("if [[ -f /sys/block/zram0/backing_dev ]]; then\n")
            sb.append("  backing_dev=$(cat /sys/block/zram0/backing_dev)\n")
            sb.append("fi\n")

            sb.append("echo 3 > /proc/sys/vm/drop_caches\n")
            sb.append("swapoff /dev/block/zram0 >/dev/null 2>&1\n")
            sb.append("echo 1 > /sys/block/zram0/reset\n")

            sb.append("if [[ -f /sys/block/zram0/backing_dev ]]; then\n")
            sb.append("  echo \"\$backing_dev\" > /sys/block/zram0/backing_dev\n")
            sb.append("fi\n")

            if (algorithm.isNotEmpty()) {
                sb.append("echo \"$algorithm\" > /sys/block/zram0/comp_algorithm\n")
            }

            if (sizeVal > 2047) {
                sb.append("echo " + sizeVal + "M > /sys/block/zram0/disksize\n")
            } else {
                sb.append("echo " + (sizeVal * 1024 * 1024L) + " > /sys/block/zram0/disksize\n")
            }

            sb.append("echo 4 > /sys/block/zram0/max_comp_streams\n")
            sb.append("mkswap /dev/block/zram0 >/dev/null 2>&1\n")
            sb.append("swapon /dev/block/zram0 -p 0 >/dev/null 2>&1\n")
            sb.append("echo \$swappiness_bak > /proc/sys/vm/swappiness")
            keepShell.doCmdSync(sb.toString())
        }
    }

    private fun setForegroundNotice(text: String) {
        if (!foregroundStarted) {
            setForegroundAsync(ForegroundInfo(NOTIFICATION_ID, buildNotification(text)))
            foregroundStarted = true
        } else {
            updateNotification(text)
        }
    }

    private fun updateNotification(text: String) {
        nm.notify(NOTIFICATION_ID, buildNotification(text))
    }

    private fun hideNotification() {
        if (bootCancel) {
            nm.cancel(NOTIFICATION_ID)
        } else {
            updateNotification(appContext.getString(R.string.boot_success))
        }
    }

    private fun buildNotification(text: String): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !channelCreated) {
            nm.createNotificationChannel(NotificationChannel(CHANNEL_ID, appContext.getString(R.string.notice_channel_boot), NotificationManager.IMPORTANCE_LOW))
            channelCreated = true
        }
        return NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_menu_digital)
            .setContentTitle(appContext.getString(R.string.notice_channel_boot))
            .setContentText(text)
            .build()
    }
}
