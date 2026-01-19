package com.omarea.ui

import android.graphics.drawable.Drawable
import android.util.TypedValue
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.viewpager2.adapter.FragmentStateAdapter
import androidx.viewpager2.widget.ViewPager2
import com.google.android.material.tabs.TabLayout
import com.google.android.material.tabs.TabLayoutMediator
import com.omarea.vtools.R

class TabIconHelper2(
        private var tabLayout: TabLayout,
        private var viewPager: ViewPager2,
        private var activity: FragmentActivity,
        private var layout: Int = R.layout.list_item_tab
) {
    private val fragments = ArrayList<Fragment>()
    private var views = ArrayList<View>()
    public val adapter = object : FragmentStateAdapter(activity) {
        override fun getItemCount(): Int = fragments.size

        override fun createFragment(position: Int): Fragment {
            return fragments[position]
        }
    }

    fun newTabSpec(drawable: Drawable, fragment: Fragment): String {
        return newTabSpec("", drawable, fragment)
    }

    fun newTabSpec(text: String, drawable: Drawable, fragment: Fragment): String {
        val layout = View.inflate(activity, layout, null)
        val imageView = layout.findViewById<ImageView>(R.id.ItemIcon)
        val textView = layout.findViewById<TextView>(R.id.ItemTitle)
        val tabId = "tab_" + views.size

        textView.setText(text)

        // val tintIcon = DrawableCompat.wrap(view.drawable)
        // val csl = getResources().getColorStateList(R.color.colorAccent)
        // DrawableCompat.setTintList(tintIcon, csl)
        // imageView.setImageDrawable(tintIcon)
        // imageView.setColorFilter(getColorAccent())

        if (views.size != 0) {
            layout.alpha = 0.3f
        }
        imageView.setImageDrawable(drawable)
        views.add(layout)

        fragments.add(fragment)
        adapter.notifyDataSetChanged()

        return tabId
    }

    fun getColorAccent(): Int {
        val typedValue = TypedValue()
        this.activity.theme.resolveAttribute(R.attr.colorAccent, typedValue, true)
        return typedValue.data
    }

    fun updateHighlight() {
        val currentTab = tabLayout.selectedTabPosition
        if (currentTab > -1) {
            for (i in 0 until tabLayout.tabCount) {
                val tab = tabLayout.getTabAt(i)
                tab?.customView?.alpha = (if (i == currentTab) {
                    1f
                } else {
                    0.3f
                })
            }
        }
    }

    init {
        viewPager.adapter = adapter
        TabLayoutMediator(tabLayout, viewPager) { tab, position ->
            tab.customView = views[position]
        }.attach()

        tabLayout.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
            override fun onTabSelected(tab: TabLayout.Tab?) {
                updateHighlight()
            }

            override fun onTabUnselected(tab: TabLayout.Tab?) {

            }

            override fun onTabReselected(tab: TabLayout.Tab?) {

            }
        })
    }
}
