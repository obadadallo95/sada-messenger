package org.sada.messenger.growth

import android.content.Context

data class UserStatusState(
    val statusText: String = "",
    val expiresAtMs: Long = 0L
) {
    fun isActive(now: Long = System.currentTimeMillis()): Boolean {
        return statusText.isNotBlank() && expiresAtMs > now
    }
}

class UserStatusStore(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun load(): UserStatusState {
        return UserStatusState(
            statusText = prefs.getString(KEY_TEXT, "") ?: "",
            expiresAtMs = prefs.getLong(KEY_EXPIRES_AT, 0L)
        )
    }

    fun save(text: String, expiresAtMs: Long) {
        prefs.edit()
            .putString(KEY_TEXT, text)
            .putLong(KEY_EXPIRES_AT, expiresAtMs)
            .apply()
    }

    fun clear() {
        prefs.edit()
            .remove(KEY_TEXT)
            .remove(KEY_EXPIRES_AT)
            .apply()
    }

    companion object {
        private const val PREFS_NAME = "sada_user_status"
        private const val KEY_TEXT = "status_text"
        private const val KEY_EXPIRES_AT = "status_expires_at"
    }
}
