package com.omarea.vtools.popup

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.pm.ActivityInfo
import android.graphics.PixelFormat
import android.os.Build
import android.view.View
import android.view.WindowManager
import com.omarea.Scene
import com.omarea.model.SceneConfigInfo
import com.omarea.utils.WindowCompatHelper

class FloatScreenRotation(mContext: Context) {
    private var view: View = View(mContext)

    private var params: WindowManager.LayoutParams = WindowManager.LayoutParams().apply {
        height = 0
        width = 0
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

    public fun update(config: SceneConfigInfo) {
        val screenOrientation = config.screenOrientation

        if (screenOrientation == params.screenOrientation) {
            return
        }

        params.screenOrientation = screenOrientation
        Scene.post {
            if (screenOrientation == ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED) {
                // Log.d(">>>>", "恢复" + screenOrientation)
                if (show) {
                    wm.removeViewImmediate(view)
                    show = false
                }
            } else {
                // Log.d(">>>>", "旋转" + screenOrientation)
                if (show) {
                    wm.updateViewLayout(view, params)
                } else {
                    wm.addView(view, params)
                    show = true
                }
            }
        }
    }

    public fun remove() {
        if (show) {
            wm.removeViewImmediate(view)
        }
        this.show = false;
        params.screenOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
    }
}
