package org.sada.messenger.security

import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.data.entities.MessageEntity
import java.security.MessageDigest
import java.security.PublicKey
import android.util.Base64
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Security Validator
 * Validates messages and protects against various attacks:
 * - Replay attacks
 * - Impersonation
 * - Message tampering
 * - Rate limiting
 */
@Singleton
class SecurityValidator @Inject constructor(
    private val database: AppDatabase,
    private val keyManager: SecureKeyManager
) {
    companion object {
        private const val TAG = "SecurityValidator"
        
        // Rate limiting constants
        private const val MAX_MESSAGES_PER_MINUTE = 30
        private const val MAX_MESSAGES_PER_HOUR = 300
        private const val MAX_MESSAGE_SIZE = 512 * 1024 // 512KB
        
        // Replay prevention window (24 hours)
        private const val REPLAY_WINDOW_MS = 24 * 60 * 60 * 1000L
    }

    private val messageRateLimiter = MessageRateLimiter()
    private val processedMessageIds = Collections.synchronizedSet<String>(LinkedHashSet())

    /**
     * Validate incoming message
     * Returns true if message is safe to process
     */
    suspend fun validateMessage(
        message: MessageEntity,
        senderPublicKey: PublicKey? = null
    ): ValidationResult = withContext(Dispatchers.IO) {
        try {
            // 1. Check message size
            if (!validateMessageSize(message)) {
                return@withContext ValidationResult.Failure(
                    ValidationError.MESSAGE_TOO_LARGE,
                    "Message exceeds maximum size"
                )
            }
            
            // 2. Check replay (duplicate message ID)
            if (!validateNoReplay(message.id)) {
                return@withContext ValidationResult.Failure(
                    ValidationError.REPLAY_ATTACK,
                    "Duplicate message detected"
                )
            }
            
            // 3. Check rate limiting
            if (!validateRateLimit(message.senderId)) {
                return@withContext ValidationResult.Failure(
                    ValidationError.RATE_LIMIT_EXCEEDED,
                    "Rate limit exceeded"
                )
            }
            
            // 4. Check timestamp (prevent old message replay)
            if (!validateTimestamp(message.timestamp)) {
                return@withContext ValidationResult.Failure(
                    ValidationError.OLD_MESSAGE,
                    "Message timestamp too old"
                )
            }
            
            // 5. Verify sender identity (if public key provided)
            if (senderPublicKey != null) {
                if (!validateSenderIdentity(message.senderId, senderPublicKey)) {
                    return@withContext ValidationResult.Failure(
                        ValidationError.INVALID_IDENTITY,
                        "Sender identity verification failed"
                    )
                }
            }
            
            // 6. Check if sender is banned
            if (validateSenderNotBanned(message.chatId, message.senderId)) {
                return@withContext ValidationResult.Failure(
                    ValidationError.SENDER_BANNED,
                    "Sender is banned from this chat"
                )
            }
            
            // All checks passed
            ValidationResult.Success
            
        } catch (e: Exception) {
            Log.e(TAG, "Validation error", e)
            ValidationResult.Failure(
                ValidationError.INTERNAL_ERROR,
                "Validation error: ${e.message}"
            )
        }
    }

    /**
     * Validate message size
     */
    private fun validateMessageSize(message: MessageEntity): Boolean {
        val contentSize = message.content.toByteArray(Charsets.UTF_8).size
        return contentSize <= MAX_MESSAGE_SIZE
    }

    /**
     * Check for replay attacks (duplicate message IDs)
     */
    private fun validateNoReplay(messageId: String): Boolean {
        if (processedMessageIds.contains(messageId)) {
            return false
        }
        
        // Add to processed set
        processedMessageIds.add(messageId)
        
        // Clean old entries if set is too large
        if (processedMessageIds.size > 10000) {
            val iterator = processedMessageIds.iterator()
            var count = 0
            while (iterator.hasNext() && count < 1000) {
                iterator.next()
                iterator.remove()
                count++
            }
        }
        
        return true
    }

    /**
     * Rate limiting per sender
     */
    private fun validateRateLimit(senderId: String): Boolean {
        return messageRateLimiter.allowRequest(senderId)
    }

    /**
     * Validate message timestamp (not too old, not from future)
     */
    private fun validateTimestamp(timestamp: Date): Boolean {
        val now = System.currentTimeMillis()
        val messageTime = timestamp.time
        
        // Check if message is too old (replay window)
        if (now - messageTime > REPLAY_WINDOW_MS) {
            return false
        }
        
        // Check if message is from the future (more than 1 minute)
        if (messageTime > now + 60000) {
            return false
        }
        
        return true
    }

    /**
     * Validate sender identity matches public key
     */
    private fun validateSenderIdentity(
        senderId: String,
        publicKey: PublicKey
    ): Boolean {
        // Calculate expected senderId from public key (hash)
        val publicKeyHash = MessageDigest.getInstance("SHA-256").digest(publicKey.encoded)
        val expectedSenderId = Base64.encodeToString(publicKeyHash, Base64.NO_WRAP)
        
        return senderId == expectedSenderId || senderId.take(16) == expectedSenderId.take(16)
    }

    /**
     * Check if sender is banned from the chat
     */
    private suspend fun validateSenderNotBanned(
        chatId: String,
        senderId: String
    ): Boolean {
        return try {
            val member = database.groupDao().getMember(chatId, senderId)
            member?.role == "banned"
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Verify message signature
     */
    fun verifyMessageSignature(
        message: MessageEntity,
        signature: ByteArray,
        senderPublicKey: PublicKey
    ): Boolean {
        val dataToVerify = buildString {
            append(message.id)
            append(message.chatId)
            append(message.senderId)
            append(message.content)
            append(message.timestamp.time)
        }.toByteArray(Charsets.UTF_8)
        
        return keyManager.verify(dataToVerify, signature, senderPublicKey)
    }

    /**
     * Calculate message hash for integrity verification
     */
    fun calculateMessageHash(message: MessageEntity): String {
        val data = buildString {
            append(message.id)
            append(message.chatId)
            append(message.senderId)
            append(message.content)
            append(message.timestamp.time)
        }.toByteArray(Charsets.UTF_8)
        
        val digest = MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(data)
        return Base64.encodeToString(hash, Base64.NO_WRAP)
    }

    /**
     * Validation result sealed class
     */
    sealed class ValidationResult {
        object Success : ValidationResult()
        data class Failure(
            val error: ValidationError,
            val message: String
        ) : ValidationResult()
    }

    /**
     * Validation error types
     */
    enum class ValidationError {
        MESSAGE_TOO_LARGE,
        REPLAY_ATTACK,
        RATE_LIMIT_EXCEEDED,
        OLD_MESSAGE,
        INVALID_IDENTITY,
        SENDER_BANNED,
        SIGNATURE_INVALID,
        INTERNAL_ERROR
    }

    /**
     * Rate limiter for message validation
     */
    private inner class MessageRateLimiter {
        private val requestCounts = Collections.synchronizedMap<String, MutableList<Long>>(LinkedHashMap())

        fun allowRequest(senderId: String): Boolean {
            val now = System.currentTimeMillis()
            
            synchronized(requestCounts) {
                val timestamps = requestCounts.getOrPut(senderId) { mutableListOf() }
                
                // Remove old entries (older than 1 hour)
                timestamps.removeAll { now - it > 60 * 60 * 1000 }
                
                // Check per-minute limit
                val recentRequests = timestamps.count { now - it < 60 * 1000 }
                if (recentRequests >= MAX_MESSAGES_PER_MINUTE) {
                    return false
                }
                
                // Check per-hour limit
                if (timestamps.size >= MAX_MESSAGES_PER_HOUR) {
                    return false
                }
                
                // Record this request
                timestamps.add(now)
                
                // Cleanup old entries from map
                if (requestCounts.size > 1000) {
                    val iterator = requestCounts.entries.iterator()
                    while (iterator.hasNext() && requestCounts.size > 900) {
                        iterator.next()
                        iterator.remove()
                    }
                }
                
                return true
            }
        }
    }
}
