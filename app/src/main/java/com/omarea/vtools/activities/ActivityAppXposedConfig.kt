package com.omarea.vtools.activities

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.AdapterView
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import com.omarea.Scene
import com.omarea.common.ui.OverScrollListView
import com.omarea.common.ui.ProgressBarDialog
import com.omarea.model.AppInfo
import com.omarea.model.SceneConfigInfo
import com.omarea.store.SpfConfig
import com.omarea.store.XposedExtension
import com.omarea.ui.XposedAppsAdapter
import com.omarea.utils.AppListHelper
import com.omarea.vtools.R
import com.omarea.vtools.databinding.ActivityAppXposedConfigBinding
import java.util.*
import kotlin.collections.ArrayList


class ActivityAppXposedConfig : ActivityBase() {
    private lateinit var processBarDialog: ProgressBarDialog
    private lateinit var globalSPF: SharedPreferences
    private lateinit var applistHelper: AppListHelper
    private var installedList: ArrayList<AppInfo>? = null
    private var displayList: ArrayList<AppInfo>? = null
    private lateinit var xposedExtension: XposedExtension
    private lateinit var binding: ActivityAppXposedConfigBinding
    private var lastClickRow: View? = null

    private val appConfigLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        val data = result.data
        if (result.resultCode == AppCompatActivity.RESULT_OK && data != null && displayList != null) {
            try {
                val adapter = (binding.sceneAppList.adapter as XposedAppsAdapter)
                var index = -1
                val packageName = data.extras!!.getString("app")
                for (i in 0 until displayList!!.size) {
                    if (displayList!![i].packageName == packageName) {
                        index = i
                    }
                }
                if (index < 0) {
                    return@registerForActivityResult
                }
                val item = adapter.getItem(index)
                setAppRowDesc(item)
                (binding.sceneAppList.adapter as XposedAppsAdapter?)?.run {
                    updateRow(index, lastClickRow!!)
                }
            } catch (ex: Exception) {
                Log.e("update-list", "" + ex.message)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAppXposedConfigBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setBackArrow()
        globalSPF = getSharedPreferences(SpfConfig.GLOBAL_SPF, Context.MODE_PRIVATE)
        xposedExtension = XposedExtension(this)

        this.onViewCreated()
    }

    private fun onViewCreated() {
        processBarDialog = ProgressBarDialog(this)
        applistHelper = AppListHelper(this)
        globalSPF = getSharedPreferences(SpfConfig.GLOBAL_SPF, Context.MODE_PRIVATE)

        binding.sceneAppList.setOnItemClickListener { parent, view2, position, _ ->
            try {
                val item = (parent.adapter.getItem(position) as AppInfo)
                val intent = Intent(this.context, ActivityAppXposedDetails::class.java)
                intent.putExtra("app", item.packageName)
                appConfigLauncher.launch(intent)
                lastClickRow = view2
            } catch (ex: Exception) {
            }
        }

        binding.configSearchBox.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_SEARCH || actionId == EditorInfo.IME_ACTION_DONE) {
                loadList()
                return@setOnEditorActionListener true
            }
            false
        }

        binding.configlistType.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onNothingSelected(parent: AdapterView<*>?) {
            }

            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, unusedId: Long) {
                loadList()
            }
        }

    }

    private fun sortAppList(list: ArrayList<AppInfo>): ArrayList<AppInfo> {
        list.sortWith { l, r ->
            try {
                val les = l.stateTags.toString()
                val res = r.stateTags.toString()
                when {
                    les < res -> -1
                    les > res -> 1
                    else -> {
                        val lp = l.packageName.toString()
                        val rp = r.packageName.toString()
                        when {
                            lp < rp -> -1
                            lp > rp -> 1
                            else -> 0
                        }
                    }
                }
            } catch (ex: Exception) {
                0
            }
        }
        return list
    }

    private fun setListData(dl: ArrayList<AppInfo>?, lv: OverScrollListView) {
        Scene.post {
            lv.adapter = XposedAppsAdapter(
                    this,
                    dl!!
            )
            processBarDialog.hideDialog()
        }
    }

    private var onLoading = false

    @SuppressLint("ApplySharedPref")
    private fun loadList(foreceReload: Boolean = false) {
        if (onLoading) {
            return
        }
        processBarDialog.showDialog()

        Thread(Runnable {
            onLoading = true
            if (foreceReload || installedList == null || installedList!!.size == 0) {
                installedList = ArrayList()/*在数组中存放数据*/
                installedList = applistHelper.getAll()
            }
            val keyword = binding.configSearchBox.text.toString().lowercase(Locale.getDefault())
            val search = keyword.isNotEmpty()
            var filterAppType = ""
            when (binding.configlistType.selectedItemPosition) {
                0 -> filterAppType = "/data"
                1 -> filterAppType = "/system"
                2 -> filterAppType = "*"
            }
            displayList = ArrayList()
            for (i in installedList!!.indices) {
                val item = installedList!![i]
                val packageName = item.packageName
                if (search && !(packageName.lowercase(Locale.getDefault()).contains(keyword) || item.appName.lowercase(Locale.getDefault()).contains(keyword))) {
                    continue
                } else {
                    if (filterAppType == "*" || item.path.startsWith(filterAppType)) {
                        displayList!!.add(item)
                        setAppRowDesc(item)
                    }
                }
            }
            sortAppList(displayList!!)
            Scene.post {
                processBarDialog.hideDialog()
                setListData(displayList, binding.sceneAppList)
            }
            onLoading = false
        }).start()
    }

    private fun setAppRowDesc(item: AppInfo) {
        item.selected = false
        val packageName = item.packageName
        val configInfo = SceneConfigInfo()
        configInfo.packageName = packageName
        item.sceneConfigInfo = configInfo

        if (xposedExtension.current != null) {
            xposedExtension.getAppConfig(packageName)?.run {
                val desc = StringBuilder()
                if (dpi > 0) {
                    desc.append("DPI:${dpi}  ")
                }
                if (excludeRecent) {
                    desc.append("Hide background  ")
                }
                if (smoothScroll) {
                    desc.append("Elastic slow scrolling  ")
                }
                if (webDebug) {
                    desc.append("Web debugging  ")
                }
                item.desc = desc.toString()
            }
        }

    }

    override fun onDestroy() {
        xposedExtension.unbindService()
        processBarDialog.hideDialog()
        super.onDestroy()
    }

    override fun onResume() {
        super.onResume()
        xposedExtension.bindService {
            loadList()
        }
        title = getString(R.string.menu_xposed_app)
    }
}
