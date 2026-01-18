package com.omarea.vtools

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.omarea.vtools.workers.BootWorker


class ReceiverBoot : BroadcastReceiver() {
    companion object {
        var bootCompleted: Boolean = false
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (bootCompleted) {
            return
        }
        bootCompleted = true

        try {
            val request = OneTimeWorkRequestBuilder<BootWorker>().build()
            WorkManager.getInstance(context).enqueueUniqueWork("boot-worker", ExistingWorkPolicy.KEEP, request)
        } catch (ex: Exception) {
        }
    }
}
