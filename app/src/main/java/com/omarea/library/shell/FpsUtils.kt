package com.omarea.library.shell

import com.omarea.common.shell.KeepShell
import com.omarea.common.shell.KeepShellPublic
import com.omarea.common.shell.RootFile.fileExists

/**
 * 帧率检测
 */
class FpsUtils(private val keepShell: KeepShell = KeepShellPublic.secondaryKeepShell) {
    private var fpsFilePath: String? = null
    private var subStrCommand = "| awk '{print \$2}'"
    private val gfxInfoFpsUtils = GfxInfoFpsUtils(KeepShellPublic.getInstance("gfxinfo-fps", true))

    private val fpsgoStatusPath = "/sys/kernel/fpsgo/fstb/fpsgo_status"

    private var fpsCommand2 = "service call SurfaceFlinger 1013"
    private var lastTime = -1L
    private var lastFrames = -1

    val currentFps: String?
        get() {
            gfxInfoFpsUtils.getFps()?.let {
                return String.format("%.1f", it)
            }
            // 优先使用GPU的内核级帧数数据
            if (!fpsFilePath.isNullOrEmpty()) {
                return keepShell.doCmdSync("cat $fpsFilePath $subStrCommand")
            }
            // 如果系统帧率不可用使用GPU的内核级帧数数据
            else if (fpsFilePath == null) {
                when {
                    fileExists("/sys/class/drm/sde-crtc-0/measured_fps") -> {
                        fpsFilePath = "/sys/class/drm/sde-crtc-0/measured_fps"
                    }
                    fileExists("/sys/class/graphics/fb0/measured_fps") -> {
                        fpsFilePath = "/sys/class/graphics/fb0/measured_fps"
                        subStrCommand = ""
                    }
                    else -> {
                        fpsFilePath = ""
                        val keepShell = KeepShell()
                        Thread(Runnable {
                            try {
                                keepShell.doCmdSync("find /sys -name measured_fps 2>/dev/null")
                                        .trim { it <= ' ' }.split("\n").filter { it.contains("crtc") }.minOrNull()?.run {
                                            fpsFilePath = this
                                        }

                                if (fpsFilePath == null || fpsFilePath == "") {
                                    keepShell.doCmdSync("find /sys -name fps 2>/dev/null")
                                            .trim { it <= ' ' }.split("\n").filter { it.contains("crtc") }.minOrNull()?.run {
                                                fpsFilePath = this
                                            }
                                }
                                if (fpsFilePath == null) {
                                    fpsFilePath = ""
                                }
                                keepShell.tryExit()
                            } catch (ex: Exception) {
                                fpsFilePath = ""
                            }
                        }).start()
                    }
                }
            }
            // 使用FPSGO状态中的当前帧率
            readFpsgoStatusFps()?.let {
                return String.format("%.1f", it)
            }
            // 使用系统帧率
            if (fpsCommand2.isNotEmpty()) {
                val result = keepShell.doCmdSync(fpsCommand2).trim()
                if (result != "error" && !result.contains("Parcel")) {
                    fpsCommand2 = ""
                } else {
                    try {
                        val index = result.indexOf("(") + 1
                        val frames = Integer.parseInt(result.substring(index, index + 8), 16)
                        val time = System.currentTimeMillis()
                        var fps = 0F
                        if (lastTime > 0 && lastFrames > 0) {
                            fps = (frames - lastFrames) * 1000.0f / (time - lastTime)
                        }
                        lastFrames = frames
                        lastTime = time
                        return String.format("%.1f", fps)
                    } catch (ex: Exception) {
                        if (!(lastTime > 0 && lastFrames > 0)) {
                            fpsCommand2 = ""
                        }
                    }
                }
            }
            return null
        }

    val fps: Float
        get() {
            val fpsStr = currentFps
            if (fpsStr != null) {
                try {
                    return fpsStr.toFloat()
                } catch (ex: java.lang.Exception) {
                }
            }
            return 1f
        }

    private fun readFpsgoStatusFps(): Float? {
        if (!fileExists(fpsgoStatusPath)) {
            return null
        }
        val pkg = getTopPackageName() ?: return null
        val output = keepShell.doCmdSync("cat $fpsgoStatusPath 2>/dev/null").trim()
        if (output.isEmpty() || output == "error") {
            return null
        }
        val rows = output.split("\n")
        var nameIndex = -1
        var fpsIndex = -1
        var bestFps = -1f
        for (row in rows) {
            val line = row.trim()
            if (line.isEmpty()) {
                continue
            }
            if (line.startsWith("tid")) {
                val headerCols = line.split(Regex("\\s+"))
                nameIndex = headerCols.indexOf("name")
                fpsIndex = headerCols.indexOf("currentFPS")
                continue
            }
            if (nameIndex < 0 || fpsIndex < 0) {
                continue
            }
            val cols = line.split(Regex("\\s+"))
            if (cols.size <= fpsIndex || cols.size <= nameIndex) {
                continue
            }
            val name = cols[nameIndex]
            if (!nameMatchesPackage(name, pkg)) {
                continue
            }
            val fps = cols[fpsIndex].toFloatOrNull() ?: continue
            if (fps > bestFps) {
                bestFps = fps
            }
        }
        if (bestFps == 0f) {
            return 1f
        }
        return if (bestFps >= 0f) bestFps else null
    }

    private fun nameMatchesPackage(name: String, packageName: String): Boolean {
        if (packageName == name || packageName.endsWith(name)) {
            return true
        }
        val tail = packageName.substringAfterLast(".")
        return name.endsWith(tail)
    }

    private fun getTopPackageName(): String? {
        val resumed = keepShell.doCmdSync("dumpsys activity activities | grep -m 1 \"mResumedActivity\"").trim()
        parsePackageFromDump(resumed)?.let { return it }
        val currentFocus = keepShell.doCmdSync("dumpsys window | grep -m 1 \"mCurrentFocus\"").trim()
        return parsePackageFromDump(currentFocus)
    }

    private fun parsePackageFromDump(line: String): String? {
        if (line.isEmpty() || line == "error") {
            return null
        }
        val match = Regex("([a-zA-Z0-9._]+)/(?:[a-zA-Z0-9._]+)").find(line) ?: return null
        return match.groupValues[1]
    }
}
