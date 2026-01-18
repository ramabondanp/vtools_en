package com.omarea.vtools.fragments

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.Toast
import com.omarea.permissions.CheckRootStatus
import com.omarea.utils.AlipayDonate
import com.omarea.vtools.R
import com.omarea.vtools.databinding.FragmentDonateBinding


class FragmentDonate : androidx.fragment.app.Fragment(), View.OnClickListener {
    private var _binding: FragmentDonateBinding? = null
    private val binding get() = _binding!!

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?,
                              savedInstanceState: Bundle?): View {
        _binding = FragmentDonateBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onResume() {
        super.onResume()
        // activity!!.title = getString(R.string.menu_paypal)
        activity!!.title = getString(R.string.app_name)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.payPaypal.setOnClickListener {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://www.paypal.me/duduski")))
        }
        binding.payAlipay.setOnClickListener {
            AlipayDonate(context!!).jumpAlipay()
        }
        binding.payWxpay.setOnClickListener {
            /*
            try {
                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("weixin://dl/business/?ticket=wxp://f2f0YqS-OUviH9sQNUDgXJhOP3fld3htEqqO")))
            } catch (ex: Exception) {
                Toast.makeText(context!!, "This method is not supported.", Toast.LENGTH_SHORT).show()
            }
            */
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("http://vtools.omarea.com/")))
            Toast.makeText(context!!, "Direct launch is not supported. Save the payment code and scan it in WeChat (choose the image from the gallery).", Toast.LENGTH_SHORT).show()
        }

        bindClickEvent(binding.navGesture)
        bindClickEvent(binding.navFilter)
        bindClickEvent(binding.navShare)
        bindClickEvent(binding.navQq)
    }

    private fun bindClickEvent(view: View) {
        view.setOnClickListener(this)
        if (!CheckRootStatus.lastCheckResult && "root".equals(view.getTag())) {
            view.isEnabled = false
        }
    }

    override fun onClick(v: View?) {
        v?.run {
            if (!CheckRootStatus.lastCheckResult && "root".equals(getTag())) {
                Toast.makeText(context, "Root permission not granted; this feature is unavailable.", Toast.LENGTH_SHORT).show()
                return
            }

            when (id) {
                R.id.nav_gesture -> {
                    tryOpenApp("com.omarea.gesture")
                    return
                }
                R.id.nav_filter -> {
                    tryOpenApp("com.omarea.filter")
                    return
                }
                R.id.nav_qq -> {
                    val key = "6ffXO4eTZVN0eeKmp-2XClxizwIc7UIu" //""e-XL2In7CgIpeK_sG75s-vAiu7n5DnlS"
                    val intent = Intent()
                    intent.data = Uri.parse("mqqopensdkapi://bizAgent/qm/qr?url=http%3A%2F%2Fqm.qq.com%2Fcgi-bin%2Fqm%2Fqr%3Ffrom%3Dapp%26p%3Dandroid%26k%3D$key")
                    // 此Flag可根据具体产品需要自定义，如设置，则在加群界面按返回，返回手Q主界面，不设置，按返回会返回到呼起产品界面    //intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    return try {
                        startActivity(intent)
                    } catch (e: Exception) {
                    }
                }
                R.id.nav_share -> {
                    val sendIntent = Intent()
                    sendIntent.action = Intent.ACTION_SEND
                    sendIntent.putExtra(Intent.EXTRA_TEXT, getString(R.string.share_link))
                    sendIntent.type = "text/plain"
                    startActivity(sendIntent)
                }
            }
        }
    }

    private fun tryOpenApp(packageName: String) {
        val pm = context!!.packageManager
        if (packageName.equals("com.omarea.gesture")) {
            try {
                val intent = Intent(Intent.ACTION_VIEW)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                intent.setComponent(ComponentName("com.omarea.gesture", "com.omarea.gesture.SettingsActivity"))
                startActivity(intent)
                return
            } catch (ex: java.lang.Exception) {
            }
        } else if (packageName.equals("com.omarea.filter")) {
            try {
                val intent = Intent(Intent.ACTION_VIEW)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                intent.setComponent(ComponentName("com.omarea.filter", "com.omarea.filter.SettingsActivity"))
                startActivity(intent)
                return
            } catch (ex: java.lang.Exception) {
            }
        }

        try {
            val intent = pm.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return
            }
        } catch (ex: java.lang.Exception) {
        }

        openUrl("https://www.coolapk.com/apk/" + packageName)
        /*
            Uri uri = Uri.parse("market://details?id=" + appPkg);
            Intent intent = new Intent(Intent.ACTION_VIEW, uri);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (marketPkg != null) {// 如果没给市场的包名，则系统会弹出市场的列表让你进行选择。
                intent.setPackage(marketPkg);
            }
            try {
                context.startActivity(intent);
                return true;
            } catch (Exception ex) {
                ex.printStackTrace();
                return false;
            }
        */
    }

    private fun openUrl(link: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(link))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (ex: Exception) {
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
