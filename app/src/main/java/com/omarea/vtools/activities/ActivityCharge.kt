package com.omarea.vtools.activities

import android.content.Intent
import android.os.BatteryManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.SpannableString
import android.text.Spanned
import android.text.style.AbsoluteSizeSpan
import android.view.View
import com.omarea.data.GlobalStatus
import com.omarea.library.device.BatteryCapacity
import com.omarea.library.shell.BatteryUtils
import com.omarea.store.ChargeSpeedStore
import com.omarea.vtools.R
import com.omarea.vtools.dialogs.DialogElectricityUnit
import com.omarea.vtools.databinding.ActivityChargeBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import java.util.*

class ActivityCharge : ActivityBase() {
    private lateinit var storage: ChargeSpeedStore
    private var timer: Timer? = null
    private lateinit var binding: ActivityChargeBinding
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityChargeBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setBackArrow()

        storage = ChargeSpeedStore(this)
        binding.electricityAdjUnit.setOnClickListener {
            DialogElectricityUnit().showDialog(this)
        }
        binding.moreBatteryStats.setOnClickListener {
            val intent = Intent(context, ActivityPowerUtilization::class.java)
            startActivity(intent)
        }
        GlobalScope.launch(Dispatchers.Main) {
            if (BatteryUtils().qcSettingSupport() || batteryUtils.bpSettingSupport()) {
                binding.chargeController.visibility = View.VISIBLE
                binding.chargeController.setOnClickListener {
                    val intent = Intent(context, ActivityChargeController::class.java)
                    startActivity(intent)
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        title = getString(R.string.menu_charge)
        timer = Timer().apply {
            schedule(object : TimerTask() {
                override fun run() {
                    updateUI()
                }
            }, 0, 2000)
        }
    }

    override fun onPause() {
        timer?.cancel()
        timer = null
        super.onPause()
    }

    private val sumInfo: String
        get() {
            val sum = storage.sum
            return getString(R.string.battery_status_sum).format((if (sum > 0) ("" + sum) else (sum.toString())))
        }

    private var batteryUtils = BatteryUtils()
    private val hander = Handler(Looper.getMainLooper())
    private fun updateUI() {
        val level = GlobalStatus.batteryCapacity
        val temp = GlobalStatus.updateBatteryTemperature()
        val kernelCapacity = batteryUtils.getKernelCapacity(level)
        val batteryMAH = BatteryCapacity().getBatteryCapacity(this).toInt().toString() + "mAh" + "   "
        val voltage = GlobalStatus.batteryVoltage
        hander.post {
            binding.viewSpeed.invalidate()
            binding.viewTime.invalidate()
            binding.viewTemperature.invalidate()

            binding.chargeState.text = (when (GlobalStatus.batteryStatus) {
                BatteryManager.BATTERY_STATUS_DISCHARGING -> {
                    getString(R.string.battery_status_discharging)
                }
                BatteryManager.BATTERY_STATUS_CHARGING -> {
                    getString(R.string.battery_status_charging)
                }
                BatteryManager.BATTERY_STATUS_FULL -> {
                    getString(R.string.battery_status_full)
                }
                BatteryManager.BATTERY_STATUS_UNKNOWN -> {
                    getString(R.string.battery_status_unknown)
                }
                BatteryManager.BATTERY_STATUS_NOT_CHARGING -> {
                    getString(R.string.battery_status_not_charging)
                }
                else -> getString(R.string.battery_status_unknown)
            }) + sumInfo

            if (kernelCapacity > -1) {
                val str = "$kernelCapacity%"
                val ss = SpannableString(str)
                if (str.contains(".")) {
                    val small = AbsoluteSizeSpan((binding.battrystatusLevel.textSize * 0.3).toInt(), false)
                    ss.setSpan(small, str.indexOf("."), str.lastIndexOf("%"), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                    val medium = AbsoluteSizeSpan((binding.battrystatusLevel.textSize * 0.5).toInt(), false)
                    ss.setSpan(medium, str.indexOf("%"), str.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                }
                binding.battrystatusLevel.text = ss
            } else {
                binding.battrystatusLevel.text = "" + level + "%"
            }

            binding.batterySize.text = batteryMAH
            binding.batteryStatus.text =
                    getString(R.string.battery_temperature) + temp + "°C\n" +
                    getString(R.string.battery_voltage) + voltage + "v\n" +
                    getString(R.string.battery_electricity) + (
                        (if (GlobalStatus.batteryCurrentNow > 0) {
                            "+"
                        } else {
                            ""
                        }) + GlobalStatus.batteryCurrentNow + "mA"
                    )
            binding.batteryCapacityChart.setData(100f, 100f - level, temp.toFloat())
        }
    }
}
