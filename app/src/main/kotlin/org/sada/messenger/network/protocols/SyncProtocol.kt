package org.sada.messenger.network.protocols

import org.json.JSONArray
import org.json.JSONObject
import java.util.*

/**
 * Handles Peer-to-Peer Synchronization of group history.
 * When a user joins a group or enters a chat, they can request the last N messages
 * from neighbors to fill their local timeline.
 */
class SyncProtocol {
    companion object {
        const val TYPE_SYNC_REQUEST = "SYNC_REQUEST"
        const val TYPE_SYNC_RESPONSE = "SYNC_RESPONSE"
    }

    /**
     * Create a request for group history
     */
    fun createSyncRequest(groupId: String, limit: Int = 50): JSONObject {
        return JSONObject().apply {
            put("type", TYPE_SYNC_REQUEST)
            put("groupId", groupId)
            put("limit", limit)
            put("timestamp", Date().time)
        }
    }

    /**
     * Create a response containing historical messages (still encrypted with group key)
     */
    fun createSyncResponse(groupId: String, encryptedMessages: JSONArray): JSONObject {
        return JSONObject().apply {
            put("type", TYPE_SYNC_RESPONSE)
            put("groupId", groupId)
            put("messages", encryptedMessages)
            put("timestamp", Date().time)
        }
    }
}
