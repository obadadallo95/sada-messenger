package org.sada.messenger.security

import android.content.Context
import android.util.Base64
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.goterl.lazysodium.LazySodiumAndroid
import com.goterl.lazysodium.SodiumAndroid
import com.goterl.lazysodium.interfaces.Box
import com.goterl.lazysodium.utils.KeyPair
import com.goterl.lazysodium.utils.Key

/**
 * مدير المفاتيح
 * يولد ويخزن المفاتيح بشكل آمن باستخدام EncryptedSharedPreferences
 */
class KeyManager(private val context: Context) {
    companion object {
        private const val TAG = "SadaKeyManager"
        private const val PREFS_NAME = "sada_secure_prefs"
        private const val PRIVATE_KEY_KEY = "user_private_key"
        private const val PUBLIC_KEY_KEY = "user_public_key"
    }

    private val lazySodium = LazySodiumAndroid(SodiumAndroid())
    
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val securePrefs = EncryptedSharedPreferences.create(
        context,
        PREFS_NAME,
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    private var cachedKeyPair: KeyPair? = null

    /**
     * الحصول على زوج المفاتيح أو توليد زوج جديد
     */
    fun getKeyPair(): KeyPair {
        cachedKeyPair?.let { return it }

        val privateKeyBase64 = securePrefs.getString(PRIVATE_KEY_KEY, null)
        val publicKeyBase64 = securePrefs.getString(PUBLIC_KEY_KEY, null)

        return if (privateKeyBase64 != null && publicKeyBase64 != null) {
            try {
                val priv = Base64.decode(privateKeyBase64, Base64.DEFAULT)
                val pub = Base64.decode(publicKeyBase64, Base64.DEFAULT)
                KeyPair(Key.fromBytes(pub), Key.fromBytes(priv)).also { cachedKeyPair = it }
            } catch (e: Exception) {
                Log.e(TAG, "Error loading keys, regenerating...", e)
                generateAndSaveKeyPair()
            }
        } else {
            generateAndSaveKeyPair()
        }
    }

    /**
     * توليد وحفظ زوج مفاتيح جديد (Curve25519)
     */
    fun generateAndSaveKeyPair(): KeyPair {
        val keyPair = lazySodium.cryptoBoxKeypair()
        
        val privBase64 = Base64.encodeToString(keyPair.secretKey.asBytes, Base64.DEFAULT)
        val pubBase64 = Base64.encodeToString(keyPair.publicKey.asBytes, Base64.DEFAULT)

        securePrefs.edit()
            .putString(PRIVATE_KEY_KEY, privBase64)
            .putString(PUBLIC_KEY_KEY, pubBase64)
            .apply()

        cachedKeyPair = keyPair
        Log.i(TAG, "New KeyPair generated and saved securely")
        return keyPair
    }

    /**
     * الحصول على المفتاح العام كـ ByteArray
     */
    fun getPublicKey(): ByteArray = getKeyPair().publicKey.asBytes

    /**
     * الحصول على المفتاح العام كـ Base64
     */
    fun getPublicKeyBase64(): String = Base64.encodeToString(getPublicKey(), Base64.NO_WRAP)

    /**
     * حذف المفاتيح بشكل نهائي
     */
    fun deleteKeys() {
        securePrefs.edit().clear().apply()
        cachedKeyPair = null
        Log.i(TAG, "Secure storage cleared")
    }
}
