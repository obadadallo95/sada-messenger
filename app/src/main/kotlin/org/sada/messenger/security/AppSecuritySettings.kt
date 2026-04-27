package org.sada.messenger.security

import android.content.Context
import android.util.Base64
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import java.security.SecureRandom
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

class AppSecuritySettings(context: Context) {
    companion object {
        private const val PREFS_NAME = "sada_secure_settings"
        private const val KEY_APP_LOCK_ENABLED = "app_lock_enabled"
        private const val KEY_MASTER_PIN_HASH = "master_pin_hash"
        private const val KEY_MASTER_PIN_SALT = "master_pin_salt"
        private const val PIN_LENGTH = 6
        private const val PBKDF2_ITERATIONS = 120_000
        private const val PBKDF2_KEY_LENGTH = 256
    }

    private val secureRandom = SecureRandom()

    private val securePrefs = try {
        createSecurePrefs(context)
    } catch (e: Exception) {
        wipeSecureStorage(context)
        try {
            createSecurePrefs(context)
        } catch (e2: Exception) {
            context.getSharedPreferences(PREFS_NAME + "_fallback", Context.MODE_PRIVATE)
        }
    }

    private fun createSecurePrefs(ctx: Context) = EncryptedSharedPreferences.create(
        ctx,
        PREFS_NAME,
        MasterKey.Builder(ctx).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    private fun wipeSecureStorage(ctx: Context) {
        try {
            ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit().clear().apply()
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                ctx.deleteSharedPreferences(PREFS_NAME)
            }
            val ks = java.security.KeyStore.getInstance("AndroidKeyStore")
            ks.load(null)
            val aliases = ks.aliases()
            while (aliases.hasMoreElements()) {
                val alias = aliases.nextElement()
                if (alias.contains("androidx_security") || alias.contains(PREFS_NAME)) {
                    ks.deleteEntry(alias)
                }
            }
        } catch (_: Exception) {}
    }

    fun isAppLockEnabled(): Boolean = securePrefs.getBoolean(KEY_APP_LOCK_ENABLED, false)

    fun setAppLockEnabled(enabled: Boolean) {
        securePrefs.edit().putBoolean(KEY_APP_LOCK_ENABLED, enabled).apply()
    }

    fun hasMasterPin(): Boolean = !securePrefs.getString(KEY_MASTER_PIN_HASH, null).isNullOrBlank()

    fun setMasterPin(pin: String): Boolean {
        if (!isValidPin(pin)) return false

        val salt = ByteArray(16).also(secureRandom::nextBytes)
        val hash = pbkdf2(pin, salt)

        securePrefs.edit()
            .putString(KEY_MASTER_PIN_SALT, Base64.encodeToString(salt, Base64.NO_WRAP))
            .putString(KEY_MASTER_PIN_HASH, Base64.encodeToString(hash, Base64.NO_WRAP))
            .apply()
        return true
    }

    fun verifyPin(pin: String): Boolean {
        val saltEncoded = securePrefs.getString(KEY_MASTER_PIN_SALT, null) ?: return false
        val hashEncoded = securePrefs.getString(KEY_MASTER_PIN_HASH, null) ?: return false

        val salt = Base64.decode(saltEncoded, Base64.NO_WRAP)
        val expected = Base64.decode(hashEncoded, Base64.NO_WRAP)
        val actual = pbkdf2(pin, salt)

        return expected.contentEquals(actual)
    }

    fun isValidPin(pin: String): Boolean {
        return pin.length == PIN_LENGTH && pin.all { it.isDigit() }
    }

    private fun pbkdf2(pin: String, salt: ByteArray): ByteArray {
        val spec = PBEKeySpec(pin.toCharArray(), salt, PBKDF2_ITERATIONS, PBKDF2_KEY_LENGTH)
        val factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
        return factory.generateSecret(spec).encoded
    }
}
