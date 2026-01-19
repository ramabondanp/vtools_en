package com.omarea.vtools.activities

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import android.webkit.*
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.omarea.common.shared.FilePathResolver
import com.omarea.common.shared.FileWrite
import com.omarea.common.ui.DialogHelper
import com.omarea.common.ui.ProgressBarDialog
import com.omarea.krscript.WebViewInjector
import com.omarea.krscript.ui.ParamsFileChooserRender
import com.omarea.scene_mode.CpuConfigInstaller
import com.omarea.scene_mode.ModeSwitcher
import com.omarea.vtools.R
import com.omarea.vtools.databinding.ActivityAddinOnlineBinding
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.net.URL
import java.nio.charset.Charset
import java.util.zip.ZipInputStream

class ActivityAddinOnline : ActivityBase() {
    private lateinit var binding: ActivityAddinOnlineBinding
    private var fileSelectedInterface: ParamsFileChooserRender.FileSelectedInterface? = null

    private val fileChooserLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        val resultUri = if (result.resultCode == Activity.RESULT_OK) result.data?.data else null
        if (fileSelectedInterface != null) {
            if (resultUri != null) {
                fileSelectedInterface?.onFileSelected(getPath(resultUri))
            } else {
                fileSelectedInterface?.onFileSelected(null)
            }
        }
        fileSelectedInterface = null
    }

    override fun onPostResume() {
        super.onPostResume()
        delegate.onPostResume()
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityAddinOnlineBinding.inflate(layoutInflater)
        setContentView(binding.root)

        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
        window.statusBarColor = Color.WHITE
        window.navigationBarColor = Color.WHITE
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val insetsController = WindowInsetsControllerCompat(window, window.decorView)
        insetsController.isAppearanceLightStatusBars = true
        insetsController.isAppearanceLightNavigationBars = true


        if (this.intent.extras != null) {
            val extraData = intent.extras
            if (extraData?.containsKey("url") == true) {
                binding.vtoolsOnline.loadUrl(extraData.getString("url")!!)
            } else {
                binding.vtoolsOnline.loadUrl("https://helloklf.github.io/vtools-online.html#/scripts")
            }
        } else {
            binding.vtoolsOnline.loadUrl("https://helloklf.github.io/vtools-online.html#/scripts")
        }
        val context = this@ActivityAddinOnline
        val progressBarDialog = ProgressBarDialog(context)

        // 处理alert、confirm
        binding.vtoolsOnline.webChromeClient = object : WebChromeClient() {
            override fun onJsAlert(view: WebView?, url: String?, message: String?, result: JsResult?): Boolean {
                val dialog = DialogHelper.animDialog(
                        AlertDialog.Builder(context)
                                .setMessage(message)
                                .setPositiveButton(R.string.btn_confirm, { _, _ -> })
                                .setOnDismissListener {
                                    result?.confirm()
                                }
                                .create()
                )
                dialog?.setCancelable(false)
                return true // super.onJsAlert(view, url, message, result)
            }

            override fun onJsConfirm(view: WebView?, url: String?, message: String?, result: JsResult?): Boolean {
                val dialog = DialogHelper.animDialog(
                        AlertDialog.Builder(context)
                                .setMessage(message)
                                .setPositiveButton(R.string.btn_confirm) { _, _ ->
                                    result?.confirm()
                                }
                                .setNeutralButton(R.string.btn_cancel) { _, _ ->
                                    result?.cancel()
                                }
                                .create()
                )
                dialog?.setCancelable(false)
                return true // super.onJsConfirm(view, url, message, result)
            }
        }

        // 处理loading、文件下载
        binding.vtoolsOnline.setWebViewClient(object : WebViewClient() {
            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                progressBarDialog.hideDialog()
                view?.run {
                    setTitle(this.title)
                }
            }

            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                super.onPageStarted(view, url, favicon)
                progressBarDialog.showDialog(getString(R.string.please_wait))
            }

            private fun tryGetPowercfg(view: WebView?, url: String?): Boolean {
                if (url != null && view != null) {
                    // v1
                    // https://github.com/yc9559/cpufreq-interactive-opt/blob/master/vtools-powercfg/20180603/sd_845/powercfg.apk 源码地址
                    // https://github.com/yc9559/cpufreq-interactive-opt/raw/master/vtools-powercfg/20180603/sd_845/powercfg.apk 点击raw指向的链接
                    // https://raw.githubusercontent.com/yc9559/cpufreq-interactive-opt/master/vtools-powercfg/20180603/sd_845/powercfg.apk 然后重定向到具体文件
                    if (url.startsWith("https://github.com/yc9559/cpufreq-interactive-opt/") && url.contains("vtools-powercfg") && url.endsWith("powercfg.apk")) {
                        val configPath = url.substring(url.indexOf("vtools-powercfg"))
                        DialogHelper.animDialog(AlertDialog.Builder(binding.vtoolsOnline.context)
                                .setTitle("Available config script")
                                .setMessage("A performance tuning config script was detected on this page. Install it locally now?\n\nConfig: $configPath\n\nAuthor: yc9559\n\n")
                                .setPositiveButton(R.string.btn_confirm) { _, _ ->
                                    val configAbsPath = "https://github.com/yc9559/cpufreq-interactive-opt/raw/master/$configPath"
                                    downloadPowercfg(configAbsPath)
                                }
                                .setNeutralButton(R.string.btn_cancel) { _, _ ->
                                    view.loadUrl(url)
                                }).setCancelable(false)
                    } else if (url.startsWith("https://github.com/yc9559/wipe-v2/releases/download/") && url.endsWith(".zip")) {
                        // v2
                        // https://github.com/yc9559/wipe-v2/releases/download/0.1.190503-dev/sdm625.zip
                        val configPath = url.substring(url.lastIndexOf("/") + 1).replace(".zip", "")
                        DialogHelper.animDialog(AlertDialog.Builder(binding.vtoolsOnline.context)
                                .setTitle("Config installation prompt")
                                .setMessage("The content you clicked appears to be a performance tuning config script. Install it locally now?\n\nConfig: $configPath\n\nAuthor: yc9559\n\n")
                                .setPositiveButton(R.string.btn_confirm) { _, _ ->
                                    val configAbsPath = url
                                    downloadPowercfgV2(configAbsPath)
                                }
                                .setNeutralButton(R.string.btn_cancel) { _, _ ->
                                    view.loadUrl(url)
                                }).setCancelable(false)
                    } else {
                        view.loadUrl(url)
                    }
                    return true
                }
                return false
            }

            @Deprecated("Deprecated in WebViewClient", level = DeprecationLevel.WARNING)
            @Suppress("DEPRECATION")
            override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                return tryGetPowercfg(view, url)
            }

            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                if (view != null && request != null) {
                    val url = request.url.toString()
                    return this.tryGetPowercfg(view, url)
                }
                return super.shouldOverrideUrlLoading(view, request)
            }
        })

        binding.vtoolsOnline.settings.javaScriptEnabled = true
        binding.vtoolsOnline.settings.setLoadWithOverviewMode(true);
        binding.vtoolsOnline.settings.setUseWideViewPort(true);

        val url = binding.vtoolsOnline.url
        if (url != null) {
            if (url.startsWith("https://vtools.oss-cn-beijing.aliyuncs.com/") || url.startsWith("https://vtools.omarea.com/")) {
                // 添加kr-script for web
                WebViewInjector(binding.vtoolsOnline,
                        object : ParamsFileChooserRender.FileChooserInterface {
                            override fun openFileChooser(fileSelectedInterface: ParamsFileChooserRender.FileSelectedInterface): Boolean {
                                return chooseFilePath(fileSelectedInterface)
                            }
                        }).inject(this, false)
            }
        }
        binding.vtoolsOnline.addJavascriptInterface(object {
            @JavascriptInterface
            public fun setStatusBarColor(colorStr: String): Boolean {
                try {
                    val color = Color.parseColor(colorStr)
                    binding.vtoolsOnline.post {
                        window.statusBarColor = color
                        val controller = WindowInsetsControllerCompat(window, window.decorView)
                        val isLight = Color.red(color) > 180 && Color.green(color) > 180 && Color.blue(color) > 180
                        controller.isAppearanceLightStatusBars = isLight
                    }
                    return true
                } catch (ex: java.lang.Exception) {
                    return false
                }
            }

            @JavascriptInterface
            public fun setNavigationBarColor(colorStr: String): Boolean {
                try {
                    val color = Color.parseColor(colorStr)
                    binding.vtoolsOnline.post {
                        window.navigationBarColor = color
                        val controller = WindowInsetsControllerCompat(window, window.decorView)
                        val isLight = Color.red(color) > 180 && Color.green(color) > 180 && Color.blue(color) > 180
                        controller.isAppearanceLightNavigationBars = isLight
                    }

                    return true
                } catch (ex: java.lang.Exception) {
                    return false
                }
            }

            @JavascriptInterface
            public fun showToast(str: String) {
                try {
                    binding.vtoolsOnline.post {
                        Toast.makeText(context, str, Toast.LENGTH_LONG).show()
                    }
                } catch (ex: java.lang.Exception) {
                }
            }
        }, "SceneUI")
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK && binding.vtoolsOnline.canGoBack()) {
            binding.vtoolsOnline.goBack()
            return true
        } else {
            return super.onKeyDown(keyCode, event)
        }
    }

    private fun downloadPowercfg(url: String) {
        val progressBarDialog = ProgressBarDialog(this)
        progressBarDialog.showDialog("Fetching config, please wait...")
        Thread(Runnable {
            try {
                val myURL = URL(url)
                val conn = myURL.openConnection()
                conn.connect()
                conn.getInputStream()
                val reader = conn.getInputStream().bufferedReader(Charset.forName("UTF-8"))
                val powercfg = reader.readText()
                if (powercfg.startsWith("#!/") && CpuConfigInstaller().installCustomConfig(this, powercfg, ModeSwitcher.SOURCE_SCENE_ONLINE)) {
                    binding.vtoolsOnline.post {
                        DialogHelper.animDialog(AlertDialog.Builder(this)
                                .setTitle("Config file installed")
                                .setPositiveButton(R.string.btn_confirm) { _, _ ->
                                    setResult(Activity.RESULT_OK)
                                    finish()
                                }).setCancelable(false)
                    }
                } else {
                    binding.vtoolsOnline.post {
                        Toast.makeText(applicationContext, "Failed to download config file or file is invalid!", Toast.LENGTH_LONG).show()
                    }
                }
                binding.vtoolsOnline.post {
                    progressBarDialog.hideDialog()
                }
            } catch (ex: Exception) {
                binding.vtoolsOnline.post {
                    progressBarDialog.hideDialog()
                    Toast.makeText(applicationContext, "Failed to download config file!", Toast.LENGTH_LONG).show()
                }
            }
        }).start()
    }

    private fun downloadPowercfgV2(url: String) {
        val progressBarDialog = ProgressBarDialog(this)
        progressBarDialog.showDialog("Fetching config, please wait...")
        Thread(Runnable {
            try {
                val myURL = URL(url)
                val conn = myURL.openConnection()
                conn.connect()
                conn.getInputStream()
                val inputStream = conn.getInputStream()
                val buffer = inputStream.readBytes()
                val cacheName = "caches/powercfg_downloaded.zip"
                if (FileWrite.writePrivateFile(buffer, cacheName, baseContext)) {
                    val cachePath = FileWrite.getPrivateFilePath(baseContext, cacheName)

                    val zipInputStream = ZipInputStream(FileInputStream(File(cachePath)))
                    while (true) {
                        val zipEntry = zipInputStream.nextEntry
                        if (zipEntry == null) {
                            throw java.lang.Exception("Downloaded file is invalid; powercfg.sh not found")
                        } else if (zipEntry.name == "powercfg.sh") {
                            val byteArray = zipInputStream.readBytes()
                            val powercfg = byteArray.toString(Charset.defaultCharset())
                            if (powercfg.startsWith("#!/") && CpuConfigInstaller().installCustomConfig(this, powercfg, ModeSwitcher.SOURCE_SCENE_ONLINE)) {
                                binding.vtoolsOnline.post {
                                    DialogHelper.animDialog(AlertDialog.Builder(this)
                                            .setTitle("Config file installed")
                                            .setPositiveButton(R.string.btn_confirm) { _, _ ->
                                                setResult(Activity.RESULT_OK)
                                                finish()
                                            }).setCancelable(false)
                                }
                            } else {
                                binding.vtoolsOnline.post {
                                    Toast.makeText(applicationContext, "Failed to download config file or file is invalid!", Toast.LENGTH_LONG).show()
                                }
                            }
                            binding.vtoolsOnline.post {
                                progressBarDialog.hideDialog()
                            }
                            break
                        } else {
                            zipInputStream.skip(zipEntry.size)
                        }
                    }
                } else {
                    throw IOException("Failed to save file")
                }
            } catch (ex: Exception) {
                binding.vtoolsOnline.post {
                    progressBarDialog.hideDialog()
                    Toast.makeText(applicationContext, "Failed to download config file!", Toast.LENGTH_LONG).show()
                }
            }
        }).start()
    }

    private fun chooseFilePath(fileSelectedInterface: ParamsFileChooserRender.FileSelectedInterface): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE), 2);
            Toast.makeText(this, getString(R.string.kr_write_external_storage), Toast.LENGTH_LONG).show()
            return false
        } else {
            try {
                val intent = Intent(Intent.ACTION_GET_CONTENT);
                intent.setType("*/*")
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                this.fileSelectedInterface = fileSelectedInterface
                fileChooserLauncher.launch(intent)
                return true;
            } catch (ex: java.lang.Exception) {
                return false
            }
        }
    }

    private fun getPath(uri: Uri): String? {
        try {
            return FilePathResolver().getPath(this, uri)
        } catch (ex: java.lang.Exception) {
            return null
        }
    }

    override fun onDestroy() {
        binding.vtoolsOnline.clearCache(true)
        binding.vtoolsOnline.removeAllViews()
        binding.vtoolsOnline.destroy()
        super.onDestroy()
    }

    public override fun onPause() {
        super.onPause()
    }
}
