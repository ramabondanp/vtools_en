package com.omarea.library.shell

import android.os.SystemClock
import com.omarea.common.shell.KeepShell

/**
 * FPS monitor using gfxinfo framestats (requires root).
 */
class GfxInfoFpsUtils(private val keepShell: KeepShell) {
    private var lastActivePackage: String? = null
    private val frameTimeBuffer = ArrayList<Long>()
    private var lastProcessedFrameTime = 0L
    private var gfxColumnIndex = -1
    private var lastFrameSeenAtMs = 0L

    @Synchronized
    fun getFps(): Float? {
        val packageName = getTopPackageName() ?: return null
        if (packageName != lastActivePackage) {
            lastActivePackage = packageName
            frameTimeBuffer.clear()
            lastProcessedFrameTime = 0L
            gfxColumnIndex = -1
            keepShell.doCmdSync("dumpsys gfxinfo $packageName reset")
            return null
        }

        val output = keepShell.doCmdSync("dumpsys gfxinfo $packageName framestats")
        if (output.isEmpty() || output == "error") {
            return null
        }

        val lines = output.split("\n")
        if (gfxColumnIndex == -1) {
            val header = lines.firstOrNull { it.contains("FrameCompleted") } ?: return null
            val headers = header.split(",")
            gfxColumnIndex = headers.indexOf("FrameCompleted")
            if (gfxColumnIndex == -1) {
                return null
            }
        }

        var maxTimestamp = lastProcessedFrameTime
        var addedFrames = 0
        for (line in lines) {
            val parts = line.split(",")
            if (parts.size <= gfxColumnIndex) {
                continue
            }
            val timestamp = parts[gfxColumnIndex].trim().toLongOrNull() ?: continue
            if (timestamp <= lastProcessedFrameTime) {
                continue
            }
            frameTimeBuffer.add(timestamp)
            addedFrames += 1
            if (timestamp > maxTimestamp) {
                maxTimestamp = timestamp
            }
        }
        lastProcessedFrameTime = maxTimestamp
        if (addedFrames > 0) {
            lastFrameSeenAtMs = SystemClock.elapsedRealtime()
        } else if (lastFrameSeenAtMs > 0 && SystemClock.elapsedRealtime() - lastFrameSeenAtMs > 2000) {
            frameTimeBuffer.clear()
            lastProcessedFrameTime = 0L
            gfxColumnIndex = -1
            keepShell.doCmdSync("dumpsys gfxinfo $packageName reset")
            return null
        }

        val nowNs = System.nanoTime()
        val iterator = frameTimeBuffer.iterator()
        while (iterator.hasNext()) {
            val frameTime = iterator.next()
            if (nowNs - frameTime > 1_000_000_000L) {
                iterator.remove()
            }
        }

        if (frameTimeBuffer.isEmpty()) {
            return null
        }
        val fps = frameTimeBuffer.size.toFloat()
        return fps
    }

    private fun getTopPackageName(): String? {
        val line = keepShell.doCmdSync("dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'").trim()
        return parsePackageFromDump(line)
    }

    private fun parsePackageFromDump(line: String): String? {
        if (line.isEmpty() || line == "error") {
            return null
        }
        val match = Regex("([a-zA-Z0-9._-]+)/").find(line) ?: return null
        return match.groupValues[1]
    }
}
