package com.omarea.utils

import android.graphics.Point
import android.os.Build
import android.view.WindowManager
import android.view.Window
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat

object WindowCompatHelper {
    fun getRealDisplaySize(windowManager: WindowManager): Point {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val bounds = windowManager.currentWindowMetrics.bounds
            Point(bounds.width(), bounds.height())
        } else {
            @Suppress("DEPRECATION")
            val display = windowManager.defaultDisplay
            val point = Point()
            @Suppress("DEPRECATION")
            display.getRealSize(point)
            point
        }
    }

    fun overlayWindowType(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
        }
    }

    fun applyEdgeToEdge(window: Window, lightStatusBars: Boolean, lightNavBars: Boolean) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        controller.isAppearanceLightStatusBars = lightStatusBars
        controller.isAppearanceLightNavigationBars = lightNavBars
    }

    fun setSystemBarColors(window: Window, statusBarColor: Int?, navigationBarColor: Int?) {
        if (statusBarColor != null) {
            @Suppress("DEPRECATION")
            window.statusBarColor = statusBarColor
        }
        if (navigationBarColor != null) {
            @Suppress("DEPRECATION")
            window.navigationBarColor = navigationBarColor
        }
    }
}
