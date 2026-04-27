package org.sada.messenger.data.models

import org.json.JSONArray
import org.json.JSONObject
import org.sada.messenger.utils.DateUtils
import java.security.MessageDigest
import java.util.*

/**
 * MeshMessage — the core unit of mesh communication.
 *
 * SECURITY: On the wire, sender and recipient are transmitted as SHA-256 hashes.
 * The actual sender ID is embedded inside the encrypted content envelope,
 * so only the intended recipient can identify who sent the message.
 */
data class MeshMessage(
    val messageId: String,
    val originalSenderId: String,       // Full ID — used locally, NEVER sent on wire
    val finalDestinationId: String,     // Full ID — used locally, NEVER sent on wire
    val encryptedContent: String,
    val hopCount: Int = 0,
    val maxHops: Int = 10,
    val trace: List<String> = emptyList(),
    val timestamp: Date = Date(),
    val type: String? = null,
    val metadata: Map<String, Any>? = null,
    val remainingTtlMs: Long? = null // Relative TTL for clock-skew resilience
) {
    companion object {
        const val TYPE_CONTACT_EXCHANGE = "CONTACT_EXCHANGE"
        const val TYPE_ACK = "ACK"
        const val TYPE_VOICE = "VOICE"
        const val TYPE_CONNECTION_REQUEST = "CONNECTION_REQUEST"
        const val TYPE_CONNECTION_ACCEPT = "CONNECTION_ACCEPT"
        const val TYPE_STATUS_UPDATE = "STATUS_UPDATE"

        fun sha256(input: String): String {
            val digest = MessageDigest.getInstance("SHA-256")
            val hash = digest.digest(input.toByteArray(Charsets.UTF_8))
            return hash.joinToString("") { "%02x".format(it) }
        }

        /**
         * Parse from wire format (hashed IDs).
         * On the wire we have senderIdHash and recipientIdHash.
         * The actual IDs must be resolved by the recipient after decryption.
         */
        fun fromJson(json: JSONObject): MeshMessage {
            val traceList = mutableListOf<String>()
            val traceArray = json.optJSONArray("trace")
            if (traceArray != null) {
                for (i in 0 until traceArray.length()) {
                    traceList.add(traceArray.getString(i))
                }
            }

            val metadataMap = mutableMapOf<String, Any>()
            val metaJson = json.optJSONObject("metadata")
            if (metaJson != null) {
                val keys = metaJson.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    metadataMap[key] = metaJson.get(key)
                }
            }

            val timestampStr = json.optString("timestamp")
            val date = try {
                if (timestampStr.isNotEmpty()) {
                    DateUtils.parseIso(timestampStr)
                } else {
                    Date(json.optLong("timestamp", System.currentTimeMillis()))
                }
            } catch (e: Exception) {
                Date(json.optLong("timestamp", System.currentTimeMillis()))
            }

            // Wire format uses hashed IDs — store them as-is for relay nodes.
            // The actual sender/recipient IDs will be "unknown" until decrypted.
            val senderIdHash = json.optString("senderIdHash", "")
            val recipientIdHash = json.optString("recipientIdHash", "")

            // Backward compatibility: if old-style fields exist, use them
            val senderId = json.optString("originalSenderId", senderIdHash)
            val recipientId = json.optString("finalDestinationId", recipientIdHash)

            return MeshMessage(
                messageId = json.getString("messageId"),
                originalSenderId = senderId,
                finalDestinationId = recipientId,
                encryptedContent = json.getString("encryptedContent"),
                hopCount = json.optInt("hopCount", 0),
                maxHops = json.optInt("maxHops", 10),
                trace = traceList,
                timestamp = date,
                type = json.optString("type", null),
                metadata = if (metadataMap.isEmpty()) null else metadataMap,
                remainingTtlMs = if (json.has("remainingTtlMs")) json.getLong("remainingTtlMs") else null
            )
        }

        fun fromJsonString(jsonStr: String): MeshMessage = fromJson(JSONObject(jsonStr))
    }

    /**
     * Serialize to wire format.
     * SECURITY: Uses SHA-256 hashes of sender/recipient IDs — never plaintext.
     * Relay nodes see only hashes + encrypted content.
     */
    fun toJson(): JSONObject {
        val json = JSONObject()
        json.put("messageId", messageId)
        // Wire format: only hashes — never plaintext IDs
        json.put("senderIdHash", sha256(originalSenderId))
        json.put("recipientIdHash", sha256(finalDestinationId))
        json.put("encryptedContent", encryptedContent)
        json.put("hopCount", hopCount)
        json.put("maxHops", maxHops)
        // Hash trace entries too so relay path is not linkable to identities
        val hashedTrace = trace.map { sha256(it) }
        json.put("trace", JSONArray(hashedTrace))
        json.put("timestamp", DateUtils.formatIso(timestamp))
        json.put("type", type)
        if (metadata != null) {
            json.put("metadata", JSONObject(metadata))
        }
        if (remainingTtlMs != null) {
            json.put("remainingTtlMs", remainingTtlMs)
        }
        return json
    }

    fun toJsonString(): String = toJson().toString()

    fun addHop(deviceId: String): MeshMessage {
        return copy(
            hopCount = hopCount + 1,
            trace = trace + deviceId
        )
    }

    fun isValid(myDeviceId: String): Boolean {
        if (hopCount >= maxHops) return false
        // Check trace using hashes (wire format) or plaintext (local)
        if (trace.contains(myDeviceId)) return false
        if (trace.contains(sha256(myDeviceId))) return false

        val ageMs = System.currentTimeMillis() - timestamp.time
        
        // If remainingTtlMs is provided, use it as the primary expiration source
        if (remainingTtlMs != null) {
            if (remainingTtlMs <= 0) return false
        } else {
            // Fallback to absolute timestamp if remainingTtlMs is missing
            if (ageMs > 24 * 60 * 60 * 1000) return false // 24 hours
        }

        return true
    }

    /**
     * Check if this message is intended for the given device.
     * Works with both hashed wire format and plaintext local format.
     */
    fun isForMe(myDeviceId: String): Boolean {
        return finalDestinationId == myDeviceId ||
               finalDestinationId == sha256(myDeviceId)
    }

    fun isFromMe(myDeviceId: String): Boolean {
        return originalSenderId == myDeviceId ||
               originalSenderId == sha256(myDeviceId)
    }
}
