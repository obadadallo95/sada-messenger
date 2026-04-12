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
        
        // Metadata Padding: Hide message sizes by padding to fixed buckets
        private val PADDING_BUCKETS = intArrayOf(64, 128, 256, 512, 1024, 2048, 4096)
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
     * Encrypt raw bytes with shared key.
     * Returns: nonce + cipher bytes.
     */
    fun encryptBytes(plainBytes: ByteArray, sharedKey: ByteArray): ByteArray {
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
            throw SecurityException("Byte encryption failed")
        }
        return nonce + cipherText
    }

    /**
     * Decrypt raw bytes encrypted by [encryptBytes].
     */
    fun decryptBytes(encryptedPayload: ByteArray, sharedKey: ByteArray): ByteArray {
        if (encryptedPayload.size < NONCE_BYTES + SecretBox.MACBYTES) {
            throw IllegalArgumentException("Encrypted bytes payload too short")
        }
        val nonce = encryptedPayload.sliceArray(0 until NONCE_BYTES)
        val cipherText = encryptedPayload.sliceArray(NONCE_BYTES until encryptedPayload.size)
        val plain = ByteArray(cipherText.size - SecretBox.MACBYTES)
        val success = lazySodium.cryptoSecretBoxOpenEasy(
            plain,
            cipherText,
            cipherText.size.toLong(),
            nonce,
            sharedKey
        )
        if (!success) {
            throw SecurityException("Byte decryption failed (MAC verification)")
        }
        return plain
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
    
    /**
     * Metadata Padding: Pads plaintext to hide actual message size.
     * Makes all messages look similar in size to prevent traffic analysis.
     * Format: [OriginalLength (2 bytes)][OriginalData][Padding (random)]
     */
    fun addPadding(plainBytes: ByteArray): ByteArray {
        val targetSize = calculatePaddedSize(plainBytes.size + 2) // +2 for length header
        
        if (targetSize <= plainBytes.size + 2) {
            // No padding needed, just add length header
            val result = ByteArray(plainBytes.size + 2)
            result[0] = (plainBytes.size shr 8).toByte()
            result[1] = plainBytes.size.toByte()
            System.arraycopy(plainBytes, 0, result, 2, plainBytes.size)
            return result
        }
        
        val paddingSize = targetSize - plainBytes.size - 2
        val result = ByteArray(targetSize)
        
        // Add length header
        result[0] = (plainBytes.size shr 8).toByte()
        result[1] = plainBytes.size.toByte()
        
        // Copy original data
        System.arraycopy(plainBytes, 0, result, 2, plainBytes.size)
        
        // Add random padding
        val padding = lazySodium.randomBytesBuf(paddingSize)
        System.arraycopy(padding, 0, result, 2 + plainBytes.size, paddingSize)
        
        return result
    }
    
    /**
     * Remove padding added by [addPadding].
     */
    fun removePadding(paddedBytes: ByteArray): ByteArray {
        if (paddedBytes.size < 2) {
            throw IllegalArgumentException("Padded data too short")
        }
        
        val originalLength = ((paddedBytes[0].toInt() and 0xFF) shl 8) or 
                            (paddedBytes[1].toInt() and 0xFF)
        
        if (originalLength > paddedBytes.size - 2) {
            throw IllegalArgumentException("Invalid padding length")
        }
        
        return paddedBytes.sliceArray(2 until 2 + originalLength)
    }
    
    /**
     * Calculate the padded size for a given input size.
     * Rounds up to the next bucket size.
     */
    private fun calculatePaddedSize(inputSize: Int): Int {
        for (bucket in PADDING_BUCKETS) {
            if (bucket >= inputSize) {
                return bucket
            }
        }
        return PADDING_BUCKETS.last() // Use largest bucket if input is too large
    }
    
    /**
     * Encrypt message with padding to hide size metadata.
     * Use this for chat messages to prevent traffic analysis.
     */
    fun encryptMessageWithPadding(plainText: String, sharedKey: ByteArray): String {
        val paddedBytes = addPadding(plainText.toByteArray(StandardCharsets.UTF_8))
        val encrypted = encryptBytes(paddedBytes, sharedKey)
        return Base64.encodeToString(encrypted, Base64.NO_WRAP)
    }
    
    /**
     * Decrypt message that was encrypted with padding.
     */
    fun decryptMessageWithPadding(encryptedBase64: String, sharedKey: ByteArray): String? {
        return try {
            val encrypted = Base64.decode(encryptedBase64, Base64.NO_WRAP)
            val paddedBytes = decryptBytes(encrypted, sharedKey)
            val originalBytes = removePadding(paddedBytes)
            String(originalBytes, StandardCharsets.UTF_8)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to decrypt padded message", e)
            null
        }
    }
}
