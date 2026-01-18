package com.omarea.vtools.activities

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.omarea.scene_mode.ModeSwitcher
import com.omarea.vtools.popup.FloatPowercfgSelector

class ActivityPowerModeTile : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (ModeSwitcher().modeConfigCompleted()) {
            if (Build.VERSION.SDK_INT >= 23 && !Settings.canDrawOverlays(this)) {
                //若没有权限，提示获取
                //val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION);
                //startActivity(intent);
                val overlayPermission = Intent().addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                overlayPermission.action = "android.settings.APPLICATION_DETAILS_SETTINGS"
                overlayPermission.data = Uri.fromParts("package", this.packageName, null)
                Toast.makeText(this, "Grant Scene overlay permission to switch modes quickly in apps.", Toast.LENGTH_SHORT).show();
            } else {
                FloatPowercfgSelector(this.applicationContext).open(this.packageName)
            }

        } else {
            Toast.makeText(this, "Performance config is incomplete; quick switch is unavailable.", Toast.LENGTH_SHORT).show();
        }
        finish()
    }
}
