@file:OptIn(kotlinx.coroutines.DelicateCoroutinesApi::class)

package com.omarea.vtools.activities

import android.annotation.SuppressLint
import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.text.Spannable
import android.text.SpannableString
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import android.view.View
import android.webkit.*
import androidx.recyclerview.widget.LinearLayoutManager
import com.omarea.common.ui.DialogHelper
import com.omarea.library.basic.AppInfoLoader
import com.omarea.library.shell.PlatformUtils
import com.omarea.store.FpsWatchStore
import com.omarea.ui.fps.AdapterSessions
import com.omarea.ui.fps.FpsDataView
import com.omarea.vtools.R
import com.omarea.vtools.popup.FloatFpsWatch
import com.omarea.vtools.databinding.ActivityFpsChartBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat

class ActivityFpsChart : ActivityBase(), AdapterSessions.OnItemClickListener {
    private lateinit var fpsWatchStore: FpsWatchStore
    private lateinit var binding: ActivityFpsChartBinding
    override fun onPostResume() {
        super.onPostResume()
        delegate.onPostResume()
        setTitle(R.string.menu_fps_chart)
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityFpsChartBinding.inflate(layoutInflater)
        setContentView(binding.root)
        setBackArrow()

        fpsWatchStore = FpsWatchStore(this)

        /*
        @Suppress("DEPRECATION")
        window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)
        window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
        window.statusBarColor = Color.WHITE
        window.navigationBarColor = Color.WHITE
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR or View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
        } else if (Build.VERSION.SDK_INT >= 23) {
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
        }
        */

        binding.chartPlatform.text = PlatformUtils().getCPUName()
        binding.chartPhone.text = Build.MODEL
        binding.chartOs.text = when (Build.VERSION.SDK_INT) {
            31 -> "Android 12"
            30 -> "Android 11"
            29 -> "Android 10"
            28 -> "Android 9"
            27 -> "Android 8.1"
            26 -> "Android 8.0"
            25 -> "Android 7.0"
            24 -> "Android 7.0"
            23 -> "Android 6.0"
            22 -> "Android 5.1"
            21 -> "Android 5.0"
            else -> "SDK(" + Build.VERSION.SDK_INT + ")"
        }

        val linearLayoutManager = LinearLayoutManager(context, LinearLayoutManager.VERTICAL, false)
        binding.chartSessions.layoutManager = linearLayoutManager
        val appInfoLoader = AppInfoLoader(context)
        GlobalScope.launch(Dispatchers.Main) {
            val sessions = fpsWatchStore.sessions()
            sessions.forEach {
                val appInfo = appInfoLoader.loadAppBasicInfo(it.packageName).await()
                it.appName = appInfo.appName
                it.appIcon = appInfo.icon
            }
            if (sessions.size > 0) {
                binding.chartSessionDetail.visibility = View.VISIBLE
                binding.chartSessionsEmpty.visibility = View.GONE
                binding.chartSessions.adapter = AdapterSessions(context, sessions).apply {
                    setOnItemClickListener(this@ActivityFpsChart)
                    setOnItemDeleteClickListener(object : AdapterSessions.OnItemClickListener {
                        override fun onItemClick(position: Int) {
                            onSessionDeleteClick(position)
                        }
                    })
                }
                onItemClick(sessions.size - 1)
            } else {
                binding.chartSessionDetail.visibility = View.GONE
                binding.chartSessionsEmpty.visibility = View.VISIBLE
            }
        }

        binding.chartAdd.setOnClickListener {
            if (FloatFpsWatch.show != true) {
                it.rotation = 45f
                FloatFpsWatch(context).showPopupWindow()
                DialogHelper.helpInfo(this@ActivityFpsChart, "Please enter the app that needs to record the frame rate, and click the small [green] button at the top right of the screen to start recording the frame rate!")
                /*
                val serviceState = AccessibleServiceHelper().serviceRunning(context)
                if (serviceState) {
                    FloatFpsWatch(context).showPopupWindow()
                } else {
                }
                */
            } else {
                it.rotation = 0f
                FloatFpsWatch(context).hidePopupWindow()
            }
        }

        val chart_right_click = object : View.OnClickListener {
            override fun onClick(v: View?) {
                val values = FpsDataView.DIMENSION.values()
                val count = values.size
                val nextIndex = (values.indexOf(binding.chartSession.getRightDimension()) + 1) % count
                binding.chartSession.setRightDimension(values.get(nextIndex))
                binding.chartRight.text = when (binding.chartSession.getRightDimension()) {
                    FpsDataView.DIMENSION.TEMPERATURE -> "Temperature(°C)"
                    FpsDataView.DIMENSION.CAPACITY -> "Battery(%)"
                    FpsDataView.DIMENSION.LOAD -> {
                        val colorSpanGpu = ForegroundColorSpan(Color.parseColor("#8087d3ff"))
                        val colorSpanCpu = ForegroundColorSpan(Color.parseColor("#80fc6bc5"))
                        val bold = StyleSpan(Typeface.BOLD)

                        SpannableString("CPU/GPU Load(%)").apply {
                            setSpan(colorSpanCpu, 0, 3, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
                            setSpan(bold, 0, 3, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
                            setSpan(colorSpanGpu, 4, 8, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
                            setSpan(bold, 4, 8, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
                        }
                    }
                }
            }
        }
        // 切换右侧坐标轴数据
        binding.chartRight.setOnClickListener(chart_right_click)
        binding.chartRightIcon.setOnClickListener(chart_right_click)
    }

    // 删除会话
    private fun onSessionDeleteClick(position: Int) {
        val adapter = (binding.chartSessions.adapter as AdapterSessions)
        val item = adapter.getItem(position)

        fpsWatchStore.deleteSession(item.sessionId)
        adapter.removeItem(position)
    }

    override fun onDestroy() {
        super.onDestroy()
    }

    public override fun onPause() {
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        binding.chartAdd.rotation = if (FloatFpsWatch.show == true) 45f else 0f
    }

    override fun onItemClick(position: Int) {
        val item = (binding.chartSessions.adapter as AdapterSessions).getItem(position)
        val sessionId = item.sessionId
        val fpsData = fpsWatchStore.sessionFpsData(sessionId)
        val tData  = fpsWatchStore.sessionTemperatureData(sessionId)
        val smoothRatio = fpsData.filter { it >= 45 }.size * 100.0 / fpsData.size
        val feverRatio = tData.filter { it > 46 }.size * 100.0 / tData.size

        binding.chartFpsMax.text = String.format("%.1f", fpsWatchStore.sessionMaxFps(sessionId))
        binding.chartFpsMin.text = String.format("%.1f", fpsWatchStore.sessionMinFps(sessionId))
        binding.chartFpsAvg.text = String.format("%.1f", fpsWatchStore.sessionAvgFps(sessionId))
        binding.chartSmoothRatio.text = String.format("%.1f%%", smoothRatio)
        binding.chartFeverRatio.text = String.format("%.1f%%", feverRatio)
        binding.chartTempMax.text = String.format("%.1f", tData.maxOrNull())
        binding.chartSessionName.text = item.appName
        binding.chartSessionTime.text = SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(item.beginTime)
        binding.chartSession.setSessionId(sessionId)
    }
}
