package com.omarea.vtools

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.omarea.Scene


class ReceiverCompileState : BroadcastReceiver() {
    companion object {
        private var channelCreated = false
        private lateinit var nm: NotificationManager
    }

    init {
        nm = Scene.context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }

    private fun updateNotification(title: String, text: String, total: Int, current: Int, autoCancel: Boolean = true) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !channelCreated) {
            nm.createNotificationChannel(NotificationChannel("vtool-compile", "Background compile", NotificationManager.IMPORTANCE_LOW))
            channelCreated = true
        }
        val builder = NotificationCompat.Builder(Scene.context, "vtool-compile")

        nm.notify(990, builder
                .setSmallIcon(R.drawable.process)
                .setContentTitle(title)
                .setContentText(text)
                .setAutoCancel(autoCancel)
                .setProgress(total, current, false)
                .build())
    }

    override fun onReceive(context: Context, intent: Intent) {
        try {
            intent.extras?.run {
                val current = getInt("current")
                val total = getInt("total")
                val packageName = getString("packageName")!!
                if (total == current) {
                    updateNotification("complete!", context.getString(R.string.dex2oat_completed), 100, 100, true)
                } else {
                    updateNotification(context.getString(R.string.dex2oat_reset_running), packageName, total, current)
                }
            }
        } catch (ex: Exception) {
        }
    }
}
