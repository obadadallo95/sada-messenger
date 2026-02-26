package org.sada.messenger.security

import android.util.Base64
import android.util.Log
import com.goterl.lazysodium.LazySodiumAndroid
import com.goterl.lazysodium.SodiumAndroid
import com.goterl.lazysodium.interfaces.Box
import com.goterl.lazysodium.interfaces.GenericHash
import com.goterl.lazysodium.interfaces.SecretBox
import com.goterl.lazysodium.utils.Key
import java.nio.charset.StandardCharsets

/**
 * مدير التشفير
 * يتعامل مع التشفير وفك التشفير باستخدام libsodium
 */
class EncryptionManager(private val keyManager: KeyManager) {
    companion object {
        private const val TAG = "SadaEncryption"
        private const val DERIVATION_CONTEXT = "sada-e2e-session-key-v1"
        private const val NONCE_BYTES = SecretBox.NONCEBYTES // 24 bytes
    }

    private val lazySodium = LazySodiumAndroid(SodiumAndroid())

    /**
     * حساب السر المشترك (Shared Secret) باستخدام ECDH
     */
    fun calculateSharedSecret(remotePublicKey: ByteArray): ByteArray {
        try {
            val myPrivateKey = keyManager.getKeyPair().secretKey.asBytes
            
            // crypto_scalarmult: Perform ECDH
            val sharedSecret = ByteArray(Box.PUBLICKEYBYTES)
            val success = lazySodium.cryptoScalarMult(
                sharedSecret,
                myPrivateKey,
                remotePublicKey
            )
            
            if (!success) {
                throw SecurityException("Failed to calculate shared secret (ECDH)")
            }

            // KDF: Blake2b(sharedSecret + context)
            val contextBytes = DERIVATION_CONTEXT.toByteArray(StandardCharsets.UTF_8)
            val keyMaterial = sharedSecret + contextBytes
            
            val sessionKey = ByteArray(SecretBox.KEYBYTES) // 32 bytes
            lazySodium.cryptoGenericHash(
                sessionKey,
                SecretBox.KEYBYTES,
                keyMaterial,
                keyMaterial.size.toLong(),
                null,
                0
            )

            Log.d(TAG, "Shared secret derived successfully")
            return sessionKey
        } catch (e: Exception) {
            Log.e(TAG, "Error calculating shared secret", e)
            throw e
        }
    }

    /**
     * تشفير رسالة
     * Returns: Base64 string (Nonce + CipherText)
     */
    fun encryptMessage(plainText: String, sharedKey: ByteArray): String {
        try {
            val plainBytes = plainText.toByteArray(StandardCharsets.UTF_8)
            val nonce = lazySodium.randomBytesBuf(NONCE_BYTES)
            
            val cipherText = ByteArray(plainBytes.size + SecretBox.MACBYTES)
            val success = lazySodium.cryptoSecretBoxEasy(
                cipherText,
                plainBytes,
                plainBytes.size.toLong(),
                nonce,
                sharedKey
            )

            if (!success) {
                throw SecurityException("Encryption failed")
            }

            // Combine Nonce + CipherText
            val combined = nonce + cipherText
            return Base64.encodeToString(combined, Base64.DEFAULT)
        } catch (e: Exception) {
            Log.e(TAG, "Error encrypting message", e)
            throw e
        }
    }

    /**
     * فك تشفير رسالة
     */
    fun decryptMessage(encryptedPayload: String, sharedKey: ByteArray): String {
        try {
            val combined = Base64.decode(encryptedPayload, Base64.DEFAULT)
            
            if (combined.size < NONCE_BYTES + SecretBox.MACBYTES) {
                throw IllegalArgumentException("Payload too short")
            }

            val nonce = combined.sliceArray(0 until NONCE_BYTES)
            val cipherText = combined.sliceArray(NONCE_BYTES until combined.size)
            
            val decrypted = ByteArray(cipherText.size - SecretBox.MACBYTES)
            val success = lazySodium.cryptoSecretBoxOpenEasy(
                decrypted,
                cipherText,
                cipherText.size.toLong(),
                nonce,
                sharedKey
            )

            if (!success) {
                throw SecurityException("Decryption failed (MAC verification error)")
            }

            return String(decrypted, StandardCharsets.UTF_8)
        } catch (e: Exception) {
            Log.e(TAG, "Error decrypting message", e)
            throw e
        }
    }
    /**
     * Encrypt with a shared symmetric key (XSalsa20)
     */
    fun encryptWithSharedKey(plainText: String, groupKeyBase64: String): String {
        return try {
            val key = Base64.decode(groupKeyBase64, Base64.NO_WRAP)
            encryptMessage(plainText, key)
        } catch (e: Exception) {
            Log.e(TAG, "Error in group encryption", e)
            ""
        }
    }

    /**
     * Decrypt with a shared symmetric key (XSalsa20)
     */
    fun decryptWithSharedKey(encryptedPayload: String, groupKeyBase64: String): String? {
        return try {
            val key = Base64.decode(groupKeyBase64, Base64.NO_WRAP)
            decryptMessage(encryptedPayload, key)
        } catch (e: Exception) {
            Log.e(TAG, "Error in group decryption", e)
            null
        }
    }
}
