package com.omarea.common.shared

import android.content.Context
import java.lang.Exception
import java.lang.StringBuilder
import java.util.*

// 从Resource解析字符串
open class ResourceStringResolver(protected val context: Context) {
    // 示例：
    // @string:home_shell_01
    private val regex1 = Regex("^@(string|dimen):[_a-z]+.*", RegexOption.IGNORE_CASE)
    // 示例
    // @string/home_shell_01
    private val regex2 = Regex("^@(string|dimen)/[_a-z]+.*", RegexOption.IGNORE_CASE)
    private val inlineRegex = Regex("@(string|dimen)[:/][A-Za-z0-9_]+", RegexOption.IGNORE_CASE)

    fun resolveRow(originRow: String): String {
        val row = originRow.trim()
        val separator = if (row.startsWith("@")) {
            when {
                regex1.matches(row) -> ':'
                regex2.matches(row) -> '/'
                else -> null
            }
        } else {
            null
        }
        if (separator != null) {
            val resources = context.resources
            val type = row.substring(1, row.indexOf(separator)).toLowerCase(Locale.ENGLISH)
            val name = row.substring(row.indexOf(separator) + 1)

            try {
                val id = resources.getIdentifier(name, type, context.packageName)
                when (type) {
                    "string" -> {
                        return resources.getString(id)
                    }
                    "dimen" -> {
                        return resources.getDimension(id).toString()
                    }
                }
            } catch (ex: Exception) {
                if (row.contains("[(") && row.contains(")]")) {
                    return row.substring(row.indexOf("[(") + 2, row.indexOf(")]"))
                }
            }
        }

        val resources = context.resources
        val replaced = inlineRegex.replace(originRow) { match ->
            val raw = match.value
            val separatorIndex = raw.indexOf(':').takeIf { it >= 0 } ?: raw.indexOf('/')
            val type = raw.substring(1, separatorIndex).toLowerCase(Locale.ENGLISH)
            val name = raw.substring(separatorIndex + 1)
            try {
                val id = resources.getIdentifier(name, type, context.packageName)
                when (type) {
                    "string" -> resources.getString(id)
                    "dimen" -> resources.getDimension(id).toString()
                    else -> raw
                }
            } catch (ex: Exception) {
                raw
            }
        }

        return replaced
    }

    fun resolveRows(rows: List<String>): String {
        val builder = StringBuilder()
        var rowIndex = 0
        for (row in rows) {
            if (rowIndex > 0) {
                builder.append("\n")
            }
            builder.append(resolveRow(row))
            rowIndex ++
        }
        return builder.toString()
    }
}
