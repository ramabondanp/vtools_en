package com.omarea.vtools.activities

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import com.omarea.common.shared.FileWrite
import com.omarea.common.ui.DialogHelper
import com.omarea.vtools.R
import com.omarea.vtools.databinding.ActivityCustomCommandBinding
import java.io.File
import java.net.URLEncoder
import java.nio.charset.Charset

class ActivityCustomCommand : ActivityBase() {
    private lateinit var binding: ActivityCustomCommandBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityCustomCommandBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setBackArrow()

        binding.btnRun.setOnClickListener {
            runCommand()
        }

        binding.btnConfirm.setOnClickListener {
            val title = binding.commandTitle.text?.toString()
            val script = binding.commandScript.text?.toString()
            if (title.isNullOrEmpty()) {
                Toast.makeText(this, "Please enter a title first!", Toast.LENGTH_SHORT).show()
            } else if (script.isNullOrEmpty()) {
                Toast.makeText(this, "Script content cannot be empty!", Toast.LENGTH_SHORT).show()
            } else {
                saveCommand(title, script)
            }
        }
    }

    private fun runCommand() {
        Toast.makeText(this, "This feature is not implemented yet!", Toast.LENGTH_SHORT).show()
    }

    private fun saveCommand(title: String, script: String, replace: Boolean = false) {
        val fileContent = script.replace(Regex("\r\n"), "\n").replace(Regex("\r\t"), "\t").toByteArray(Charset.defaultCharset())
        val fileName = "custom-command/" + URLEncoder.encode(title) + ".sh"
        val fullPath = FileWrite.getPrivateFilePath(context, fileName)

        if (File(fullPath).exists() && !replace) {
            val current = File(fullPath).readText(Charset.defaultCharset())
            DialogHelper.confirmBlur(this, "Overwrite existing command with the same name?", "A command with the same name already exists, content:\n" + current, {
                saveCommand(title, script, true)
            })
        } else {
            if (FileWrite.writePrivateFile(fileContent, fileName, this)) {
                setResult(RESULT_OK, Intent().apply {
                    putExtra("path", fullPath)
                })
                finish()
                Toast.makeText(this, "Added successfully!", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this, "Save failed!", Toast.LENGTH_SHORT).show()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        title = getString(R.string.menu_custom_command)
    }

    override fun onPause() {
        super.onPause()
    }
}
