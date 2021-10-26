package com.omarea.scene_mode

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.widget.Toast
import com.omarea.vtools.popup.FloatPowercfgSelector

class ReceiverSceneMode : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.extras != null) {
            val parameterValue = intent.getStringExtra("packageName");
            if (parameterValue == null || parameterValue.isEmpty()) {
                return
            }
            if (Build.VERSION.SDK_INT >= 23 && !Settings.canDrawOverlays(context)) {
                //若没有权限，提示获取
                //val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION);
                //startActivity(intent);
                val overlayPermission = Intent().addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                overlayPermission.action = "android.settings.APPLICATION_DETAILS_SETTINGS"
                overlayPermission.data = Uri.fromParts("package", context.packageName, null)
                Toast.makeText(context, "Authorize Display Over Other Apps permission for Scene to quickly switch modes in the app!", Toast.LENGTH_SHORT).show();
            } else {
                FloatPowercfgSelector(context.applicationContext).open(parameterValue)
            }
        }
    }
}
