package org.sada.messenger.data.models

import org.json.JSONArray
import org.json.JSONObject
import java.util.Date
import org.sada.messenger.utils.DateUtils

/**
 * نموذج رسالة Mesh مع routing metadata
 */
data class MeshMessage(
    val messageId: String,
    val originalSenderId: String,
    val finalDestinationId: String,
    val encryptedContent: String,
    val hopCount: Int = 0,
    val maxHops: Int = 10,
    val trace: List<String> = emptyList(),
    val timestamp: Date = Date(),
    val type: String? = null,
    val metadata: Map<String, Any>? = null
) {
    companion object {
        const val TYPE_CONTACT_EXCHANGE = "CONTACT_EXCHANGE"
        const val TYPE_ACK = "ACK"

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

            return MeshMessage(
                messageId = json.getString("messageId"),
                originalSenderId = json.getString("originalSenderId"),
                finalDestinationId = json.getString("finalDestinationId"),
                encryptedContent = json.getString("encryptedContent"),
                hopCount = json.optInt("hopCount", 0),
                maxHops = json.optInt("maxHops", 10),
                trace = traceList,
                timestamp = date,
                type = json.optString("type", null),
                metadata = if (metadataMap.isEmpty()) null else metadataMap
            )
        }

        fun fromJsonString(jsonStr: String): MeshMessage = fromJson(JSONObject(jsonStr))
    }

    fun toJson(): JSONObject {
        val json = JSONObject()
        json.put("messageId", messageId)
        json.put("originalSenderId", originalSenderId)
        json.put("finalDestinationId", finalDestinationId)
        json.put("encryptedContent", encryptedContent)
        json.put("hopCount", hopCount)
        json.put("maxHops", maxHops)
        json.put("trace", JSONArray(trace))
        json.put("timestamp", DateUtils.formatIso(timestamp))
        json.put("type", type)
        if (metadata != null) {
            json.put("metadata", JSONObject(metadata))
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
        if (trace.contains(myDeviceId)) return false
        
        val ageMs = System.currentTimeMillis() - timestamp.time
        if (ageMs > 24 * 60 * 60 * 1000) return false // 24 hours
        
        return true
    }

    fun isForMe(myDeviceId: String): Boolean = finalDestinationId == myDeviceId
    fun isFromMe(myDeviceId: String): Boolean = originalSenderId == myDeviceId
}
