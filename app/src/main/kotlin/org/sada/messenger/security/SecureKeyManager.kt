package org.sada.messenger.security

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.security.*
import java.security.spec.ECGenParameterSpec
import java.security.spec.PKCS8EncodedKeySpec
import java.security.spec.X509EncodedKeySpec
import javax.crypto.KeyAgreement
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Secure Key Manager using Android Keystore
 * Stores private keys securely in hardware-backed keystore (TEE/StrongBox if available)
 */
@Singleton
class SecureKeyManager @Inject constructor(
    private val context: Context
) {
    companion object {
        private const val TAG = "SecureKeyManager"
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val KEY_ALIAS = "sada_identity_key"
        private const val MASTER_KEY_ALIAS = "sada_master_key"
        private const val EC_CURVE = "secp256r1" // NIST P-256
    }

    private val keyStore: KeyStore by lazy {
        KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
    }

    /**
     * Initialize identity key pair
     * Generates ECDH key pair in Android Keystore
     */
    suspend fun initialize(): Boolean = withContext(Dispatchers.IO) {
        try {
            if (!keyStore.containsAlias(KEY_ALIAS)) {
                generateIdentityKeyPair()
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize key manager", e)
            false
        }
    }

    /**
     * Generate identity key pair in Android Keystore
     */
    private fun generateIdentityKeyPair() {
        val keyPairGenerator = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC,
            ANDROID_KEYSTORE
        )

        val builder = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        )
            .setAlgorithmParameterSpec(ECGenParameterSpec(EC_CURVE))
            .setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA512)
            .setUserAuthenticationRequired(false)

        // Use StrongBox if available (dedicated hardware security chip)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            builder.setIsStrongBoxBacked(true)
        }

        keyPairGenerator.initialize(builder.build())
        keyPairGenerator.generateKeyPair()

        Log.i(TAG, "Identity key pair generated successfully")
    }

    /**
     * Get public key for sharing with others
     */
    fun getPublicKey(): PublicKey? {
        return try {
            val entry = keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.PrivateKeyEntry
            entry?.certificate?.publicKey
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get public key", e)
            null
        }
    }

    /**
     * Get public key as Base64 string
     */
    fun getPublicKeyBase64(): String? {
        return getPublicKey()?.encoded?.let {
            Base64.encodeToString(it, Base64.NO_WRAP)
        }
    }

    /**
     * Get private key for signing/encryption operations
     * Note: Private key NEVER leaves Android Keystore
     */
    fun getPrivateKey(): PrivateKey? {
        return try {
            val entry = keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.PrivateKeyEntry
            entry?.privateKey
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get private key", e)
            null
        }
    }

    /**
     * Sign data with private key
     * Used for message authentication
     */
    fun sign(data: ByteArray): ByteArray? {
        return try {
            val privateKey = getPrivateKey() ?: return null
            val signature = Signature.getInstance("SHA256withECDSA")
            signature.initSign(privateKey)
            signature.update(data)
            signature.sign()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to sign data", e)
            null
        }
    }

    /**
     * Verify signature with public key
     */
    fun verify(data: ByteArray, signature: ByteArray, publicKey: PublicKey): Boolean {
        return try {
            val sig = Signature.getInstance("SHA256withECDSA")
            sig.initVerify(publicKey)
            sig.update(data)
            sig.verify(signature)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to verify signature", e)
            false
        }
    }

    /**
     * Calculate shared secret using ECDH
     */
    fun calculateSharedSecret(peerPublicKey: PublicKey): ByteArray? {
        return try {
            val privateKey = getPrivateKey() ?: return null
            val keyAgreement = KeyAgreement.getInstance("ECDH")
            keyAgreement.init(privateKey)
            keyAgreement.doPhase(peerPublicKey, true)
            keyAgreement.generateSecret()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to calculate shared secret", e)
            null
        }
    }

    /**
     * Parse public key from Base64 string
     */
    fun parsePublicKey(base64PublicKey: String): PublicKey? {
        return try {
            val decoded = Base64.decode(base64PublicKey, Base64.NO_WRAP)
            val keySpec = X509EncodedKeySpec(decoded)
            val keyFactory = KeyFactory.getInstance("EC")
            keyFactory.generatePublic(keySpec)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse public key", e)
            null
        }
    }

    /**
     * Check if StrongBox is available (hardware security)
     */
    fun isStrongBoxAvailable(): Boolean {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            context.packageManager.hasSystemFeature(android.content.pm.PackageManager.FEATURE_STRONGBOX_KEYSTORE)
        } else {
            false
        }
    }

    /**
     * Check if TEE (Trusted Execution Environment) is available
     */
    fun isTeeAvailable(): Boolean {
        return context.packageManager.hasSystemFeature(
            android.content.pm.PackageManager.FEATURE_HARDWARE_KEYSTORE
        )
    }

    /**
     * Get key storage information
     */
    fun getKeyStorageInfo(): String {
        return when {
            isStrongBoxAvailable() -> "StrongBox (Hardware)"
            isTeeAvailable() -> "TEE (Hardware-backed)"
            else -> "Software Keystore"
        }
    }

    /**
     * Delete identity key (for key rotation or logout)
     */
    fun deleteIdentityKey(): Boolean {
        return try {
            keyStore.deleteEntry(KEY_ALIAS)
            Log.i(TAG, "Identity key deleted")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to delete identity key", e)
            false
        }
    }

    /**
     * Rotate identity key
     * Generates new key pair and returns old public key
     */
    fun rotateIdentityKey(): String? {
        val oldPublicKey = getPublicKeyBase64()
        deleteIdentityKey()
        generateIdentityKeyPair()
        return oldPublicKey
    }
}
