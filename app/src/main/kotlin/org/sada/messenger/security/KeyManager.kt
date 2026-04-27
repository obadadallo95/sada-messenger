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
        private const val KEY_GENERATION_DATE_KEY = "key_generation_date"
        private const val KEY_ROTATION_INTERVAL_MS = 24 * 60 * 60 * 1000L // 24 hours
        private const val MAX_KEY_VERSIONS = 3 // Keep last 3 keys for backward compatibility
    }

    private val lazySodium = LazySodiumAndroid(SodiumAndroid())
    
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val securePrefs = try {
        createSecurePrefs(context)
    } catch (e: Exception) {
        Log.e(TAG, "EncryptedSharedPreferences corrupted, wiping secure storage...", e)
        wipeSecureStorage(context)
        try {
            createSecurePrefs(context)
        } catch (e2: Exception) {
            Log.e(TAG, "Failed to recover secure storage, falling back to plain SharedPreferences (NOT RECOMMENDED FOR PRODUCTION)", e2)
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
            // 1. Clear the data
            ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit().clear().apply()
            
            // 2. Delete the file
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                ctx.deleteSharedPreferences(PREFS_NAME)
            } else {
                val prefsFile = java.io.File(ctx.filesDir.parent + "/shared_prefs/${PREFS_NAME}.xml")
                if (prefsFile.exists()) prefsFile.delete()
            }

            // 3. Delete Keystore entries
            val ks = java.security.KeyStore.getInstance("AndroidKeyStore")
            ks.load(null)
            val aliases = ks.aliases()
            while (aliases.hasMoreElements()) {
                val alias = aliases.nextElement()
                if (alias.contains("androidx_security") || alias.contains(PREFS_NAME)) {
                    ks.deleteEntry(alias)
                    Log.d(TAG, "Deleted Keystore alias: $alias")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error during secure storage wipe", e)
        }
    }

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
     * مع دعم Perfect Forward Secrecy (تخزين المفاتيح القديمة لفترة وجيزة)
     */
    fun generateAndSaveKeyPair(): KeyPair {
        // Archive current key before generating new one (for PFS)
        archiveCurrentKey()
        
        val keyPair = lazySodium.cryptoBoxKeypair()
        
        val privBase64 = Base64.encodeToString(keyPair.secretKey.asBytes, Base64.DEFAULT)
        val pubBase64 = Base64.encodeToString(keyPair.publicKey.asBytes, Base64.DEFAULT)

        securePrefs.edit()
            .putString(PRIVATE_KEY_KEY, privBase64)
            .putString(PUBLIC_KEY_KEY, pubBase64)
            .putLong(KEY_GENERATION_DATE_KEY, System.currentTimeMillis())
            .apply()

        cachedKeyPair = keyPair
        Log.i(TAG, "New KeyPair generated and saved securely (PFS enabled)")
        return keyPair
    }
    
    /**
     * Perfect Forward Secrecy: Archive current key for backward compatibility.
     * Old messages can still be decrypted, but new messages use fresh keys.
     */
    private fun archiveCurrentKey() {
        val currentPriv = securePrefs.getString(PRIVATE_KEY_KEY, null)
        val currentPub = securePrefs.getString(PUBLIC_KEY_KEY, null)
        
        if (currentPriv != null && currentPub != null) {
            // Shift existing archives
            for (i in (MAX_KEY_VERSIONS - 2) downTo 0) {
                val oldPriv = securePrefs.getString("${PRIVATE_KEY_KEY}_$i", null)
                val oldPub = securePrefs.getString("${PUBLIC_KEY_KEY}_$i", null)
                if (oldPriv != null) {
                    securePrefs.edit()
                        .putString("${PRIVATE_KEY_KEY}_${i+1}", oldPriv)
                        .putString("${PUBLIC_KEY_KEY}_${i+1}", oldPub)
                        .apply()
                }
            }
            
            // Store current as archive version 0
            securePrefs.edit()
                .putString("${PRIVATE_KEY_KEY}_0", currentPriv)
                .putString("${PUBLIC_KEY_KEY}_0", currentPub)
                .apply()
            
            // Clean up oldest archive
            securePrefs.edit()
                .remove("${PRIVATE_KEY_KEY}_${MAX_KEY_VERSIONS}")
                .remove("${PUBLIC_KEY_KEY}_${MAX_KEY_VERSIONS}")
                .apply()
        }
    }
    
    /**
     * تحقق مما إذا كان يجب تدوير المفاتيح (24 ساعة)
     */
    fun shouldRotateKeys(): Boolean {
        val lastGeneration = securePrefs.getLong(KEY_GENERATION_DATE_KEY, 0)
        val timeSinceLastRotation = System.currentTimeMillis() - lastGeneration
        return timeSinceLastRotation > KEY_ROTATION_INTERVAL_MS
    }
    
    /**
     * تدوير المفاتيح إذا كان الوقت قد حان (24 ساعة)
     */
    fun rotateKeysIfNeeded(): Boolean {
        if (shouldRotateKeys()) {
            Log.i(TAG, "Rotating keys for Perfect Forward Secrecy")
            generateAndSaveKeyPair()
            return true
        }
        return false
    }
    
    /**
     * الحصول على مفتاح قديم للفك (للرسائل المستلمة قبل التدوير)
     */
    fun getArchivedPrivateKey(version: Int): ByteArray? {
        val keyBase64 = securePrefs.getString("${PRIVATE_KEY_KEY}_$version", null) ?: return null
        return Base64.decode(keyBase64, Base64.DEFAULT)
    }
    
    /**
     * الحصول على المفتاح العام القديم
     */
    fun getArchivedPublicKey(version: Int): ByteArray? {
        val keyBase64 = securePrefs.getString("${PUBLIC_KEY_KEY}_$version", null) ?: return null
        return Base64.decode(keyBase64, Base64.DEFAULT)
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
