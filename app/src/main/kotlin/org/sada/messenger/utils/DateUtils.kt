package org.sada.messenger.utils

import java.text.SimpleDateFormat
import java.util.*

object DateUtils {
    private const val ISO_8601_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"
    private const val ISO_8601_FORMAT_NO_MS = "yyyy-MM-dd'T'HH:mm:ssXXX"
    private const val ISO_8601_FORMAT_Z = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    
    fun getCurrentIsoTimestamp(): String {
        val sdf = SimpleDateFormat(ISO_8601_FORMAT, Locale.US)
        sdf.timeZone = TimeZone.getDefault()
        return sdf.format(Date())
    }

    fun formatIso(date: Date): String {
        val sdf = SimpleDateFormat(ISO_8601_FORMAT, Locale.US)
        sdf.timeZone = TimeZone.getDefault()
        return sdf.format(date)
    }

    fun parseIso(isoString: String): Date {
        val formats = listOf(ISO_8601_FORMAT, ISO_8601_FORMAT_NO_MS, ISO_8601_FORMAT_Z)
        for (pattern in formats) {
            try {
                val sdf = SimpleDateFormat(pattern, Locale.US)
                if (pattern.endsWith("'Z'")) {
                    sdf.timeZone = TimeZone.getTimeZone("UTC")
                } else {
                    sdf.timeZone = TimeZone.getDefault()
                }
                return sdf.parse(isoString) ?: continue
            } catch (e: Exception) {
                continue
            }
        }
        return Date() // Fallback
    }
}
