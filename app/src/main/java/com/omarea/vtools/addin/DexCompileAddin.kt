package com.omarea.vtools.addin

import android.app.AlertDialog
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.Toast
import com.omarea.common.ui.DialogHelper
import com.omarea.library.shell.PropsUtils
import com.omarea.utils.CommonCmds
import com.omarea.vtools.R
import com.omarea.vtools.activities.ActivityBase
import com.omarea.vtools.services.CompileService

/**
 * Created by Hello on 2018/02/20.
 */

class DexCompileAddin(private var context: ActivityBase) : AddinBase(context) {
    fun isSupport(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            Toast.makeText(context, "System version too low, Android 7.0+ required!", Toast.LENGTH_SHORT).show()
            return false
        }
        return true
    }

    private fun triggerCompile (action: String) {
        if (CompileService.compiling) {
            Toast.makeText(context, "A background compile is already running; cannot start another.", Toast.LENGTH_SHORT).show()
        } else {
            try {
                val service = Intent(context, CompileService::class.java)
                service.action = action
                context.startService(service)
                Toast.makeText(context, "Background compile started. Check notifications for progress.", Toast.LENGTH_SHORT).show()
            } catch (ex: java.lang.Exception) {
                Toast.makeText(context, "Failed to start background process", Toast.LENGTH_SHORT).show()
            }
        }
    }

    //增加进度显示，而且不再出现因为编译应用自身而退出
    private fun run2() {
        if (!isSupport()) {
            return
        }

        if (CompileService.compiling) {
            Toast.makeText(context, "A background compile is already running.", Toast.LENGTH_SHORT).show()
            return
        }

        val view = context.layoutInflater.inflate(R.layout.dialog_addin_compile, null)
        val dialog = DialogHelper.customDialog(context, view)
        view.findViewById<View>(R.id.mode_speed_profile).setOnClickListener {
            dialog.dismiss()
            triggerCompile(context.getString(R.string.scene_speed_profile_compile))
        }
        view.findViewById<View>(R.id.mode_speed).setOnClickListener {
            dialog.dismiss()
            triggerCompile(context.getString(R.string.scene_speed_compile))
        }
        view.findViewById<View>(R.id.mode_everything).setOnClickListener {
            dialog.dismiss()
            triggerCompile(context.getString(R.string.scene_everything_compile))
        }
        view.findViewById<View>(R.id.mode_reset).setOnClickListener {
            dialog.dismiss()
            triggerCompile(context.getString(R.string.scene_reset_compile))
        }
        view.findViewById<View>(R.id.faq).setOnClickListener {
            dialog.dismiss()
            Toast.makeText(context, "This page may require a VPN in mainland China.", Toast.LENGTH_LONG).show()

            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(context.getString(R.string.addin_dex2oat_helplink))))
        }
    }

    override fun run() {
        run2()
    }

    fun modifyConfigOld() {
        val arr = arrayOf(
                "verify",
                "speed",
                "Restore default")
        val intallMode = PropsUtils.getProp("dalvik.vm.dex2oat-filter")
        var index = 0
        when (intallMode) {
            "interpret-only" -> index = 0
            "speed" -> index = 1
        }
        DialogHelper.animDialog(AlertDialog.Builder(context)
                .setTitle("Select Dex2oat config")
                .setSingleChoiceItems(arr, index) { _, which ->
                    index = which
                }
                .setNegativeButton("OK") { _, _ ->
                    val stringBuilder = StringBuilder()

                    //移除已添加的配置
                    stringBuilder.append("sed '/^dalvik.vm.image-dex2oat-filter=/'d /system/build.prop > /data/build.prop;")
                    stringBuilder.append("sed -i '/^dalvik.vm.dex2oat-filter=/'d /data/build.prop;")

                    when (index) {
                        0 -> {
                            stringBuilder.append("sed -i '\$adalvik.vm.image-dex2oat-filter=interpret-only' /data/build.prop;")
                            stringBuilder.append("sed -i '\$adalvik.vm.dex2oat-filter=interpret-only' /data/build.prop;")
                        }
                        1 -> {
                            stringBuilder.append("sed -i '\$adalvik.vm.image-dex2oat-filter=speed' /data/build.prop;")
                            stringBuilder.append("sed -i '\$adalvik.vm.dex2oat-filter=speed' /data/build.prop;")
                        }
                    }

                    stringBuilder.append(CommonCmds.MountSystemRW)
                    stringBuilder.append("cp /system/build.prop /system/build.prop.${System.currentTimeMillis()}\n")
                    stringBuilder.append("cp /data/build.prop /system/build.prop\n")
                    stringBuilder.append("rm /data/build.prop\n")
                    stringBuilder.append("chmod 0755 /system/build.prop\n")

                    execShell(stringBuilder)
                    Toast.makeText(context, "Config updated; reboot required to take effect.", Toast.LENGTH_SHORT).show()
                }
                .setNeutralButton("View details") { _, _ ->
                    DialogHelper.animDialog(AlertDialog.Builder(context).setTitle("Info").setMessage("interpret-only installs faster. speed installs slower but runs faster."))
                })
    }

    fun modifyConfig() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            modifyConfigOld()
            return
        }

        val arr = arrayOf(
                "No compile (faster install)",
                "Compile (faster runtime)",
                "Restore default")
        val intallMode = PropsUtils.getProp("pm.dexopt.install")
        var index = 0
        when (intallMode) {
            "extract",
            "quicken",
            "interpret-only",
            "verify-none" -> index = 0
            "speed" -> index = 1
            "everything" -> index = 1
            else -> {
                if (PropsUtils.getProp("pm.dexopt.core-app") == "verify-none") {
                    index = 3
                } else
                    index = 0
            }
        }
        DialogHelper.animDialog(AlertDialog.Builder(context)

                .setSingleChoiceItems(arr, index) { _, which ->
                    index = which
                }
                .setNegativeButton("OK") { _, _ ->
                    val stringBuilder = StringBuilder()

                    //移除已添加的配置
                    stringBuilder.append("cp /system/build.prop /data/build.prop;")
                    //stringBuilder.append("sed -i '/^pm.dexopt.ab-ota=/'d /data/build.prop;")
                    stringBuilder.append("sed -i '/^pm.dexopt.bg-dexopt=/'d /data/build.prop;")
                    //stringBuilder.append("sed -i '/^pm.dexopt.boot=/'d /data/build.prop;")
                    stringBuilder.append("sed -i '/^pm.dexopt.core-app=/'d /data/build.prop;")
                    //stringBuilder.append("sed -i '/^pm.dexopt.first-boot=/'d /data/build.prop;")
                    stringBuilder.append("sed -i '/^pm.dexopt.forced-dexopt=/'d /data/build.prop;")
                    stringBuilder.append("sed -i '/^pm.dexopt.install=/'d /data/build.prop;")
                    stringBuilder.append("sed -i '/^pm.dexopt.nsys-library=/'d /data/build.prop;")
                    stringBuilder.append("sed -i '/^pm.dexopt.shared-apk=/'d /data/build.prop;")
                    stringBuilder.append("sed -i '/^dalvik.vm.image-dex2oat-filter=/'d /data/build.prop;")
                    stringBuilder.append("sed -i '/^dalvik.vm.dex2oat-filter=/'d /data/build.prop;")

                    when (index) {
                        0 -> {
                            stringBuilder.append("sed -i '\$apm.dexopt.bg-dexopt=speed' /data/build.prop;")
                            stringBuilder.append("sed -i '\$apm.dexopt.core-app=speed' /data/build.prop;")
                            stringBuilder.append("sed -i '\$apm.dexopt.forced-dexopt=speed' /data/build.prop;")
                            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                                stringBuilder.append("sed -i '\$apm.dexopt.install=interpret-only' /data/build.prop;")
                            } else {
                                stringBuilder.append("sed -i '\$apm.dexopt.install=quicken' /data/build.prop;")
                            }
                            stringBuilder.append("sed -i '\$apm.dexopt.nsys-library=speed' /data/build.prop;")
                            stringBuilder.append("sed -i '\$apm.dexopt.shared-apk=speed' /data/build.prop;")
                            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
                                stringBuilder.append("sed -i '\$adalvik.vm.image-dex2oat-filter=speed' /data/build.prop;")
                                stringBuilder.append("sed -i '\$adalvik.vm.dex2oat-filter=speed' /data/build.prop;")
                            }
                        }
                        1 -> {
                            stringBuilder.append("sed -i '\$apm.dexopt.bg-dexopt=speed' /data/build.prop;")
                            stringBuilder.append("sed -i '\$apm.dexopt.core-app=speed' /data/build.prop;")
                            stringBuilder.append("sed -i '\$apm.dexopt.forced-dexopt=speed' /data/build.prop;")
                            stringBuilder.append("sed -i '\$apm.dexopt.install=speed' /data/build.prop;")
                            stringBuilder.append("sed -i '\$apm.dexopt.nsys-library=speed' /data/build.prop;")
                            stringBuilder.append("sed -i '\$apm.dexopt.shared-apk=speed' /data/build.prop;")
                            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
                                stringBuilder.append("sed -i '\$adalvik.vm.image-dex2oat-filter=speed' /data/build.prop;")
                                stringBuilder.append("sed -i '\$adalvik.vm.dex2oat-filter=speed' /data/build.prop;")
                            }
                        }
                    }

                    stringBuilder.append(CommonCmds.MountSystemRW)
                    stringBuilder.append("cp /system/build.prop /system/build.prop.${System.currentTimeMillis()}\n")
                    stringBuilder.append("cp /data/build.prop /system/build.prop\n")
                    stringBuilder.append("rm /data/build.prop\n")
                    stringBuilder.append("chmod 0755 /system/build.prop\n")

                    execShell(stringBuilder)
                    Toast.makeText(context, "Config updated; reboot required to take effect.", Toast.LENGTH_SHORT).show()
                }
                .setNeutralButton("View details") { _, _ ->
                    DialogHelper.animDialog(AlertDialog.Builder(context)
                            .setTitle("Info")
                            .setMessage(R.string.addin_dexopt_helpinfo)
                            .setNegativeButton("Learn more") { _, _ ->
                                context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(context.getString(R.string.addin_dex2oat_helplink))))
                            })
                })
    }
}
