package com.omarea.vtools.activities

import android.os.Bundle
import android.widget.Toast
import com.omarea.common.shared.MagiskExtend
import com.omarea.common.ui.DialogHelper
import com.omarea.vtools.R
import com.omarea.vtools.databinding.ActivityMagiskBinding
import com.google.android.material.tabs.TabLayoutMediator
import androidx.viewpager2.adapter.FragmentStateAdapter
import com.omarea.vtools.fragments.FragmentMagiskAfterStart
import com.omarea.vtools.fragments.FragmentMagiskBeforeStart
import com.omarea.vtools.fragments.FragmentMagiskFiles
import com.omarea.vtools.fragments.FragmentMagiskProps


class ActivityMagisk : ActivityBase() {
    private lateinit var binding: ActivityMagiskBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMagiskBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setBackArrow()

        onViewCreated()
    }

    override fun onResume() {
        super.onResume()
        title = getString(R.string.menu_app_magisk)
    }

    fun onViewCreated() {
        if (MagiskExtend.magiskSupported()) {
            if (!MagiskExtend.moduleInstalled()) {
                DialogHelper.confirm(this, "Install Magisk extension?",
                        "Install Scene's Magisk extension module to change parameters without modifying system files.",
                        {
                            MagiskExtend.magiskModuleInstall(context)
                            Toast.makeText(context, "Operation completed.", Toast.LENGTH_LONG).show()
                            this@ActivityMagisk.recreate()
                        })
            }
        } else {
            Toast.makeText(context, "Magisk is not installed on this device; feature unavailable.", Toast.LENGTH_LONG).show()
            finish()
            return
        }

        val fragments = listOf(
                FragmentMagiskProps(),
                FragmentMagiskFiles(),
                FragmentMagiskBeforeStart(),
                FragmentMagiskAfterStart()
        )

        binding.magiskPager.adapter = object : FragmentStateAdapter(this) {
            override fun getItemCount(): Int = fragments.size

            override fun createFragment(position: Int) = fragments[position]
        }
        binding.magiskPager.offscreenPageLimit = fragments.size - 1

        val titles = listOf("Properties", "System files", "Before boot", "After boot")
        TabLayoutMediator(binding.magiskTabs, binding.magiskPager) { tab, position ->
            tab.text = titles[position]
        }.attach()
    }
}
