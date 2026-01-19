package com.omarea.vtools.activities

import android.os.Bundle
import com.omarea.vtools.R
import com.omarea.vtools.databinding.ActivitySystemSceneBinding
import com.omarea.vtools.fragments.FragmentSystemSceneMain
import com.omarea.vtools.fragments.FragmentSystemSceneSettings
import com.omarea.ui.TabIconHelper2

class ActivitySystemScene : ActivityBase() {
    private lateinit var binding: ActivitySystemSceneBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySystemSceneBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setBackArrow()
        onViewCreated()
    }

    override fun onResume() {
        super.onResume()
        title = getString(R.string.menu_system_scene)
    }

    private fun onViewCreated() {
        val tabIconHelper = TabIconHelper2(binding.systemSceneTabs, binding.systemScenePager, this)
        tabIconHelper.newTabSpec("System scenes", getDrawable(R.drawable.tab_security)!!, FragmentSystemSceneMain())
        tabIconHelper.newTabSpec("Settings", getDrawable(R.drawable.tab_settings)!!, FragmentSystemSceneSettings())
        binding.systemScenePager.offscreenPageLimit = 1
    }
}
