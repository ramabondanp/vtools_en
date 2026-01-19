package com.omarea.scene_mode

import android.app.Service
import android.content.Intent
import android.os.IBinder
import com.omarea.store.TriggerStorage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class TriggerExecutorService : Service() {
    private val serviceJob = SupervisorJob()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        serviceScope.launch {
            handleIntent(intent)
            stopSelfResult(startId)
        }
        return START_NOT_STICKY
    }

    private fun handleIntent(intent: Intent?) {
        intent?.run {
            if (intent.hasExtra("triggers")) {
                executeTriggers(intent.getStringArrayListExtra("triggers")!!)
            }
        }
    }

    override fun onDestroy() {
        serviceScope.cancel()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun executeTriggers(triggers: ArrayList<String>) {
        val context = this;
        val storage = TriggerStorage(this)
        triggers.forEach {
            storage.load(it)?.run {
                TaskActionsExecutor(taskActions, customTaskActions, context).run()
            }
        }
    }
}
