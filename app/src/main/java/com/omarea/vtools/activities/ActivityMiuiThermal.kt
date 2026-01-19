package com.omarea.vtools.activities

import android.annotation.SuppressLint
import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.CompoundButton
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import com.omarea.common.shell.KeepShellPublic
import com.omarea.common.shell.KernelProrp
import com.omarea.common.shell.RootFile
import com.omarea.common.ui.DialogHelper
import com.omarea.library.device.MiuiThermalAESUtil
import com.omarea.vtools.R
import com.omarea.vtools.databinding.ActivityMiuiThermalBinding
import java.io.File
import java.nio.charset.Charset

class ActivityMiuiThermal : ActivityBase() {
    private var currentFile = ""
    private var encrypted = true
    private lateinit var binding: ActivityMiuiThermalBinding
    private val configPickerLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        val data = result.data
        if (result.resultCode == Activity.RESULT_OK && data?.extras != null) {
            val fileName = data.extras!!.getString("file")
            if (!fileName!!.startsWith("thermal")) {
                currentFile = fileName
                title = fileName

                try {
                    readConfig()
                    encrypted = true
                } catch (ex: Exception) {
                    val content = String(File(currentFile).readBytes(), Charset.forName("UTF-8")).trim()
                    binding.thermalConfig.setText(content)
                    encrypted = false
                    return@registerForActivityResult
                }
            } else {
                Toast.makeText(this, "This filename doesn't look like a thermal config file.", Toast.LENGTH_LONG).show()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMiuiThermalBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setBackArrow()
        onViewCreated()
    }

    private fun onViewCreated() {
    }

    override fun onResume() {
        super.onResume()
        title = getString(R.string.menu_miui_thermal)
    }


    private fun openDir() {
        val options = applicationContext.resources.getTextArray(R.array.start_dir_options)
        var currentIndex = 0
        DialogHelper.animDialog(
                AlertDialog.Builder(this)
                        .setTitle("Select config source directory")
                        .setSingleChoiceItems(options, currentIndex) { _, index ->
                            currentIndex = index
                        }.setPositiveButton("Browse selected directory") { _, _ ->
                            if (currentIndex > -1) {
                                val intent = Intent(this.applicationContext, ActivityFileSelector::class.java)
                                intent.putExtra("extension", "conf")
                                intent.putExtra("start", options.get(currentIndex))
                                configPickerLauncher.launch(intent)
                            }
                        })
    }

    private fun readConfig() {
        val file = File(currentFile)
        val output = MiuiThermalAESUtil.decrypt(file.readBytes())
        binding.thermalConfig.setText(String(output, Charset.forName("UTF-8")))
        setTitle(file.name)
    }

    @SuppressLint("RestrictedApi")
    private fun saveConfig() {
        val currentContent = binding.thermalConfig.text.toString().trim().replace(Regex("\r\n"), "\n").replace(Regex("\r\t"), "\t")
        val bytes = currentContent.toByteArray(Charset.forName("UTF-8"))
        val data = if (encrypted) MiuiThermalAESUtil.encrypt(bytes) else bytes
        val file_path = filesDir.path + File.separator + "thermal-temp.conf"
        File(file_path).writeBytes(data)
        // TODO:
        val result = KeepShellPublic.doCmdSync(
                "busybox mount -o rw,remount /\n" +
                        "busybox mount -o rw,remount /system\n" +
                        "mount -o rw,remount /system\n" +
                        "busybox mount -o remount,rw /dev/block/bootdevice/by-name/system /system\n" +
                        "mount -o remount,rw /dev/block/bootdevice/by-name/system /system\n" +
                        "busybox mount -o rw,remount /vendor\n" +
                        "mount -o rw,remount /vendor\n" +
                        "cp \"$file_path\" \"$currentFile\"\n" +
                        "chmod 664 \"$currentFile\""
        )
        File(file_path).delete()
        if (result == "error") {
            Toast.makeText(this, "Save failed. Check root permission and whether the file is locked.", Toast.LENGTH_LONG).show()
        } else {
            val output = (try {
                MiuiThermalAESUtil.decrypt(File(currentFile).readBytes())
            } catch (ex: Exception) {
                File(currentFile).readBytes()
            })
            val savedContent = String(output, Charset.forName("UTF-8"))
            if (savedContent.equals(currentContent)) {
                Toast.makeText(this, "Saved successfully.", Toast.LENGTH_LONG).show()
            } else {
                Toast.makeText(this, "Save failed. Check root permission and whether the file is locked.", Toast.LENGTH_LONG).show()
            }
        }
    }


    private fun applyThermal(saveConfig: Boolean) {
        val currentContent = binding.thermalConfig.text.toString().trim().replace(Regex("\r\n"), "\n").replace(Regex("\r\t"), "\t")
        val bytes = currentContent.toByteArray(Charset.forName("UTF-8"))
        val data = if (encrypted) MiuiThermalAESUtil.encrypt(bytes) else bytes
        val file_path = filesDir.path + File.separator + "thermal-temp.conf"
        val fileName = File(currentFile).name
        val outPath = "/data/vendor/thermal/config/$fileName"
        File(file_path).writeBytes(data)
        if (RootFile.dirExists("/data/vendor/thermal/config")) {
            // TODO:
            val result = KeepShellPublic.doCmdSync(
                    "cp \"$file_path\" \"$outPath\"\n" +
                            "chmod 664 \"$outPath\""
            )
            File(file_path).delete()
            if (result == "error") {
                Toast.makeText(this, "Failed to apply thermal config!", Toast.LENGTH_LONG).show()
            } else {
                val savedContent = KernelProrp.getProp("/data/vendor/thermal/decrypt.txt").trim()
                if (savedContent.equals(currentContent)) {
                    Toast.makeText(this, "Thermal config applied successfully.", Toast.LENGTH_LONG).show()
                } else if (!RootFile.fileExists(outPath)) {
                    Toast.makeText(this, "Failed to apply thermal config!", Toast.LENGTH_LONG).show()
                } else {
                    Toast.makeText(
                            this,
                            "Unable to confirm whether the thermal config applied. Check logs or verify with dump thermal-engine.",
                            Toast.LENGTH_LONG
                    ).show()
                }
            }
        } else {
            Toast.makeText(this, "System not supported or directory is corrupted; cannot apply thermal config.", Toast.LENGTH_LONG).show()
        }
        if (saveConfig) {
            saveConfig()
        }
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.menu_miui_thermal, menu)
        return true
    }


