package org.sada.messenger.data.models

import org.json.JSONObject

data class VoiceMessageEnvelope(
    val messageId: String,
    val chatId: String,
    val senderId: String,
    val destinationId: String,
    val mimeType: String,
    val durationMs: Long,
    val totalChunks: Int,
    val checksumSha256: String,
    val createdAt: Long,
    val encrypted: Boolean
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("messageId", messageId)
        put("chatId", chatId)
        put("senderId", senderId)
        put("destinationId", destinationId)
        put("mimeType", mimeType)
        put("durationMs", durationMs)
        put("totalChunks", totalChunks)
        put("checksumSha256", checksumSha256)
        put("createdAt", createdAt)
        put("encrypted", encrypted)
    }

    companion object {
        fun fromJson(json: JSONObject): VoiceMessageEnvelope {
            return VoiceMessageEnvelope(
                messageId = json.getString("messageId"),
                chatId = json.getString("chatId"),
                senderId = json.getString("senderId"),
                destinationId = json.getString("destinationId"),
                mimeType = json.getString("mimeType"),
                durationMs = json.optLong("durationMs", 0L),
                totalChunks = json.getInt("totalChunks"),
                checksumSha256 = json.optString("checksumSha256", ""),
                createdAt = json.optLong("createdAt", System.currentTimeMillis()),
                encrypted = json.optBoolean("encrypted", false)
            )
        }
    }
}
