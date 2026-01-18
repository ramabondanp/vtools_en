package com.omarea.store

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import android.widget.Toast
import com.omarea.vaddin.IAppConfigAidlInterface
import org.json.JSONObject

public class XposedExtension(private val context: Context) {

    open class AppConfig(val packageName: String) {
        public var dpi = -1
        public var excludeRecent = false
        public var smoothScroll = false
        public var webDebug = false
    }

    open class GlobalConfig {
        public var hideSuIcon = false
        public var fgNotificationDisable = false
        public var reverseOptimizer = false
        public var androidScroll = false
    }

    private var aidlConn: IAppConfigAidlInterface? = null

    public val current: IAppConfigAidlInterface?
        get() {
            return aidlConn
        }

    private lateinit var conn:ServiceConnection

    public fun bindService(onCompleted: Runnable):Boolean {
        try {
            if (context.packageManager?.getPackageInfo("com.omarea.vaddin", 0) == null) {
                return false
            }
        } catch (ex: Exception) {
            Toast.makeText(this.context, "The \"Scene - Advanced Settings\" plugin is not installed!", Toast.LENGTH_LONG).show()
            return false
        }

        if (aidlConn != null) {
            onCompleted.run()
            return true
        }

        try {
            conn = object : ServiceConnection {
                override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
                    aidlConn = IAppConfigAidlInterface.Stub.asInterface(service)

                    onCompleted.run()
                }
                override fun onServiceDisconnected(name: ComponentName?) {
                    aidlConn = null
                }
            }

            val intent = Intent()
            //绑定服务端的service
            intent.action = "com.omarea.vaddin.ConfigUpdateService"
            //新版本（5.0后）必须显式intent启动 绑定服务
            intent.setComponent(ComponentName("com.omarea.vaddin", "com.omarea.vaddin.ConfigUpdateService"))
            //绑定的时候服务端自动创建
            if (!context.bindService(intent, conn, Context.BIND_AUTO_CREATE)) {
                throw Exception("")
            }

            return true
        } catch (ex: Exception) {
            Toast.makeText(this.context, "Failed to connect to the \"Scene - Advanced Settings\" plugin. Please do not block it from auto-starting!", Toast.LENGTH_LONG).show()
        }
        return false
    }

    public fun unbindService() {
        try {
            if (aidlConn != null) {
                context.unbindService(conn)
                aidlConn = null
            }
        } catch (ex: java.lang.Exception) {
        }
    }


    // 获取某个应用的xposed配置
    public fun getAppConfig(packageName: String): AppConfig? {
        return getAppConfig(AppConfig(packageName))
    }

    public fun getAppConfig(appConfig: AppConfig): AppConfig? {
        try {
            val configJson = current!!.getStringValue(appConfig.packageName, "{}") as String
            val config = JSONObject(configJson)
            for (key in config.keys()) {
                when (key) {
                    "dpi" -> {
                        appConfig.dpi = config.getInt(key)
                    }
                    "excludeRecent" -> {
                        appConfig.excludeRecent = config.getBoolean(key)
                    }
                    "smoothScroll" -> {
                        appConfig.smoothScroll = config.getBoolean(key)
                    }
                    "webDebug" -> {
                        appConfig.webDebug = config.getBoolean(key)
                    }
                }
            }
            return appConfig
        } catch (ex: Exception) {
        }

        return null
    }

    public fun setAppConfig(appConfig: AppConfig): Boolean {
        if (current != null) {
            try {
                val config = JSONObject().apply {
                    put("dpi", appConfig.dpi)
                    put("excludeRecent", appConfig.excludeRecent)
                    put("smoothScroll", appConfig.smoothScroll)
                    put("webDebug", appConfig.webDebug)
                }.toString(0)
                return current?.setStringValue(appConfig.packageName, config) == true
            } catch (ex: java.lang.Exception) {
            }
        }
        return false
    }

    public fun getGlobalConfig(): GlobalConfig? {
        if (current != null) {
            try {
                val config = GlobalConfig()
                config.hideSuIcon = current?.getBooleanValue("com.android.systemui_hide_su", false) == true
                config.fgNotificationDisable = current?.getBooleanValue("android_dis_service_foreground", false) == true
                config.reverseOptimizer = current?.getBooleanValue("reverse_optimizer", false) == true
                config.androidScroll = current?.getBooleanValue("android_scroll", false) == true
                return config
            } catch (ex: java.lang.Exception) {
            }
        }
        return null
    }

    public fun setGlobalConfig(globalConfig: GlobalConfig): Boolean {
        if (current != null) {
            try {
                aidlConn!!.setBooleanValue("com.android.systemui_hide_su", globalConfig.hideSuIcon)
                aidlConn!!.setBooleanValue("android_dis_service_foreground", globalConfig.fgNotificationDisable)
                aidlConn!!.setBooleanValue("reverse_optimizer", globalConfig.reverseOptimizer)
                aidlConn!!.setBooleanValue("android_scroll", globalConfig.androidScroll)
                return true
            } catch (ex: java.lang.Exception) {
            }
        }
        return false
    }
}
