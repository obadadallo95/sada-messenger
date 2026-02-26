package org.sada.messenger.network.protocols

import android.util.Base64
import org.json.JSONObject
import java.io.File

/**
 * MediaProtocol
 * Handles chunking large files (Images/Audio/Video) for transmission
 * over the mesh network (MTU restricted LoRa/WiFi).
 */
class MediaProtocol {
    companion object {
        const val TYPE_MEDIA_HEADER = "MEDIA_HEADER"
        const val TYPE_MEDIA_CHUNK = "MEDIA_CHUNK"
        
        // LoRa effective MTU after mesh headers is ~150-180 bytes
        // We'll use 1KB chunks for WiFi/UDP and let LoraPacketizer handle 
        // the further sub-fragmentation for LoRa specifically.
        const val CHUNK_SIZE = 1024 * 4 // 4KB chunks for initial protocol
    }

    fun createHeader(
        messageId: String,
        fileName: String,
        fileSize: Long,
        chunkCount: Int,
        mimeType: String
    ): JSONObject {
        return JSONObject().apply {
            put("type", TYPE_MEDIA_HEADER)
            put("messageId", messageId)
            put("fileName", fileName)
            put("fileSize", fileSize)
            put("chunkCount", chunkCount)
            put("mimeType", mimeType)
        }
    }

    fun createChunk(
        messageId: String,
        chunkIndex: Int,
        data: ByteArray
    ): JSONObject {
        return JSONObject().apply {
            put("type", TYPE_MEDIA_CHUNK)
            put("messageId", messageId)
            put("chunkIndex", chunkIndex)
            put("data", Base64.encodeToString(data, Base64.NO_WRAP))
        }
    }
}
