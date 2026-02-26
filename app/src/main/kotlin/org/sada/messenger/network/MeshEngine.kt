package org.sada.messenger.network

import android.content.Context
import android.util.Log
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONObject
import org.sada.messenger.SocketManager
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.data.entities.ChatEntity
import org.sada.messenger.data.entities.GroupMemberEntity
import org.sada.messenger.data.entities.MessageEntity
import org.sada.messenger.data.entities.RelayQueueEntity
import org.sada.messenger.data.models.MeshMessage
import org.sada.messenger.network.protocols.GroupProtocol
import org.sada.messenger.network.protocols.MediaProtocol
import org.sada.messenger.network.lora.LoraInterface
import org.sada.messenger.network.lora.LoraPacketizer
import org.sada.messenger.security.EncryptionManager
import org.sada.messenger.security.KeyManager
import org.sada.messenger.utils.BloomFilter
import org.sada.messenger.data.entities.MediaChunkEntity
import java.util.*
import org.sada.messenger.utils.DateUtils
import java.io.FileOutputStream
import java.io.File
import android.util.Base64

/**
 * المحرك الأساسي لشبكة المش (Mesh Engine)
 * يدير الاتصالات، المصافحة (Handshake)، وتوجيه الرسائل (Routing)
 */
class MeshEngine(
    private val context: Context,
    private val socketManager: SocketManager,
    private val database: AppDatabase,
    private val keyManager: KeyManager,
    private val encryptionManager: EncryptionManager,
    private val loraInterface: LoraInterface? = null
) {
    private val loraPacketizer = LoraPacketizer()
    private val groupProtocol = GroupProtocol(keyManager, encryptionManager)
    private val mediaProtocol = MediaProtocol()
    
    private val processedMessageIds = mutableSetOf<String>()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val _transportError = MutableStateFlow<String?>(null)
    val transportError: StateFlow<String?> = _transportError.asStateFlow()

    private var handshakeAttempts = 0
    private var handshakeAcks = 0
    private var handshakeTimeouts = 0
    private var lastSocketRemoteIp: String? = null

    companion object {
        const val TAG = "MeshEngine"
        const val HANDSHAKE_TYPE = "HANDSHAKE"
        const val HANDSHAKE_ACK_TYPE = "HANDSHAKE_ACK"
        const val STATUS_ACCEPTED = "ACCEPTED"
        const val STATUS_REJECTED = "REJECTED"
        const val TYPE_SOS = "SOS"
        const val SOS_MAX_HOPS = 15
    }

    private val _connectedPeers = MutableStateFlow<List<String>>(emptyList())
    val connectedPeers: StateFlow<List<String>> = _connectedPeers.asStateFlow()

    private val peerBloomFilters = mutableMapOf<String, BloomFilter>()

    init {
        setupSocketCallbacks()
        setupLoraCallbacks()
    }

    private fun setupLoraCallbacks() {
        loraInterface?.setOnDataReceived { data, rssi, snr ->
            val reassembled = loraPacketizer.reassemble(data)
            if (reassembled != null) {
                val jsonStr = String(reassembled, Charsets.UTF_8)
                handleIncomingJson(jsonStr, rssi, snr)
            }
        }
    }

    private fun setupSocketCallbacks() {
        socketManager.setOnMessageReceived { bytes ->
            handleIncomingData(bytes)
        }

        socketManager.setOnConnectionStatusChanged { status, message ->
            Log.d(TAG, "Socket Status Changed: $status - $message")
            if (status.equals("connected", ignoreCase = true) ||
                status.equals("CONNECTED", ignoreCase = true)
            ) {
                scope.launch { initiateHandshake() }
            }
        }
    }

    private fun handleIncomingData(bytes: ByteArray) {
        if (bytes.isEmpty()) return
        
        val frameType = bytes[0]
        val payload = bytes.sliceArray(1 until bytes.size)
        
        if (frameType == 0x00.toByte()) { // Text Frame
            val jsonStr = String(payload, Charsets.UTF_8)
            handleIncomingJson(jsonStr, null, null)
        }
    }

    private fun handleIncomingJson(jsonStr: String, rssi: Int?, snr: Double?) {
        try {
            val json = JSONObject(jsonStr)
            val type = json.optString("type")

            when (type) {
                HANDSHAKE_TYPE -> scope.launch { handleHandshake(json) }
                HANDSHAKE_ACK_TYPE -> scope.launch { handleHandshakeAck(json) }
                GroupProtocol.TYPE_GROUP_INVITE -> handleGroupInvite(json)
                GroupProtocol.TYPE_GROUP_MSG -> handleGroupMessage(json)
                "MSG_ACK" -> handleMessageAck(json)
                MediaProtocol.TYPE_MEDIA_HEADER -> handleMediaHeader(json)
                MediaProtocol.TYPE_MEDIA_CHUNK -> handleMediaChunk(json)
                TYPE_SOS -> scope.launch { handleSos(json, rssi, snr) }
                else -> {
                    // It's likely a MeshMessage
                    val meshMessage = MeshMessage.fromJson(json)
                    scope.launch { processIncomingMeshMessage(meshMessage, rssi, snr) }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing incoming JSON", e)
        }
    }

    private fun handleGroupInvite(json: JSONObject) {
        scope.launch {
            val groupId = json.getString("groupId")
            val groupName = json.getString("groupName")
            val groupKey = json.getString("groupKey")
            
            val chat = ChatEntity(
                id = groupId,
                name = groupName,
                isGroup = true,
                groupKey = groupKey
            )
            database.chatDao().insertChat(chat)
            Log.d(TAG, "Joined group: $groupName")
        }
    }

    private fun handleGroupMessage(json: JSONObject) {
        scope.launch {
            val groupId = json.getString("groupId")
            val encryptedContent = json.getString("content")
            val senderId = json.getString("senderId")
            val timestamp = json.getLong("timestamp")

            val chat = database.chatDao().getChatById(groupId) ?: return@launch
            val groupKey = chat.groupKey ?: return@launch
            
            val decrypted = encryptionManager.decryptWithSharedKey(encryptedContent, groupKey) ?: "[Decryption Failed]"
            
            val message = MessageEntity(
                id = UUID.randomUUID().toString(),
                chatId = groupId,
                senderId = senderId,
                content = decrypted,
                timestamp = Date(timestamp),
                isFromMe = senderId == keyManager.getPublicKeyBase64()
            )
            database.messageDao().insertMessage(message)
        }
    }

    private suspend fun initiateHandshake() {
        Log.i(TAG, "Initiating Handshake...")
        handshakeAttempts++
        val myId = keyManager.getPublicKeyBase64()
        val myBf = createBloomFilter()
        
        val handshake = JSONObject().apply {
            put("type", HANDSHAKE_TYPE)
            put("peerId", myId)
            put("publicKey", keyManager.getPublicKeyBase64())
            put("bloomFilter", myBf.toBase64())
            put("timestamp", DateUtils.getCurrentIsoTimestamp())
        }

        sendRawText(handshake.toString())
    }

    private suspend fun handleHandshake(json: JSONObject) {
        val peerId = json.getString("peerId")
        Log.i(TAG, "Received Handshake from $peerId")
        
        // Strict Parity: Verify if this peer is a known contact
        val contact = database.contactDao().getContactById(peerId)
        val isAccepted = contact != null
        
        if (!isAccepted) {
            Log.w(TAG, "🚫 Handshake rejected from unknown peer: $peerId")
        }

        val myBf = createBloomFilter()
        val ack = JSONObject().apply {
            put("type", HANDSHAKE_ACK_TYPE)
            put("peerId", keyManager.getPublicKeyBase64())
            put("status", if (isAccepted) STATUS_ACCEPTED else STATUS_REJECTED)
            put("bloomFilter", myBf.toBase64())
            put("timestamp", DateUtils.getCurrentIsoTimestamp())
        }

        sendRawText(ack.toString())

        if (isAccepted) {
            val peerBfBase64 = json.optString("bloomFilter")
            if (peerBfBase64.isNotEmpty()) {
                peerBloomFilters[peerId] = BloomFilter.fromBase64(peerBfBase64)
            }
            
            // Auto-Add as contact if not exists
            scope.launch {
                val existing = database.contactDao().getContactById(peerId)
                if (existing == null) {
                    val pubKey = json.optString("publicKey")
                    database.contactDao().insertContact(
                        org.sada.messenger.data.entities.ContactEntity(
                            id = peerId,
                            name = "Discovery: ${peerId.take(8)}",
                            publicKey = pubKey
                        )
                    )
                }
            }

            updatePeerList(peerId, true)
            syncPendingPackets(peerId)
        }
    }

    private suspend fun handleHandshakeAck(json: JSONObject) {
        val peerId = json.getString("peerId")
        val status = json.getString("status")
        handshakeAcks++
        
        if (status == STATUS_ACCEPTED) {
            Log.i(TAG, "Handshake accepted by $peerId")
            _connectedPeers.value = _connectedPeers.value + peerId
            
            // Parse Bloom Filter
            val bfBase64 = json.optString("bloomFilter")
            if (bfBase64.isNotEmpty()) {
                try {
                    val peerBf = BloomFilter.fromBase64(bfBase64)
                    peerBloomFilters[peerId] = peerBf
                } catch (e: Exception) {
                    Log.e(TAG, "Error parsing Bloom Filter from $peerId", e)
                }
            }
            syncPendingPackets(peerId)
        }
    }

    private suspend fun processIncomingMeshMessage(message: MeshMessage, rssi: Int?, snr: Double?) {
        val myId = keyManager.getPublicKeyBase64()
        
        // Update peer metrics if this is from a known contact
        updatePeerMetrics(message.originalSenderId, rssi, snr)

        if (processedMessageIds.contains(message.messageId)) return
        if (!message.isValid(myId)) return

        processedMessageIds.add(message.messageId)

        if (message.isForMe(myId)) {
            Log.i(TAG, "Message reached destination: ${message.messageId}")
            saveMessageToDb(message)
            sendAck(message.originalSenderId, message.messageId)
        } else {
            Log.i(TAG, "Relaying message: ${message.messageId}")
            storeAndForward(message)
        }
    }

    /**
     * Public API: enqueue + forward a direct mesh message.
     * This is the canonical path used by ChatViewModel.
     */
    suspend fun sendMeshMessage(message: MeshMessage): Boolean {
        return try {
            storeAndForward(message)
            true
        } catch (e: Exception) {
            _transportError.value = "sendMeshMessage_failed:${e.message}"
            Log.e(TAG, "Failed to send mesh message ${message.messageId}", e)
            false
        }
    }

    private suspend fun storeAndForward(message: MeshMessage) {
        val myId = keyManager.getPublicKeyBase64()
        val forwarded = message.addHop(myId)
        
        // Blind Relay Security: Hash the recipient ID
        val recipientHash = sha256(forwarded.finalDestinationId)
        
        // Save to relay queue
        database.relayQueueDao().addToQueue(
            RelayQueueEntity(
                messageId = forwarded.messageId,
                recipientHash = recipientHash,
                payload = forwarded.toJsonString(),
                expiresAt = Date(System.currentTimeMillis() + 24 * 60 * 60 * 1000)
            )
        )

        // Fan out to connected peers
        forwardToPeers(forwarded)
    }

    private suspend fun forwardToPeers(message: MeshMessage) {
        val jsonStr = message.toJsonString()
        
        // WiFi Mesh Forwarding
        _connectedPeers.value.forEach { peerId ->
            if (!message.trace.contains(peerId)) {
                val peerBf = peerBloomFilters[peerId]
                if (peerBf == null || !peerBf.contains(message.messageId)) {
                    sendRawText(jsonStr)
                }
            }
        }
        
        // LoRa Forwarding (Broadcast)
        if (loraInterface?.isConnected?.value == true) {
            val data = jsonStr.toByteArray(Charsets.UTF_8)
            val fragments = loraPacketizer.fragment(message.messageId, data)
            fragments.forEach { fragment ->
                loraInterface.sendData(fragment)
            }
        }
    }

    private suspend fun syncPendingPackets(peerId: String) {
        val activeRelays = database.relayQueueDao().getActiveRelays(Date())
        val peerBf = peerBloomFilters[peerId]
        
        activeRelays.forEach { relay ->
            if (peerBf == null || !peerBf.contains(relay.messageId)) {
                sendRawText(relay.payload)
            }
        }
    }

    private suspend fun saveMessageToDb(message: MeshMessage) {
        // Logic to decrypt and save to messages table
        // This requires knowing the shared secret with the sender
        // For now, just save as encrypted
        database.messageDao().insertMessage(
            MessageEntity(
                id = message.messageId,
                chatId = message.originalSenderId, // Simplified: use sender ID as chatId
                senderId = message.originalSenderId,
                content = message.encryptedContent,
                timestamp = message.timestamp,
                isFromMe = false,
                isRelayed = message.trace.isNotEmpty()
            )
        )
        
        // Also ensure chat exists
        database.chatDao().insertChat(
            ChatEntity(
                id = message.originalSenderId,
                name = "Chat with ${message.originalSenderId.take(8)}",
                lastMessage = "[Encrypted Message]",
                lastMessageAt = message.timestamp
            )
        )
    }

    private fun updatePeerList(peerId: String, connected: Boolean) {
        val current = _connectedPeers.value.toMutableList()
        if (connected) {
            if (!current.contains(peerId)) current.add(peerId)
        } else {
            current.remove(peerId)
            peerBloomFilters.remove(peerId)
        }
        _connectedPeers.value = current
    }

    private fun sendRawText(text: String) {
        val payload = text.toByteArray(Charsets.UTF_8)
        val framed = ByteArray(payload.size + 1)
        framed[0] = 0x00.toByte() // Text Frame
        System.arraycopy(payload, 0, framed, 1, payload.size)
        socketManager.write(framed)
    }

    private suspend fun createBloomFilter(): BloomFilter {
        val bf = BloomFilter()
        // Here we'd add all known message IDs from DB to the filter
        // and also all active relays we have (to avoid being sent them again)
        
        // Optimization: In a real app we'd query just recent IDs
        val activeRelays = database.relayQueueDao().getActiveRelays(Date())
        activeRelays.forEach { bf.add(it.messageId) }
        
        // processedMessageIds.forEach { bf.add(it) }
        
        return bf
    }

    private fun updatePeerMetrics(peerId: String, rssi: Int?, snr: Double?) {
        scope.launch {
            val contact = database.contactDao().getContactById(peerId) ?: return@launch
            database.contactDao().insertContact(
                contact.copy(
                    lastSeen = Date(),
                    lastRssi = rssi ?: contact.lastRssi,
                    lastSnr = snr ?: contact.lastSnr
                )
            )
        }
    }

    private suspend fun sendAck(peerId: String, messageId: String) {
        val ack = JSONObject().apply {
            put("type", "MSG_ACK")
            put("messageId", messageId)
            put("senderId", keyManager.getPublicKeyBase64())
        }
        sendRawText(ack.toString())
    }

    private fun handleMessageAck(json: JSONObject) {
        val messageId = json.getString("messageId")
        scope.launch {
            val message = database.messageDao().getMessageById(messageId)
            if (message != null) {
                database.messageDao().insertMessage(message.copy(status = "delivered"))
            }
        }
    }
    
    fun generateGroupKey(): String = groupProtocol.generateGroupKey()

    suspend fun sendGroupInvitation(peerId: String, groupId: String, groupName: String, groupKey: String) {
        val invite = groupProtocol.createInvitation(
            groupId = groupId,
            groupName = groupName,
            groupKey = groupKey,
            senderNickname = context.getSharedPreferences("sada_app_state", Context.MODE_PRIVATE)
                .getString("user_nickname", "Unknown") ?: "Unknown"
        )
        sendRawText(invite.toString()) // We could also send this as a MeshMessage for multi-hop
    }

    suspend fun sendGroupChatMessage(groupId: String, content: String) {
        val chat = database.chatDao().getChatById(groupId) ?: return
        val groupKey = chat.groupKey ?: return
        
        val encrypted = encryptionManager.encryptWithSharedKey(content, groupKey)
        val groupMsg = groupProtocol.createGroupMessage(
            groupId = groupId,
            encryptedContent = encrypted,
            senderId = keyManager.getPublicKeyBase64()
        )
        
        // Broadcast to all connected peers
        // In a more advanced version, we'd route this via MeshMessage
        sendRawText(groupMsg.toString())
        
        // Save locally
        saveMessageToDb(org.sada.messenger.data.models.MeshMessage(
            messageId = UUID.randomUUID().toString(),
            originalSenderId = keyManager.getPublicKeyBase64(),
            finalDestinationId = groupId,
            encryptedContent = encrypted,
            hopCount = 0,
            maxHops = 10,
            trace = emptyList(),
            timestamp = Date(),
            type = GroupProtocol.TYPE_GROUP_MSG
        ))
    }

    private fun handleMediaHeader(json: JSONObject) {
        val messageId = json.getString("messageId")
        val fileName = json.getString("fileName")
        val mimeType = json.getString("mimeType")
        
        scope.launch {
            // Pre-create the message record as "pending"
            database.messageDao().insertMessage(
                MessageEntity(
                    id = messageId,
                    chatId = json.optString("senderId", "unknown"),
                    senderId = json.optString("senderId", "unknown"),
                    content = "Receiving file: $fileName",
                    type = "media",
                    status = "receiving",
                    attachmentType = mimeType
                )
            )
        }
    }

    private fun handleMediaChunk(json: JSONObject) {
        val messageId = json.getString("messageId")
        val chunkIndex = json.getInt("chunkIndex")
        val totalChunks = json.optInt("totalChunks", 0)
        val dataStr = json.getString("data")
        val data = Base64.decode(dataStr, Base64.NO_WRAP)

        scope.launch {
            database.mediaChunkDao().insertChunk(
                MediaChunkEntity(
                    messageId = messageId,
                    chunkIndex = chunkIndex,
                    totalChunks = totalChunks,
                    data = data
                )
            )

            // Check if all chunks received
            val message = database.messageDao().getMessageById(messageId) ?: return@launch
            val expectedChunks = database.mediaChunkDao().getChunkCount(messageId)
            
            // In a real scenario, the header or chunks would convey the total count
            // For now, if we have chunks, let's see if we can finish.
            // Ideally header stores 'totalChunks' in the MessageEntity.
            // Let's update handleMediaHeader to store totalChunks.
        }
    }

    private suspend fun reassembleMedia(messageId: String, fileName: String): File? {
        val chunks = database.mediaChunkDao().getChunksForMessage(messageId)
        val destFile = File(context.filesDir, "media/received/$fileName")
        destFile.parentFile?.mkdirs()
        
        try {
            FileOutputStream(destFile).use { fos ->
                chunks.forEach { chunk ->
                    fos.write(chunk.data)
                }
            }
            database.mediaChunkDao().deleteChunksForMessage(messageId)
            return destFile
        } catch (e: Exception) {
            Log.e(TAG, "Reassembly failed", e)
            return null
        }
    }

    suspend fun sendMedia(chatId: String, file: File, mimeType: String) {
        val messageId = UUID.randomUUID().toString()
        val data = file.readBytes()
        val totalChunks = (data.size + MediaProtocol.CHUNK_SIZE - 1) / MediaProtocol.CHUNK_SIZE
        
        // 1. Send Header
        val header = mediaProtocol.createHeader(messageId, file.name, file.length(), totalChunks, mimeType).apply {
            put("senderId", keyManager.getPublicKeyBase64())
        }
        sendRawText(header.toString())
        
        // 2. Send Chunks with slight delay for mesh safety
        for (i in 0 until totalChunks) {
            val start = i * MediaProtocol.CHUNK_SIZE
            val end = Math.min(start + MediaProtocol.CHUNK_SIZE, data.size)
            val chunkData = data.sliceArray(start until end)
            
            val chunk = mediaProtocol.createChunk(messageId, i, chunkData)
            sendRawText(chunk.toString())
            delay(100) // Mesh pacing
        }
        
        // 3. Save locally
        database.messageDao().insertMessage(
            MessageEntity(
                id = messageId,
                chatId = chatId,
                senderId = keyManager.getPublicKeyBase64(),
                content = "Sent file: ${file.name}",
                type = "media",
                status = "sent",
                attachmentPath = file.absolutePath,
                attachmentType = mimeType,
                isFromMe = true
            )
        )
    }

    private suspend fun handleSos(json: JSONObject, rssi: Int?, snr: Double?) {
        val messageId = json.getString("messageId")
        val senderId = json.getString("senderId")
        val latitude = json.optDouble("latitude")
        val longitude = json.optDouble("longitude")
        val timestamp = json.getLong("timestamp")
        val hopCount = json.optInt("hopCount", 0)

        if (processedMessageIds.contains(messageId)) return
        processedMessageIds.add(messageId)

        Log.w(TAG, "EMERGENCY: Received SOS from $senderId (Hops: $hopCount)")

        // 1. Save to Emergency Chat
        val emergencyChatId = "SYSTEM_EMERGENCY"
        database.chatDao().insertChat(
            ChatEntity(
                id = emergencyChatId,
                name = "EMERGENCY / طوارئ",
                lastMessage = "SOS from ${senderId.take(8)}",
                lastMessageAt = Date(timestamp)
            )
        )

        database.messageDao().insertMessage(
            MessageEntity(
                id = messageId,
                chatId = emergencyChatId,
                senderId = senderId,
                content = "SOS: Emergency at location!",
                type = "sos",
                status = "received",
                timestamp = Date(timestamp),
                latitude = latitude,
                longitude = longitude,
                isRelayed = hopCount > 0
            )
        )

        // 2. Flood rebroadcast if within hop limit
        if (hopCount < SOS_MAX_HOPS) {
            val rebroadcast = JSONObject(json.toString()).apply {
                put("hopCount", hopCount + 1)
            }
            val jsonStr = rebroadcast.toString()
            
            // WiFi
            _connectedPeers.value.forEach { sendRawText(jsonStr) }
            
            // LoRa
            if (loraInterface?.isConnected?.value == true) {
                val data = jsonStr.toByteArray(Charsets.UTF_8)
                val fragments = loraPacketizer.fragment(messageId, data)
                fragments.forEach { loraInterface.sendData(it) }
            }
        }
    }

    suspend fun sendSosBroadcast(latitude: Double?, longitude: Double?) {
        val messageId = UUID.randomUUID().toString()
        val myId = keyManager.getPublicKeyBase64()
        val timestamp = DateUtils.getCurrentIsoTimestamp()

        val sos = JSONObject().apply {
            put("type", TYPE_SOS)
            put("messageId", messageId)
            put("senderId", myId)
            put("latitude", latitude ?: 0.0)
            put("longitude", longitude ?: 0.0)
            put("timestamp", timestamp)
            put("hopCount", 0)
        }

        val jsonStr = sos.toString()
        processedMessageIds.add(messageId)

        // 1. Save locally
        handleSos(sos, null, null)

        // 2. Broadcast to all (Flooding)
        _connectedPeers.value.forEach { sendRawText(jsonStr) }

        if (loraInterface?.isConnected?.value == true) {
            val data = jsonStr.toByteArray(Charsets.UTF_8)
            val fragments = loraPacketizer.fragment(messageId, data)
            fragments.forEach { loraInterface.sendData(it) }
        }
    }

    fun getDiagnostics(): Map<String, Any> {
        return mapOf(
            "myPeerId" to keyManager.getPublicKeyBase64(),
            "connectedPeers" to _connectedPeers.value,
            "handshakeAttempts" to handshakeAttempts,
            "handshakeAcks" to handshakeAcks,
            "handshakeTimeouts" to handshakeTimeouts,
            "processedMessagesCount" to processedMessageIds.size,
            "knownBloomFilters" to peerBloomFilters.size,
            "lastError" to (_transportError.value ?: "None"),
            "isSocketConnected" to socketManager.isSocketConnected()
        )
    }

    private fun sha256(input: String): String {
        val bytes = input.toByteArray(Charsets.UTF_8)
        val md = java.security.MessageDigest.getInstance("SHA-256")
        val digest = md.digest(bytes)
        return digest.fold("") { str, it -> str + "%02x".format(it) }
    }
}
