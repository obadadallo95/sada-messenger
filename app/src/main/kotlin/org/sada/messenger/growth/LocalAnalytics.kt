package org.sada.messenger.growth

import android.content.Context

data class LocalAnalyticsSnapshot(
    val qrScanOpened: Long,
    val qrScanSuccess: Long,
    val qrShared: Long,
    val contactsAddedViaQr: Long
)

class LocalAnalytics(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun trackQrScanOpened() = increment(KEY_QR_SCAN_OPENED)
    fun trackQrScanSuccess() = increment(KEY_QR_SCAN_SUCCESS)
    fun trackQrShared() = increment(KEY_QR_SHARED)
    fun trackContactAddedViaQr() = increment(KEY_CONTACT_ADDED)

    fun snapshot(): LocalAnalyticsSnapshot {
        return LocalAnalyticsSnapshot(
            qrScanOpened = prefs.getLong(KEY_QR_SCAN_OPENED, 0L),
            qrScanSuccess = prefs.getLong(KEY_QR_SCAN_SUCCESS, 0L),
            qrShared = prefs.getLong(KEY_QR_SHARED, 0L),
            contactsAddedViaQr = prefs.getLong(KEY_CONTACT_ADDED, 0L)
        )
    }

    fun reset() {
        prefs.edit().clear().apply()
    }

    private fun increment(key: String) {
        val next = prefs.getLong(key, 0L) + 1L
        prefs.edit().putLong(key, next).apply()
    }

    companion object {
        private const val PREFS_NAME = "sada_local_analytics"
        private const val KEY_QR_SCAN_OPENED = "qr_scan_opened"
        private const val KEY_QR_SCAN_SUCCESS = "qr_scan_success"
        private const val KEY_QR_SHARED = "qr_shared"
        private const val KEY_CONTACT_ADDED = "contact_added_via_qr"
    }
}