    private fun openUrl(link: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(link))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (ex: Exception) {
        }
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        val id = item.itemId

        return if (id == R.id.action_open) {
            openDir()
            true
        } else if (id == R.id.action_save) {
            if (currentFile.isNotEmpty()) {
                saveConfig()
            } else {
                Toast.makeText(this, "You haven't opened a file yet.", Toast.LENGTH_SHORT).show()
            }
            true
        } else if (id == R.id.action_apply) {
            if (currentFile.isNotEmpty()) {
                val view = layoutInflater.inflate(R.layout.dialog_apply_thermal, null)
                val dialog = DialogHelper.customDialog(this, view)
                view.findViewById<View>(R.id.btn_cancel).setOnClickListener {
                    dialog.dismiss()
                }
                view.findViewById<View>(R.id.btn_applay).setOnClickListener {
                    val saveConfig = view.findViewById<CompoundButton>(R.id.save_thermal).isChecked
                    dialog.dismiss()
                    this.applyThermal(saveConfig)
                }
            } else {
                Toast.makeText(this, "You haven't opened a file yet.", Toast.LENGTH_SHORT).show()
            }
            true
        } else if (id == R.id.action_hele) {
            openUrl("https://github.com/helloklf/vtools/blob/scene3/docs/MIUI%E6%B8%A9%E6%8E%A7%E8%AF%B4%E6%98%8E.md")
            true
        } else super.onOptionsItemSelected(item)
    }
}
