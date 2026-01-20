package com.omarea.vtools.popup

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.pm.ActivityInfo
import android.graphics.PixelFormat
import android.os.Build
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import com.omarea.utils.WindowCompatHelper
import com.omarea.vtools.R

class FloatLogView(mContext: Context) {
    private var view: View = LayoutInflater.from(mContext).inflate(R.layout.fw_logview, null)
    private var logView: TextView = view.findViewById(R.id.fw_logs)

    private var params: WindowManager.LayoutParams = WindowManager.LayoutParams().apply {
        height = WindowManager.LayoutParams.MATCH_PARENT
        width = WindowManager.LayoutParams.MATCH_PARENT
        screenOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED

        // 类型
        if (mContext is AccessibilityService && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            type = WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
        } else {
            type = WindowCompatHelper.overlayWindowType()
        }

        format = PixelFormat.TRANSLUCENT
        x = 0
        y = 0

        flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
    }

    private var show: Boolean = false
    private val wm = mContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    public fun hide() {
        if (show) {
            wm.removeView(view)
            show = false
        }
    }

    public fun update(logs: String) {
        if (!show) {
            wm.addView(view, params)
            show = true
        }
        logView.post {
            logView.text = logs
        }
    }
}
