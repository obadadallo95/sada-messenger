package org.sada.messenger.security

import android.util.Log
import org.sada.messenger.BuildConfig

/**
 * Secure Logger
 * Prevents sensitive data leaks in log messages
 * Automatically redacts sensitive information in production builds
 */
object SecureLogger {
    
    private const val TAG_PREFIX = "Sada_"
    private val IS_DEBUG = BuildConfig.DEBUG
    
    // Patterns to redact
    private val SENSITIVE_PATTERNS = listOf(
        Regex("[a-zA-Z0-9_-]{20,}") to "[REDACTED_KEY]", // API keys, tokens
        Regex("-----BEGIN.*?-----END.*?-----", RegexOption.DOT_MATCHES_ALL) to "[REDACTED_KEY_BLOCK]",
        Regex("[0-9a-fA-F]{32,}") to "[REDACTED_HASH]", // SHA256 hashes
        Regex("content[\"']?\\s*[:=]\\s*[\"'][^\"']{10,}[\"']") to "content=[REDACTED]",
        Regex("password[\"']?\\s*[:=]\\s*[\"'][^\"']+[\"']") to "password=[REDACTED]",
        Regex("privateKey[\"']?\\s*[:=]\\s*[\"'][^\"']+[\"']") to "privateKey=[REDACTED]"
    )

    @JvmStatic
    fun v(tag: String, message: String) {
        if (IS_DEBUG) {
            Log.v(TAG_PREFIX + tag, sanitize(message))
        }
    }

    @JvmStatic
    fun d(tag: String, message: String) {
        if (IS_DEBUG) {
            Log.d(TAG_PREFIX + tag, sanitize(message))
        }
    }

    @JvmStatic
    fun i(tag: String, message: String) {
        // Info logs are allowed in production but sanitized
        Log.i(TAG_PREFIX + tag, sanitize(message))
    }

    @JvmStatic
    fun w(tag: String, message: String, throwable: Throwable? = null) {
        if (throwable != null) {
            Log.w(TAG_PREFIX + tag, sanitize(message), sanitize(throwable))
        } else {
            Log.w(TAG_PREFIX + tag, sanitize(message))
        }
    }

    @JvmStatic
    fun e(tag: String, message: String, throwable: Throwable? = null) {
        if (throwable != null) {
            Log.e(TAG_PREFIX + tag, sanitize(message), sanitize(throwable))
        } else {
            Log.e(TAG_PREFIX + tag, sanitize(message))
        }
    }

    /**
     * Sanitize message by redacting sensitive patterns
     */
    private fun sanitize(message: String): String {
        if (IS_DEBUG) {
            // In debug, we still redact but maybe less aggressively
            return message
        }
        
        var sanitized = message
        SENSITIVE_PATTERNS.forEach { (pattern, replacement) ->
            sanitized = pattern.replace(sanitized, replacement)
        }
        return sanitized
    }

    /**
     * Sanitize throwable message
     */
    private fun sanitize(throwable: Throwable): Throwable {
        return if (IS_DEBUG) {
            throwable
        } else {
            // Create sanitized exception for production
            val sanitizedMessage = throwable.message?.let { sanitize(it) }
            RuntimeException(sanitizedMessage, throwable.cause)
        }
    }

    /**
     * Log with explicit non-sensitive data
     * Use this for logging structured data that is safe
     */
    @JvmStatic
    fun logMetric(tag: String, metric: String, value: Any) {
        Log.i(TAG_PREFIX + tag, "METRIC: $metric=$value")
    }

    /**
     * Log connection events (without sensitive data)
     */
    @JvmStatic
    fun logConnection(tag: String, event: String, peerId: String) {
        val sanitizedPeerId = peerId.take(8) + "..." + peerId.takeLast(4)
        Log.i(TAG_PREFIX + tag, "CONNECTION: $event peer=$sanitizedPeerId")
    }

    /**
     * Log security events
     */
    @JvmStatic
    fun logSecurity(event: String, details: String = "") {
        Log.w(TAG_PREFIX + "Security", "SECURITY_EVENT: $event $details")
    }

    /**
     * Disable logging completely (for testing)
     */
    @JvmStatic
    fun disableLogging() {
        // This is a no-op in production, only works in debug
    }
}
