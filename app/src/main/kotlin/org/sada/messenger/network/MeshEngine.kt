package org.sada.messenger.network

import android.content.Context
import android.app.ActivityManager
import android.util.Log
import androidx.room.withTransaction
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import org.json.JSONObject
import org.json.JSONArray
import org.sada.messenger.SocketManager
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.data.entities.ChatEntity
import org.sada.messenger.data.entities.ContactEntity
import org.sada.messenger.data.entities.GroupMemberEntity
import org.sada.messenger.data.entities.MessageEntity
import org.sada.messenger.data.entities.RelayQueueEntity
import org.sada.messenger.data.entities.SeenMessageEntity
import org.sada.messenger.data.models.MeshMessage
import org.sada.messenger.data.models.VoiceMessageEnvelope
import org.sada.messenger.network.protocols.GroupProtocol
import org.sada.messenger.network.protocols.MediaProtocol
import org.sada.messenger.network.protocols.SyncProtocol
import org.sada.messenger.network.lora.LoraInterface
import org.sada.messenger.network.lora.LoraPacketizer
import org.sada.messenger.security.EncryptionManager
import org.sada.messenger.security.KeyManager
import org.sada.messenger.core.services.SadaNotificationManager
import org.sada.messenger.utils.BloomFilter
import org.sada.messenger.data.entities.MediaChunkEntity
import org.sada.messenger.network.direct.BleMeshManager
import org.sada.messenger.network.direct.WifiDirectManager
import java.util.*
import org.sada.messenger.utils.DateUtils
import org.sada.messenger.ui.utils.tr
import java.io.FileOutputStream
import java.io.File
import android.util.Base64
import java.security.MessageDigest

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
    private val loraInterface: LoraInterface? = null,
    val bleMeshManager: BleMeshManager = BleMeshManager(context, keyManager.getPublicKeyBase64()),
    val wifiDirectManager: WifiDirectManager = WifiDirectManager(context, socketManager),
    private val transportSend: (ByteArray) -> Boolean = { false },
    private val transportIsConnected: () -> Boolean = { false },
    private val activeTransportProvider: () -> String = { "NONE" }
) {
    private val loraPacketizer = LoraPacketizer()
    private val groupProtocol = GroupProtocol(keyManager, encryptionManager)
    private val syncProtocol = SyncProtocol()
    private val mediaProtocol = MediaProtocol()
    private val notificationManager = SadaNotificationManager(context)
    private val myId: String get() = keyManager.getPublicKeyBase64()
    private val userNickname: String get() = context.getSharedPreferences("sada_app_state", Context.MODE_PRIVATE)
        .getString("user_nickname", "User") ?: "User"
    
    private val processedMessageIds = LinkedHashSet<String>()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val _transportError = MutableStateFlow<String?>(null)
    val transportError: StateFlow<String?> = _transportError.asStateFlow()
    private val _transportConnected = MutableStateFlow(false)
    val transportConnected: StateFlow<Boolean> = _transportConnected.asStateFlow()

    private var handshakeAttempts = 0
    private var handshakeAcks = 0
    private var handshakeTimeouts = 0
    private var lastSocketRemoteIp: String? = null
    private var lastHandshakeReason: String = "none"
    private var pendingHandshakeAtMs: Long? = null
    private val peerHandshakeState = mutableMapOf<String, String>()
    private val peerHandshakeReason = mutableMapOf<String, String>()
    private var relayPumpJob: Job? = null
    private var gossipJob: Job? = null
    private var started = false
    private var relayQueueActiveCount = 0
    private var relayFlushedCount = 0L
    private var ackCleanupCount = 0L
    private var gossipCount = 0L
    
    private var spamBlockedRequestsCount = 0L
    private var transportSentNearby = 0L
    private var transportSentLan = 0L
    private var transportReceivedNearby = 0L
    private var transportReceivedLan = 0L
    private var voiceMessagesSent = 0
    private var voiceMessagesReceived = 0
    private var lastSeenCleanupAt = 0L
    private var lastRequestCleanupAt = 0L
    
    // Bandwidth throttling state
    private var messagesSentThisMinute = 0
    private var bytesSentThisSecond = 0
    private var lastMinuteReset = System.currentTimeMillis()
    private var lastSecondReset = System.currentTimeMillis()

    companion object {
        const val TAG = "MeshEngine"
        
        // Epidemic Gossip Constants
        private const val GOSSIP_INTERVAL_MS = 30000L // 30 seconds between gossip rounds
        private const val GOSSIP_BATCH_SIZE = 10 // Max messages to gossip per round (bandwidth limit)
        private const val MAX_MESSAGES_PER_MINUTE = 60 // Prevent flooding
        private const val MAX_BYTES_PER_SECOND = 50_000 // ~50KB/s limit
        const val HANDSHAKE_TYPE = "HANDSHAKE"
        const val HANDSHAKE_ACK_TYPE = "HANDSHAKE_ACK"
        const val GROUP_ANNOUNCE_TYPE = "GROUP_ANNOUNCE"
        const val STATUS_ACCEPTED = "ACCEPTED"
        const val STATUS_REJECTED = "REJECTED"
        const val TYPE_VOICE = "VOICE"
        const val TYPE_SOS = "SOS"
        const val TYPE_BROADCAST_MISSING = "BROADCAST_MISSING"

        const val SOS_MAX_HOPS = 15
        const val RELAY_PUMP_INTERVAL_MS = 7000L
        const val IN_MEMORY_SEEN_CACHE_LIMIT = 5000
        const val SEEN_RETENTION_MS = 48L * 60L * 60L * 1000L
        const val SEEN_CLEANUP_INTERVAL_MS = 30L * 60L * 1000L
        const val PENDING_REQUEST_RETENTION_MS = 72L * 60L * 60L * 1000L
        const val REQUEST_CLEANUP_INTERVAL_MS = 30L * 60L * 1000L
        const val MAX_PENDING_INCOMING_REQUESTS = 50

        // Feature Flags for high-risk environments
        const val FEATURE_MEDIA_ENABLED = false // Hibernate media processing to save battery/storage
    }

    private val _connectedPeers = MutableStateFlow<List<String>>(emptyList())
    val connectedPeers: StateFlow<List<String>> = _connectedPeers.asStateFlow()

    private val peerBloomFilters = mutableMapOf<String, BloomFilter>()
    private val mediaHeaderCache = mutableMapOf<String, JSONObject>()

    @Synchronized
    fun start() {
        if (started) return
        started = true
        setupSocketCallbacks()
        setupLoraCallbacks()
        setupP2pManagers()
        refreshTransportConnected()
        startRelayPump()
        startPeriodicGossip()
    }

    @Synchronized
    fun stop() {
        if (!started) return
        started = false
        relayPumpJob?.cancel()
        relayPumpJob = null
        gossipJob?.cancel()
        gossipJob = null
        socketManager.clearCallbacks()
        loraInterface?.clearOnDataReceived()
        bleMeshManager.clearOnPeerDiscoveredListener()
        wifiDirectManager.clearConnectionCallbacks()
        _connectedPeers.value = emptyList()
    }

    private fun setupP2pManagers() {
        bleMeshManager.setOnPeerDiscoveredListener { peerId, rssi ->
            Log.i(TAG, "BLE Discovered peer $peerId (len=${peerId.length}), checking Wi-Fi Direct...")
            if (!wifiDirectManager.isConnected.value) {
                val myId = keyManager.getPublicKeyBase64()
                // Both sides must compare equal-length strings:
                // BLE sends take(20), so we compare our take(20) vs the received 20-char peerId
                val myIdTrunc = myId.take(20)
                Log.i(TAG, "GO decision: myId=$myIdTrunc vs peerId=$peerId → ${if (myIdTrunc < peerId) "I create group" else "I discover"}")
                if (myIdTrunc < peerId) {
                    wifiDirectManager.createGroup()
                } else {
                    wifiDirectManager.startDiscovery()
                }
            }
        }
        
        wifiDirectManager.setConnectionCallbacks(
            onOwner = { inetAddress -> 
                Log.i(TAG, "Connected to Wi-Fi Direct Group Owner at ${inetAddress.hostAddress}")
            },
            onPeer = {
                Log.i(TAG, "Wi-Fi Direct Peer connected to my Hosted Group")
            }
        )
    }

    fun startAirBridge() {
        bleMeshManager.startAdvertising()
        bleMeshManager.startScanning()
    }

    fun stopAirBridge() {
        bleMeshManager.stopAdvertising()
        bleMeshManager.stopScanning()
        wifiDirectManager.stopDiscovery()
        wifiDirectManager.disconnect()
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
            transportReceivedLan++
            handleIncomingData(bytes)
        }

        socketManager.setOnConnectionStatusChanged { status, message ->
            Log.d(TAG, "Socket Status Changed: $status - $message")
            if (status.equals("connected", ignoreCase = true) ||
                status.equals("CONNECTED", ignoreCase = true)
            ) {
                lastHandshakeReason = "socket_connected_start_handshake"
                refreshTransportConnected()
                scope.launch { initiateHandshakeWithRetry() }
            } else if (
                status.equals("disconnected", ignoreCase = true) ||
                status.equals("error", ignoreCase = true)
            ) {
                _connectedPeers.value = emptyList()
                peerBloomFilters.clear()
                if (status.equals("disconnected", ignoreCase = true)) {
                    lastHandshakeReason = "socket_disconnected"
                } else {
                    lastHandshakeReason = "socket_error_${message.take(64)}"
                }
                refreshTransportConnected()
            }
        }
    }

    private fun startRelayPump() {
        relayPumpJob?.cancel()
        relayPumpJob = scope.launch {
            while (isActive) {
                try {
                    checkQueuePressure() // Remove oldest if queue is too full
                    flushRelayQueue()
                    cleanupSeenIfNeeded()
                    cleanupConnectionRequestsIfNeeded()
                } catch (e: Exception) {
                    Log.e(TAG, "Relay pump error", e)
                }
                delay(RELAY_PUMP_INTERVAL_MS)
            }
        }
    }
    
    /**
     * Queue Pressure Control: If queue exceeds max size, remove oldest messages.
     * This prevents memory issues and keeps the system responsive.
     */
    private suspend fun checkQueuePressure() {
        val MAX_QUEUE_SIZE = 1000
        val PRESSURE_THRESHOLD = 800
        
        val currentSize = database.relayQueueDao().countTotal()
        
        if (currentSize > MAX_QUEUE_SIZE) {
            val toRemove = currentSize - PRESSURE_THRESHOLD
            val removed = database.relayQueueDao().removeOldest(toRemove, Date())
            Log.w(TAG, "Queue pressure: removed $removed old messages (size was $currentSize)")
        }
    }
    
    /**
     * Periodic Gossip: Re-broadcast pending messages every 30 seconds.
     * This ensures messages reach new peers that join the mesh after the initial broadcast.
     * Critical for mobile scenarios where devices move in and out of range.
     */
    private fun startPeriodicGossip() {
        gossipJob?.cancel()
        gossipJob = scope.launch {
            while (isActive) {
                delay(GOSSIP_INTERVAL_MS)
                try {
                    if (transportIsConnected() && _connectedPeers.value.isNotEmpty()) {
                        performGossipRound()
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Gossip cycle error", e)
                }
            }
        }
    }
    
    private suspend fun performGossipRound() {
        val pendingRelays = database.relayQueueDao().getActiveRelays(Date())
        if (pendingRelays.isEmpty()) return
        
        Log.i(TAG, "Gossip cycle: ${pendingRelays.size} pending messages to propagate")
        
        // Select random subset of pending messages to gossip (limit bandwidth)
        val messagesToGossip = if (pendingRelays.size <= GOSSIP_BATCH_SIZE) {
            pendingRelays
        } else {
            pendingRelays.shuffled().take(GOSSIP_BATCH_SIZE)
        }
        
        messagesToGossip.forEach { relay ->
            try {
                val message = MeshMessage.fromJsonString(relay.payload)
                // Only gossip if message hasn't reached max hops
                if (message.isValid(keyManager.getPublicKeyBase64())) {
                    forwardToPeers(message)
                    gossipCount++
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to gossip message ${relay.messageId}", e)
            }
        }
    }

    private suspend fun refreshRelayQueueCount() {
        relayQueueActiveCount = database.relayQueueDao().countActive(Date())
    }

    private fun rememberSeenInMemory(messageId: String) {
        if (processedMessageIds.contains(messageId)) return
        processedMessageIds.add(messageId)
        while (processedMessageIds.size > IN_MEMORY_SEEN_CACHE_LIMIT) {
            val it = processedMessageIds.iterator()
            if (!it.hasNext()) break
            it.next()
            it.remove()
        }
    }

    private suspend fun isSeen(messageId: String): Boolean {
        if (processedMessageIds.contains(messageId)) return true
        return database.seenMessageDao().exists(messageId)
    }

    private suspend fun markSeen(messageId: String) {
        rememberSeenInMemory(messageId)
        database.seenMessageDao().upsertSeen(
            SeenMessageEntity(messageId = messageId, seenAt = Date())
        )
    }

    private suspend fun cleanupSeenIfNeeded() {
        val now = System.currentTimeMillis()
        if (now - lastSeenCleanupAt < SEEN_CLEANUP_INTERVAL_MS) return
        lastSeenCleanupAt = now
        val cutoff = Date(now - SEEN_RETENTION_MS)
        runCatching { database.seenMessageDao().deleteOlderThan(cutoff) }
            .onFailure { e -> Log.w(TAG, "Seen index cleanup failed", e) }
    }

    private suspend fun cleanupConnectionRequestsIfNeeded() {
        val now = System.currentTimeMillis()
        if (now - lastRequestCleanupAt < REQUEST_CLEANUP_INTERVAL_MS) return
        lastRequestCleanupAt = now
        val cutoff = Date(now - PENDING_REQUEST_RETENTION_MS)
        runCatching {
            database.connectionRequestDao().purgeStalePendingIncoming(cutoff)
        }.onFailure { e ->
            Log.w(TAG, "Pending incoming request cleanup failed", e)
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

    fun onExternalPayload(bytes: ByteArray) {
        transportReceivedNearby++
        handleIncomingData(bytes)
    }

    fun onExternalTransportConnected(transport: String) {
        lastHandshakeReason = "external_${transport}_connected"
        refreshTransportConnected()
        scope.launch { initiateHandshakeWithRetry() }
    }

    private fun refreshTransportConnected() {
        _transportConnected.value = transportIsConnected()
    }

    private fun handleIncomingJson(jsonStr: String, rssi: Int?, snr: Double?) {
        try {
            val json = JSONObject(jsonStr)
            val type = json.optString("type")

            when (type) {
                HANDSHAKE_TYPE -> scope.launch { handleHandshake(json) }
                HANDSHAKE_ACK_TYPE -> scope.launch { handleHandshakeAck(json) }
                GROUP_ANNOUNCE_TYPE -> handleGroupAnnounce(json)
                GroupProtocol.TYPE_GROUP_JOIN -> handleGroupJoin(json)
                GroupProtocol.TYPE_GROUP_INVITE -> handleGroupInvite(json)
                GroupProtocol.TYPE_GROUP_REMOVE -> handleGroupRemove(json)
                GroupProtocol.TYPE_GROUP_MSG -> handleGroupMessage(json)
                "MSG_ACK" -> handleMessageAck(json)
                MediaProtocol.TYPE_MEDIA_HEADER -> handleMediaHeader(json)
                MediaProtocol.TYPE_MEDIA_CHUNK -> handleMediaChunk(json)
                TYPE_SOS -> scope.launch { handleSos(json, rssi, snr) }
                TYPE_BROADCAST_MISSING -> scope.launch { handleMissingPersonBroadcast(json) }
                SyncProtocol.TYPE_SYNC_REQUEST -> handleSyncRequest(json)
                SyncProtocol.TYPE_SYNC_RESPONSE -> handleSyncResponse(json)
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
            val encryptedGroupKey = json.optString("encryptedGroupKey", "")
            val plaintextGroupKey = json.optString("groupKey", "")
            val senderPublicKey = json.optString("senderPublicKey", "")
            val senderId = json.optString("senderId", "")
            
            // BUG 4 FIX: Decrypt the group key using ECDH with sender's public key
            val groupKey: String = when {
                encryptedGroupKey.isNotEmpty() && senderPublicKey.isNotEmpty() -> {
                    try {
                        val senderPubBytes = Base64.decode(senderPublicKey, Base64.DEFAULT)
                        val sharedSecret = encryptionManager.calculateSharedSecret(senderPubBytes)
                        val decryptedKey = encryptionManager.decryptMessage(encryptedGroupKey, sharedSecret)
                        
                        if (decryptedKey != null) {
                            Log.i(TAG, "Group key decrypted successfully for $groupName")
                            decryptedKey
                        } else {
                            Log.e(TAG, "Failed to decrypt group key for $groupName - decryption returned null")
                            // Store encrypted and try to decrypt later when contact is verified
                            encryptedGroupKey
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to decrypt group key for $groupName", e)
                        // Store encrypted for later retry
                        encryptedGroupKey
                    }
                }
                plaintextGroupKey.isNotEmpty() -> {
                    Log.w(TAG, "Received group invite with PLAINTEXT key (legacy format)")
                    plaintextGroupKey
                }
                else -> {
                    Log.e(TAG, "Group invite missing group key")
                    return@launch
                }
            }
            
            val chat = ChatEntity(
                id = groupId,
                name = groupName,
                isGroup = true,
                groupKey = groupKey
            )
            database.chatDao().insertChat(chat)
            val myPeerId = keyManager.getPublicKeyBase64()
            database.groupDao().insertMember(
                GroupMemberEntity(
                    groupId = groupId,
                    peerId = myPeerId,
                    role = "member"
                )
            )
            
            // If key is still encrypted, schedule retry after contact verification
            if (groupKey == encryptedGroupKey && senderPublicKey.isNotEmpty()) {
                scheduleGroupKeyDecryptionRetry(groupId, encryptedGroupKey, senderPublicKey)
            }
            
            Log.d(TAG, "Joined group: $groupName")
        }
    }
    
    private fun scheduleGroupKeyDecryptionRetry(groupId: String, encryptedKey: String, senderPublicKey: String) {
        scope.launch {
            delay(30000L) // Retry after 30 seconds
            try {
                val chat = database.chatDao().getChatById(groupId)
                if (chat != null && chat.groupKey == encryptedKey) {
                    // Try decryption again (contact might be verified now)
                    val senderPubBytes = Base64.decode(senderPublicKey, Base64.DEFAULT)
                    val sharedSecret = encryptionManager.calculateSharedSecret(senderPubBytes)
                    val decryptedKey = encryptionManager.decryptMessage(encryptedKey, sharedSecret)
                    
                    if (decryptedKey != null) {
                        database.chatDao().insertChat(chat.copy(groupKey = decryptedKey))
                        Log.i(TAG, "Delayed group key decryption succeeded for $groupId")
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Delayed group key decryption failed for $groupId", e)
            }
        }
    }

    private fun handleGroupAnnounce(json: JSONObject) {
        scope.launch {
            try {
                val groupId = json.getString("groupId")
                val groupName = json.getString("groupName")
                val groupDescription = json.optString("groupDescription", "")
                val ownerId = json.optString("ownerId", "")
                val joinPolicy = json.optString("joinPolicy", "open")

                val existing = database.chatDao().getChatById(groupId)
                val merged = (existing ?: ChatEntity(id = groupId, name = groupName)).copy(
                    id = groupId,
                    name = groupName,
                    isGroup = true,
                    isPublic = true,
                    groupDescription = groupDescription.ifBlank { existing?.groupDescription },
                    joinPolicy = joinPolicy,
                    ownerId = ownerId.ifBlank { existing?.ownerId },
                )
                database.chatDao().insertChat(merged)
                Log.d(TAG, "Registered announced public group: $groupName ($groupId)")
            } catch (e: Exception) {
                Log.e(TAG, "Failed handling GROUP_ANNOUNCE", e)
            }
        }
    }

    private fun handleGroupJoin(json: JSONObject) {
        scope.launch {
            try {
                val groupId = json.getString("groupId")
                val peerId = json.getString("peerId")
                val nickname = json.optString("nickname", "Peer ${peerId.take(8)}")
                val group = database.groupDao().getGroupById(groupId) ?: return@launch
                val existing = database.groupDao().getMember(groupId, peerId)
                if (existing == null) {
                    database.groupDao().insertMember(
                        GroupMemberEntity(
                            groupId = groupId,
                            peerId = peerId,
                            role = "member"
                        )
                    )
                }
                database.chatDao().insertChat(
                    group.copy(
                        lastMessage = "$nickname ${if (Locale.getDefault().language.startsWith("ar")) "انضم للمجموعة" else "joined the group"}",
                        lastMessageAt = Date()
                    )
                )

                // If this device owns the group, send encrypted group key invitation
                // so the new member can decrypt future group messages.
                val myPeerId = keyManager.getPublicKeyBase64()
                if (group.ownerId == myPeerId && !group.groupKey.isNullOrBlank()) {
                    sendGroupInvitation(peerId, groupId, group.name, group.groupKey)
                }
                Log.i(TAG, "Group join applied: group=$groupId peer=$peerId")
            } catch (e: Exception) {
                Log.e(TAG, "Failed handling GROUP_JOIN", e)
            }
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

            val shouldIncrementUnread = senderId != keyManager.getPublicKeyBase64()
            database.chatDao().insertChat(
                chat.copy(
                    lastMessage = decrypted,
                    lastMessageAt = Date(timestamp),
                    unreadCount = if (shouldIncrementUnread) chat.unreadCount + 1 else chat.unreadCount
                )
            )
        }
    }

    private suspend fun initiateHandshakeWithRetry(maxAttempts: Int = 3) {
        Log.i(TAG, "Initiating Handshake with retry (max=$maxAttempts)...")
        
        repeat(maxAttempts) { attempt ->
            // Check if socket is still connected
            if (!socketManager.isSocketConnected()) {
                Log.w(TAG, "Socket disconnected during handshake retry loop")
                return
            }

            // We don't check _connectedPeers.value.firstOrNull() here because it's only 
            // populated AFTER the handshake completes. Checking it here creates a deadlock.
            
            Log.i(TAG, "Handshake attempt ${attempt + 1}/$maxAttempts")
            initiateHandshake()
            
            // Wait for handshake to complete (indicated by peerHandshakeState changing or peer added to list)
            // Exponential backoff: 1s, 2s, 4s
            val backoffMs = (1000L * (1 shl attempt)).coerceAtMost(5000L)
            delay(backoffMs)
            
            // If the peer list is no longer empty, it means at least one handshake succeeded
            if (_connectedPeers.value.isNotEmpty()) {
                Log.i(TAG, "Handshake succeeded (at least one peer connected)")
                return
            }
        }
        
        Log.e(TAG, "Handshake sequence completed (check logs for success/failure)")
        lastHandshakeReason = "handshake_retry_loop_finished"
    }

    private suspend fun initiateHandshake() {
        Log.i(TAG, "Initiating Handshake...")
        handshakeAttempts++
        pendingHandshakeAtMs = System.currentTimeMillis()
        lastHandshakeReason = "handshake_sent_waiting_ack"
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

        scope.launch {
            val sentAt = pendingHandshakeAtMs ?: return@launch
            delay(4500L)
            if (pendingHandshakeAtMs == sentAt && 
                peerHandshakeState[myId] != "peer_ready") {
                handshakeTimeouts++
                lastHandshakeReason = "handshake_ack_timeout"
            }
        }
    }

    private suspend fun handleHandshake(json: JSONObject) {
        val peerId = json.getString("peerId")
        Log.i(TAG, "Received Handshake from $peerId")
        peerHandshakeState[peerId] = "handshake_received"
        peerHandshakeReason[peerId] = "waiting_ack_send"
        
        // BUG 6 FIX: Check if peer is blocked → disconnect immediately
        val existingContact = database.contactDao().getContactById(peerId)
        if (existingContact?.isBlocked == true) {
            Log.w(TAG, "BLOCKED peer attempted handshake: $peerId — disconnecting")
            peerHandshakeState[peerId] = "blocked_rejected"
            peerHandshakeReason[peerId] = "peer_is_blocked"
            lastHandshakeReason = "blocked_peer_rejected"
            socketManager.closeConnections()
            return
        }

        val myBf = createBloomFilter()
        val ack = JSONObject().apply {
            put("type", HANDSHAKE_ACK_TYPE)
            put("peerId", keyManager.getPublicKeyBase64())
            put("status", STATUS_ACCEPTED)
            put("bloomFilter", myBf.toBase64())
            put("timestamp", DateUtils.getCurrentIsoTimestamp())
        }

        sendRawText(ack.toString())
        peerHandshakeState[peerId] = "handshake_ack_sent"
        peerHandshakeReason[peerId] = "awaiting_peer_ready"

        val peerBfBase64 = json.optString("bloomFilter")
        if (peerBfBase64.isNotEmpty()) {
            peerBloomFilters[peerId] = BloomFilter.fromBase64(peerBfBase64)
        }
        
        // AUTO-MERGE & DEEP CLEANUP: Ensure only one record exists per Public Key
        scope.launch {
            val pubKey = json.optString("publicKey", peerId)
            val name = json.optString("userName", "Discovery: ${peerId.take(8)}")
            consolidatePeerIdentity(peerId, pubKey, name)
        }

        updatePeerList(peerId, true)
        peerHandshakeState[peerId] = "peer_ready"
        peerHandshakeReason[peerId] = "accepted_incoming_handshake"
        lastHandshakeReason = "incoming_handshake_accepted"
        syncPublicGroupsCatalog()
        syncPendingPackets(peerId)
    }

    private suspend fun handleHandshakeAck(json: JSONObject) {
        val peerId = json.getString("peerId")
        val status = json.getString("status")
        handshakeAcks++
        pendingHandshakeAtMs = null
        
        if (status == STATUS_ACCEPTED) {
            Log.i(TAG, "Handshake accepted by $peerId")
            updatePeerList(peerId, true)
            peerHandshakeState[peerId] = "peer_ready"
            peerHandshakeReason[peerId] = "ack_received"
            lastHandshakeReason = "handshake_ack_accepted"
            
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
            syncPublicGroupsCatalog()
            syncPendingPackets(peerId)
        } else {
            peerHandshakeState[peerId] = "handshake_rejected"
            peerHandshakeReason[peerId] = "ack_rejected"
            lastHandshakeReason = "handshake_ack_rejected"
        }
    }

    private suspend fun processIncomingMeshMessage(message: MeshMessage, rssi: Int?, snr: Double?) {
        val myId = keyManager.getPublicKeyBase64()
        
        // Update peer metrics if this is from a known contact
        updatePeerMetrics(message.originalSenderId, rssi, snr)

        if (isSeen(message.messageId)) return
        if (!message.isValid(myId)) return

        markSeen(message.messageId)

        if (message.isForMe(myId)) {
            Log.i(TAG, "Message reached destination: ${message.messageId}")
            
            val senderId = message.originalSenderId
            
            // BUG 6 FIX: Check if sender is blocked → drop silently
            val senderContact = database.contactDao().getContactById(senderId)
                ?: database.contactDao().getContactByPublicKey(senderId)
            if (senderContact?.isBlocked == true) {
                Log.w(TAG, "Dropping message from blocked sender: ${senderId.take(8)}")
                return
            }
            
            // QR-FIRST: Check if sender is verified for personal messages
            val isVerified = senderContact?.isVerified == true
            
            // CONSOLIDATE IDENTITY: If message contains sender public key, ensure it's linked
            val senderPubKeyInMeta = message.metadata?.get("senderPublicKey") as? String
            if (senderPubKeyInMeta != null) {
                consolidatePeerIdentity(senderId, senderPubKeyInMeta, senderContact?.name ?: "Discovery: ${senderId.take(8)}")
            }
            
            // Handle Connection Requests
            if (message.type == MeshMessage.TYPE_CONNECTION_REQUEST) {
                // Pre-emptive merge check for connection requests
                val senderPubKey = message.metadata?.get("senderPublicKey") as? String ?: senderId
                val senderName = message.metadata?.get("senderName") as? String ?: "Discovery: ${senderId.take(8)}"
                consolidatePeerIdentity(senderId, senderPubKey, senderName)
                
                handleIncomingConnectionRequest(message)
                return
            }
            if (message.type == MeshMessage.TYPE_CONNECTION_ACCEPT) {
                handleIncomingConnectionAccept(message)
                return
            }

            // Recalculate isVerified after potential consolidation
            val finalSenderContact = database.contactDao().getContactById(senderId)
                ?: database.contactDao().getContactByPublicKey(senderPubKeyInMeta ?: senderId)
            val finalIsVerified = finalSenderContact?.isVerified == true

            if (message.type == MeshMessage.TYPE_STATUS_UPDATE) {
                if (!finalIsVerified) return
                handleIncomingStatusUpdate(message, finalSenderContact)
                sendAck(senderId, message.messageId)
                database.relayQueueDao().removeByMessageId(message.messageId)
                refreshRelayQueueCount()
                return
            }

            saveMessageToDb(
                message = message,
                isFromVerified = finalIsVerified,
                resolvedSenderContact = finalSenderContact
            )
            sendAck(senderId, message.messageId)
            database.relayQueueDao().removeByMessageId(message.messageId)
            refreshRelayQueueCount()
        } else {
            // Not for me: relay blindly (mailman role) regardless of verification
            Log.i(TAG, "Relaying message: ${message.messageId}")
            storeAndForward(message)
        }
    }

    suspend fun publishStatusToVerifiedContacts(statusText: String, expiresAt: Date): Int {
        val myId = keyManager.getPublicKeyBase64()
        val contacts = database.contactDao().getVerifiedContactsOnce()
            .filter { !it.isBlocked }
            .filter { (it.publicKey ?: it.id).isNotBlank() }
            .filter { (it.publicKey ?: it.id) != myId }

        var sentCount = 0
        for (contact in contacts) {
            val peerId = contact.publicKey?.takeIf { it.isNotBlank() } ?: contact.id
            val encrypted = runCatching {
                val remotePubKey = Base64.decode(peerId, Base64.DEFAULT)
                val sharedSecret = encryptionManager.calculateSharedSecret(remotePubKey)
                encryptionManager.encryptMessage(statusText, sharedSecret)
            }.getOrNull() ?: continue

            val statusMsg = MeshMessage(
                messageId = UUID.randomUUID().toString(),
                originalSenderId = myId,
                finalDestinationId = peerId,
                encryptedContent = encrypted,
                type = MeshMessage.TYPE_STATUS_UPDATE,
                metadata = mapOf(
                    "statusExpiresAt" to DateUtils.formatIso(expiresAt),
                    "senderPublicKey" to myId
                )
            )
            if (sendMeshMessage(statusMsg)) {
                sentCount++
            }
        }
        return sentCount
    }

    private suspend fun handleIncomingStatusUpdate(message: MeshMessage, senderContact: org.sada.messenger.data.entities.ContactEntity?) {
        val senderPublicKey = senderContact?.publicKey ?: message.originalSenderId
        val statusText = runCatching {
            val senderPubBytes = Base64.decode(senderPublicKey, Base64.DEFAULT)
            val sharedSecret = encryptionManager.calculateSharedSecret(senderPubBytes)
            encryptionManager.decryptMessage(message.encryptedContent, sharedSecret)
        }.getOrNull()?.trim().orEmpty()
        if (statusText.isBlank()) return

        val expiresRaw = message.metadata?.get("statusExpiresAt")?.toString().orEmpty()
        val expiresAt = runCatching {
            if (expiresRaw.isBlank()) Date(System.currentTimeMillis() + 24L * 60L * 60L * 1000L)
            else DateUtils.parseIso(expiresRaw)
        }.getOrElse { Date(System.currentTimeMillis() + 24L * 60L * 60L * 1000L) }

        val contactId = senderContact?.id ?: message.originalSenderId
        database.contactDao().setStatus(
            id = contactId,
            statusText = statusText,
            expiresAt = expiresAt,
            updatedAt = Date()
        )
    }

    /**
     * Public API: enqueue + forward a direct mesh message.
     * This is the canonical path used by ChatViewModel.
     */
    suspend fun sendMeshMessage(message: MeshMessage): Boolean {
        return try {
            val myId = keyManager.getPublicKeyBase64()
            val messageWithSenderKey = message.copy(
                metadata = (message.metadata ?: emptyMap()) + ("senderPublicKey" to myId)
            )
            storeAndForward(messageWithSenderKey)
            true
        } catch (e: Exception) {
            _transportError.value = "sendMeshMessage_failed:${e.message}"
            Log.e(TAG, "Failed to send mesh message ${message.messageId}", e)
            false
        }
    }

    suspend fun sendConnectionRequest(peerId: String, peerName: String, publicKey: String) {
        val contact = database.contactDao().getContactById(peerId)
        if (contact?.lastActionAt != null) {
            val cooldown = 24 * 60 * 60 * 1000L
            if (System.currentTimeMillis() - contact.lastActionAt.time < cooldown) {
                Log.w(TAG, "Connection request blocked by cooldown for $peerId")
                return
            }
        }

        val request = MeshMessage(
            messageId = UUID.randomUUID().toString(),
            originalSenderId = myId,
            finalDestinationId = publicKey,
            encryptedContent = Base64.encodeToString(
                encryptionManager.encryptMessage(
                    "CONNECTION_REQUEST from $userNickname",
                    encryptionManager.calculateSharedSecret(Base64.decode(publicKey, Base64.DEFAULT))
                ).toByteArray(),
                Base64.DEFAULT
            ),
            type = MeshMessage.TYPE_CONNECTION_REQUEST,
            metadata = mapOf("senderName" to userNickname, "senderPublicKey" to myId)
        )
        
        database.connectionRequestDao().upsertRequest(
            org.sada.messenger.data.entities.ConnectionRequestEntity(
                id = UUID.randomUUID().toString(),
                peerId = peerId,
                peerName = peerName,
                publicKey = publicKey,
                status = "pending",
                type = "outgoing"
            )
        )
        storeAndForward(request)
    }

    suspend fun acceptConnectionRequest(requestId: String, peerId: String, publicKey: String) {
        val canonicalPeerId = publicKey.ifBlank { peerId }
        val accept = MeshMessage(
            messageId = UUID.randomUUID().toString(),
            originalSenderId = myId,
            finalDestinationId = canonicalPeerId,
            encryptedContent = "ACCEPTED",
            type = MeshMessage.TYPE_CONNECTION_ACCEPT,
            metadata = mapOf("senderPublicKey" to myId)
        )
        
        database.connectionRequestDao().updateRequestStatus(requestId, "approved", Date())
        database.contactDao().setVerified(canonicalPeerId, true)
        if (canonicalPeerId != peerId) {
            database.contactDao().setVerified(peerId, true)
            consolidatePeerIdentity(peerId, canonicalPeerId, "Discovery: ${canonicalPeerId.take(8)}")
        }
        storeAndForward(accept)
    }

    suspend fun rejectConnectionRequest(requestId: String, peerId: String) {
        database.connectionRequestDao().updateRequestStatus(requestId, "rejected", Date())
        database.contactDao().deleteContactById(peerId) // Or keep with cooldown
        val existing = database.contactDao().getContactById(peerId)
        if (existing != null) {
            database.contactDao().insertContact(existing.copy(lastActionAt = Date()))
        }
    }

    private suspend fun handleIncomingConnectionRequest(message: MeshMessage) {
        val senderId = message.originalSenderId
        val senderName = message.metadata?.get("senderName") as? String ?: "Unknown"
        val senderPublicKey = message.metadata?.get("senderPublicKey") as? String ?: senderId
        val canonicalPeerId = senderPublicKey.ifBlank { senderId }

        val senderContact = database.contactDao().getContactById(canonicalPeerId)
            ?: database.contactDao().getContactByPublicKey(senderPublicKey)
        if (senderContact?.isBlocked == true) {
            Log.w(TAG, "Dropping connection request from blocked peer: ${canonicalPeerId.take(12)}")
            spamBlockedRequestsCount++
            return
        }

        val existing = database.connectionRequestDao().getRequestByPublicKey(senderPublicKey)
        if (existing?.status == "pending" && existing.type == "incoming") {
            Log.d(TAG, "Ignoring duplicate incoming request from ${canonicalPeerId.take(12)} (already pending)")
            spamBlockedRequestsCount++
            return
        }

        val pendingIncomingCount = database.connectionRequestDao().getPendingIncomingCount()
        if (pendingIncomingCount >= MAX_PENDING_INCOMING_REQUESTS) {
            Log.w(TAG, "Incoming request dropped: pending inbox is full ($pendingIncomingCount)")
            spamBlockedRequestsCount++
            return
        }

        database.connectionRequestDao().upsertRequest(
            org.sada.messenger.data.entities.ConnectionRequestEntity(
                id = existing?.id ?: UUID.randomUUID().toString(),
                peerId = canonicalPeerId,
                peerName = senderName,
                publicKey = senderPublicKey,
                status = "pending",
                type = "incoming"
            )
        )

        notificationManager.showIncomingMessageNotification(
            chatId = canonicalPeerId,
            title = tr("طلب اتصال جديد", "New Connection Request"),
            body = tr("يريد $senderName إضافتك كجهة اتصال موثوقة", "$senderName wants to add you as a trusted contact")
        )
    }

    /**
     * CONSOLIDATED IDENTITY MERGE: Single source of truth for handling peer ID changes.
     * This method ensures that all messages, chats, and requests from an old ID
     * are migrated to a new ID if they share the same Public Key.
     */
    private suspend fun consolidatePeerIdentity(newPeerId: String, publicKey: String?, potentialName: String) {
        val normalizedKey = publicKey?.trim().orEmpty()
        if (normalizedKey.isBlank()) return

        // Canonical rule: public key is the stable identity key.
        val canonicalPeerId = normalizedKey
        val observedPeerId = newPeerId.trim()
        
        Log.d(TAG, "Consolidating identity: $observedPeerId -> $canonicalPeerId")

        database.withTransaction {
            val existingCanonical = database.contactDao().getContactById(canonicalPeerId)
            val existingByPubKey = database.contactDao().getContactByPublicKey(normalizedKey)
            val observedContact = if (observedPeerId != canonicalPeerId) {
                database.contactDao().getContactById(observedPeerId)
            } else {
                null
            }

            // Inherit verification and block status from ANY of the identities being merged
            val isVerified = (existingCanonical?.isVerified == true) || 
                             (existingByPubKey?.isVerified == true) || 
                             (observedContact?.isVerified == true)
                             
            val isBlocked = (existingCanonical?.isBlocked == true) || 
                            (existingByPubKey?.isBlocked == true) || 
                            (observedContact?.isBlocked == true)

            val preferredName = when {
                !existingCanonical?.name.isNullOrBlank() && !existingCanonical.name.contains("Discovery") -> existingCanonical.name
                !existingByPubKey?.name.isNullOrBlank() && !existingByPubKey!!.name.contains("Discovery") -> existingByPubKey.name
                !observedContact?.name.isNullOrBlank() && !observedContact!!.name.contains("Discovery") -> observedContact.name
                else -> potentialName
            }

            // Create or update canonical contact
            val canonicalBase = existingCanonical ?: existingByPubKey ?: ContactEntity(
                id = canonicalPeerId,
                name = preferredName,
                publicKey = normalizedKey,
                isVerified = isVerified,
                isBlocked = isBlocked
            )

            database.contactDao().insertContact(
                canonicalBase.copy(
                    id = canonicalPeerId,
                    name = preferredName,
                    publicKey = normalizedKey,
                    isVerified = isVerified,
                    isBlocked = isBlocked,
                    updatedAt = Date()
                )
            )

            // Migrate data from observedPeerId to canonicalPeerId if they differ
            if (observedPeerId.isNotBlank() && observedPeerId != canonicalPeerId) {
                Log.i(TAG, "Migrating data from $observedPeerId to $canonicalPeerId")
                
                database.messageDao().updateChatIdForMessages(observedPeerId, canonicalPeerId)
                database.messageDao().updateSenderIdForMessages(observedPeerId, canonicalPeerId)
                database.connectionRequestDao().updatePeerIdForRequests(observedPeerId, canonicalPeerId)
                
                // Remove the old temporary contact and its associated empty chat if it exists
                database.contactDao().deleteContactById(observedPeerId)
                database.chatDao().deleteChatById(observedPeerId)
            }
        }
        
        Log.i(TAG, "Identity consolidation complete for $canonicalPeerId (Verified: ${peerHandshakeState[canonicalPeerId]})")
    }

    private suspend fun handleIncomingConnectionAccept(message: MeshMessage) {
        val senderId = message.originalSenderId
        val senderPubKey = message.metadata?.get("senderPublicKey") as? String ?: senderId
        val canonicalPeerId = senderPubKey.ifBlank { senderId }
        
        // Try looking up by ID first, then by Public Key (handles peer ID changes)
        val request = database.connectionRequestDao().getRequestByPeerId(senderId)
            ?: database.connectionRequestDao().getRequestByPublicKey(senderPubKey)
            
        if (request != null) {
            database.connectionRequestDao().updateRequestStatus(request.id, "approved", Date())
            database.contactDao().setVerified(canonicalPeerId, true)
            if (request.peerId != canonicalPeerId) {
                database.contactDao().setVerified(request.peerId, true)
            }
            consolidatePeerIdentity(senderId, senderPubKey, request.peerName)
        }
    }

    private suspend fun storeAndForward(message: MeshMessage) {
        val myId = keyManager.getPublicKeyBase64()
        val forwarded = message.addHop(myId)
        if (forwarded.hopCount >= forwarded.maxHops) {
            Log.w(TAG, "Dropping message ${forwarded.messageId}: max hops reached")
            return
        }
        
        // Blind Relay Security: Hash the recipient ID
        val recipientHash = sha256(forwarded.finalDestinationId)

        // Deduplicate by messageId to avoid queue inflation.
        database.relayQueueDao().removeByMessageId(forwarded.messageId)
        
        // Priority-based queue insertion (Standardized: 0 is highest)
        val priority = calculateMessagePriority(forwarded)
        
        val ttlMs = getMessageTTL(forwarded)
        val expiresAt = Date(System.currentTimeMillis() + ttlMs)

        // Inject remaining TTL for the next hop (relative expiry)
        val messageWithTtl = forwarded.copy(remainingTtlMs = ttlMs)

        database.relayQueueDao().addToQueue(
            RelayQueueEntity(
                messageId = messageWithTtl.messageId,
                recipientHash = recipientHash,
                payload = messageWithTtl.toJsonString(),
                expiresAt = expiresAt,
                priority = priority
            )
        )
        refreshRelayQueueCount()

        // Smart Relay: Only forward if we have good carriers
        if (shouldForwardImmediately(forwarded)) {
            forwardToPeers(forwarded)
        } else {
            Log.d(TAG, "Message ${forwarded.messageId.take(8)} stored for smarter relay")
        }
    }
    
    /**
     * Calculate message priority based on type and urgency.
     * Priority: SOS (100) > Connection (80) > Chat (50) > Status (20)
     */
    private fun calculateMessagePriority(message: MeshMessage): Int {
        return when (message.type) {
            TYPE_SOS -> 0 // Highest priority - emergency (SOS bypasses rate limits)
            MeshMessage.TYPE_CONNECTION_REQUEST -> 1
            MeshMessage.TYPE_CONNECTION_ACCEPT -> 1
            MeshMessage.TYPE_VOICE -> 2
            else -> 2 // Normal text messages
        }
    }
    
    /**
     * Geographic Routing: Estimate if message is moving toward destination based on hop progress.
     * This is a simplified heuristic - in production, use actual GPS coordinates.
     */
    private fun isMovingTowardDestination(message: MeshMessage): Boolean {
        // If hop count is low, message is likely still spreading
        // If hop count is high but not maxed, it may be circling
        val progressRatio = message.hopCount.toFloat() / message.maxHops
        
        // Early hops (0-30%) = likely spreading outward
        // Mid hops (30-70%) = should be converging
        // Late hops (70%+) = may be lost or in sparse area
        return when {
            progressRatio < 0.3f -> true // Early phase, keep spreading
            progressRatio < 0.7f -> true // Mid phase, should be routing
            else -> false // Late phase, might be circling
        }
    }
    
    /**
     * Get current device location for geographic routing.
     * Returns null if location unavailable or permission denied.
     */
    private fun getCurrentLocation(): Pair<Double, Double>? {
        // TODO: Implement actual GPS location retrieval
        // For now, return null (location-agnostic routing)
        return null
    }
    
    /**
     * Get message TTL based on priority.
     */
    private fun getMessageTTL(message: MeshMessage): Long {
        return when (calculateMessagePriority(message)) {
            0 -> 48 * 60 * 60 * 1000L // 48 hours for SOS (Survival Priority)
            1 -> 24 * 60 * 60 * 1000L // 24 hours for handshakes
            else -> 24 * 60 * 60 * 1000L // 24 hours default
        }
    }
    
    /**
     * Smart Relay Decision: Should we forward immediately or wait for better carrier?
     * Forwards immediately if:
     * - Message is high priority (SOS)
     * - We have connected peers
     * - Destination is directly connected
     */
    private fun shouldForwardImmediately(message: MeshMessage): Boolean {
        // Check bandwidth limits first
        if (!checkBandwidthAvailable(message)) {
            Log.d(TAG, "Bandwidth throttled, delaying message ${message.messageId.take(8)}")
            return false
        }
        
        // Always forward SOS immediately if bandwidth allows
        if (message.type == TYPE_SOS) return true
        
        // Forward if we have connected peers and bandwidth available
        if (_connectedPeers.value.isNotEmpty()) return true
        
        // Store for later if no good carriers
        return false
    }
    
    /**
     * Bandwidth Throttling: Check if we can send more data.
     * High priority messages (SOS) bypass some limits.
     */
    private fun checkBandwidthAvailable(message: MeshMessage): Boolean {
        val now = System.currentTimeMillis()
        
        // Reset counters if time window passed
        if (now - lastMinuteReset > 60000L) {
            messagesSentThisMinute = 0
            lastMinuteReset = now
        }
        if (now - lastSecondReset > 1000L) {
            bytesSentThisSecond = 0
            lastSecondReset = now
        }
        
        // SOS messages bypass minute limit but respect second limit
        if (message.type == TYPE_SOS) {
            return bytesSentThisSecond < MAX_BYTES_PER_SECOND
        }
        
        // Normal messages must respect both limits
        return messagesSentThisMinute < MAX_MESSAGES_PER_MINUTE &&
               bytesSentThisSecond < MAX_BYTES_PER_SECOND
    }
    
    /**
     * Record sent data for bandwidth tracking.
     */
    private fun recordDataSent(bytes: Int) {
        messagesSentThisMinute++
        bytesSentThisSecond += bytes
    }

    private suspend fun forwardToPeers(message: MeshMessage) {
        if (!transportIsConnected()) return
        val jsonStr = message.toJsonString()
        
        // Epidemic Gossip: Select peers intelligently based on network density
        val connectedPeers = _connectedPeers.value
        val gossipTargets = selectGossipTargets(connectedPeers, message)
        
        // WiFi Mesh Forwarding to selected peers
        for (peerId in gossipTargets) {
            if (!message.trace.contains(peerId)) {
                val peerBf = peerBloomFilters[peerId]
                if (peerBf == null || !peerBf.contains(message.messageId)) {
                    Log.d(TAG, "Gossip: Forwarding ${message.messageId.take(8)} to ${peerId.take(8)}")
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
    
    /**
     * Epidemic Gossip: Select optimal number of peers to forward to.
     * - Low density (< 3 peers): Flood to all
     * - Medium density (3-10 peers): Select 3 random
     * - High density (> 10 peers): Select 3 random (save bandwidth)
     */
    private fun selectGossipTargets(peers: List<String>, message: MeshMessage): List<String> {
        val availablePeers = peers.filter { !message.trace.contains(it) }
        
        return when {
            availablePeers.isEmpty() -> emptyList()
            availablePeers.size <= 3 -> {
                // Low density: flood to all
                Log.d(TAG, "Gossip: Flooding to all ${availablePeers.size} peers (low density)")
                availablePeers
            }
            else -> {
                // Medium/High density: random selection for load balancing
                val selected = availablePeers.shuffled().take(3)
                Log.d(TAG, "Gossip: Selected ${selected.size}/${availablePeers.size} peers (random)")
                selected
            }
        }
    }

    private suspend fun syncPendingPackets(peerId: String) {
        database.relayQueueDao().removeExpired(Date())
        val activeRelays = database.relayQueueDao().getActiveRelays(Date())
        val peerBf = peerBloomFilters[peerId]

        val ordered = activeRelays.sortedByDescending { relay ->
            val direct = try {
                MeshMessage.fromJsonString(relay.payload).finalDestinationId == peerId
            } catch (_: Exception) {
                false
            }
            if (direct) 1 else 0
        }

        for (relay in ordered) {
            if (peerBf == null || !peerBf.contains(relay.messageId)) {
                sendRawText(relay.payload)
                relayFlushedCount++
            }
        }
        refreshRelayQueueCount()
    }

    suspend fun flushRelayQueue() {
        database.relayQueueDao().removeExpired(Date())
        refreshRelayQueueCount()
        refreshTransportConnected()
        if (!transportIsConnected()) return
        if (_connectedPeers.value.isEmpty()) return

        for (peerId in _connectedPeers.value) {
            syncPendingPackets(peerId)
        }
    }

    private suspend fun saveMessageToDb(
        message: MeshMessage,
        isFromVerified: Boolean = true,
        resolvedSenderContact: org.sada.messenger.data.entities.ContactEntity? = null
    ) {
        val existing = database.messageDao().getMessageById(message.messageId)
        if (existing != null) {
            return
        }

        val senderPublicKeyMeta = message.metadata?.get("senderPublicKey") as? String
        val contactById = database.contactDao().getContactById(message.originalSenderId)
        val contact = resolvedSenderContact
            ?: contactById
            ?: senderPublicKeyMeta?.let { database.contactDao().getContactByPublicKey(it) }
            ?: database.contactDao().getContactByPublicKey(message.originalSenderId)
            
        // If we found the contact by public key but the ID is different, consolidate now!
        if (contact != null && contact.id != message.originalSenderId) {
            consolidatePeerIdentity(
                newPeerId = message.originalSenderId,
                publicKey = contact.publicKey ?: senderPublicKeyMeta,
                potentialName = contact.name
            )
        }

        val stableChatId = contact?.id ?: message.originalSenderId

        // QR-only model: unverified peers are not allowed to spawn inbox chats.
        // Their requests are handled separately by connection-request flow.
        if (!isFromVerified) {
            Log.w(TAG, "Ignoring direct message from unverified peer: ${message.originalSenderId.take(12)}")
            return
        }

        var displayContent = message.encryptedContent
        var mediaPath: String? = null
        var mediaDur: Int? = null

        try {
            val senderPublicKey = contact?.publicKey ?: message.originalSenderId
            val senderPubBytes = Base64.decode(senderPublicKey, Base64.DEFAULT)
            val sharedSecret = encryptionManager.calculateSharedSecret(senderPubBytes)
            
            if (message.type == MeshMessage.TYPE_VOICE) {
                val encryptedBytes = Base64.decode(message.encryptedContent, Base64.DEFAULT)
                val decryptedBytes = encryptionManager.decryptBytes(encryptedBytes, sharedSecret)
                mediaPath = saveVoiceToCache(message.messageId, decryptedBytes)
                mediaDur = (message.metadata?.get("durationSeconds") as? Number)?.toInt()
                displayContent = "[Voice Message]"
                voiceMessagesReceived++
            } else {
                val decrypted = encryptionManager.decryptMessage(message.encryptedContent, sharedSecret)
                if (!decrypted.isNullOrBlank()) {
                    displayContent = decrypted
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Decryption failed for message ${message.messageId}", e)
            if (message.type == MeshMessage.TYPE_VOICE) displayContent = "[Encrypted Voice]"
        }

        val shownContent = displayContent

        // Ensure chat exists and increment unread for incoming message.
        val chatName = contact?.name ?: "Chat with ${message.originalSenderId.take(8)}"
        val existingChat = database.chatDao().getChatById(stableChatId)
        database.chatDao().insertChat(
            if (existingChat != null) {
                existingChat.copy(
                    name = chatName,
                    lastMessage = shownContent,
                    lastMessageAt = message.timestamp,
                    unreadCount = existingChat.unreadCount + 1
                )
            } else {
                ChatEntity(
                    id = stableChatId,
                    name = chatName,
                    lastMessage = shownContent,
                    lastMessageAt = message.timestamp,
                    unreadCount = 1
                )
            }
        )

        try {
            database.messageDao().insertMessage(
                MessageEntity(
                    id = message.messageId,
                    chatId = stableChatId,
                    senderId = stableChatId,
                    content = displayContent,
                    type = if (message.type == MeshMessage.TYPE_VOICE) "voice" else "text",
                    timestamp = message.timestamp,
                    isFromMe = false,
                    isRelayed = message.trace.isNotEmpty(),
                    mediaLocalPath = mediaPath,
                    mediaDuration = mediaDur
                )
            )
            if (!isAppInForeground()) {
                notificationManager.showIncomingMessageNotification(
                    chatId = stableChatId,
                    title = chatName,
                    body = shownContent
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed inserting incoming message ${message.messageId} for chat=$stableChatId", e)
        }
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

    private suspend fun sendRawText(text: String) {
        val payload = text.toByteArray(Charsets.UTF_8)
        val framed = ByteArray(payload.size + 1)
        framed[0] = 0x00.toByte() // Text Frame
        System.arraycopy(payload, 0, framed, 1, payload.size)
        
        // Record bandwidth usage
        recordDataSent(framed.size)
        
        withContext(Dispatchers.IO) {
            val selectedTransport = activeTransportProvider()
            val sent = transportSend(framed)
            if (!sent) {
                _transportError.value = "send_failed_no_transport"
            } else {
                if (selectedTransport.startsWith("Nearby", ignoreCase = true)) {
                    transportSentNearby++
                } else {
                    transportSentLan++
                }
            }
        }
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
        val ackSenderId = json.optString("senderId", "unknown")
        val myId = keyManager.getPublicKeyBase64()
        
        scope.launch {
            // Check if this is an ACK for a message I sent
            val myMessage = database.messageDao().getMessageById(messageId)
            if (myMessage != null && myMessage.isFromMe) {
                Log.i(TAG, "ACK received for my message $messageId from ${ackSenderId.take(12)}")
                database.messageDao().updateMessageStatus(messageId, "delivered")
                database.relayQueueDao().removeByMessageId(messageId)
                refreshRelayQueueCount()
                return@launch
            }
            
            // Check if this is an ACK for a message I'm relaying
            // (Store-and-Forward: forward ACK back to original sender)
            val relayed = database.relayQueueDao().getByMessageId(messageId)
            if (relayed != null) {
                Log.i(TAG, "Forwarding ACK for relayed message $messageId")
                // Forward ACK to next hop (reverse path)
                val ack = JSONObject().apply {
                    put("type", "MSG_ACK")
                    put("messageId", messageId)
                    put("senderId", ackSenderId)
                    put("forwardedBy", myId)
                }
                sendRawText(ack.toString())
                
                // Remove from relay queue since destination confirmed receipt
                val removed = database.relayQueueDao().removeByMessageId(messageId)
                if (removed > 0) {
                    ackCleanupCount += removed
                    Log.i(TAG, "Relay queue cleaned up for delivered message $messageId")
                }
                refreshRelayQueueCount()
                return@launch
            }
            
            // ACK for unknown message - just log
            Log.d(TAG, "ACK received for unknown message $messageId")
        }
    }
    
    fun generateGroupKey(): String = groupProtocol.generateGroupKey()

    /**
     * BUG 4 FIX: Encrypt the group key per-recipient via ECDH before sending.
     */
    suspend fun sendGroupInvitation(peerId: String, groupId: String, groupName: String, groupKey: String) {
        val encryptedGroupKey = try {
            val recipientContact = database.contactDao().getContactById(peerId)
                ?: database.contactDao().getContactByPublicKey(peerId)
            val recipientPubKey = recipientContact?.publicKey ?: peerId
            val recipientPubBytes = Base64.decode(recipientPubKey, Base64.DEFAULT)
            val sharedSecret = encryptionManager.calculateSharedSecret(recipientPubBytes)
            encryptionManager.encryptMessage(groupKey, sharedSecret) ?: groupKey
        } catch (e: Exception) {
            Log.e(TAG, "Failed to encrypt group key for $peerId", e)
            groupKey
        }

        val invite = groupProtocol.createInvitation(
            groupId = groupId,
            groupName = groupName,
            encryptedGroupKey = encryptedGroupKey,
            senderNickname = context.getSharedPreferences("sada_app_state", Context.MODE_PRIVATE)
                .getString("user_nickname", "Unknown") ?: "Unknown"
        )
        sendRawText(invite.toString())
    }

    /**
     * Rotate the group key (called when a member is removed).
     * Generates a new key, updates local DB, and sends encrypted key to all remaining members.
     */
    suspend fun rotateGroupKey(groupId: String) {
        val myId = keyManager.getPublicKeyBase64()
        val group = database.groupDao().getGroupById(groupId) ?: return
        if (group.ownerId != myId) {
            Log.w(TAG, "Only group owner can rotate key")
            return
        }
        
        val newKey = groupProtocol.generateGroupKey()
        // Update group key directly in chat entity
        val chat = database.groupDao().getGroupById(groupId)
        if (chat != null) {
            database.chatDao().insertChat(chat.copy(groupKey = newKey))
        }
        
        // Send encrypted new key to each remaining member
        val members = database.groupDao().getAllMembersList(groupId)
        members.forEach { member ->
            if (member.peerId != myId) {
                try {
                    val contact = database.contactDao().getContactById(member.peerId)
                        ?: database.contactDao().getContactByPublicKey(member.peerId)
                    val pubKey = contact?.publicKey ?: member.peerId
                    val pubBytes = Base64.decode(pubKey, Base64.DEFAULT)
                    val sharedSecret = encryptionManager.calculateSharedSecret(pubBytes)
                    val encryptedNewKey = encryptionManager.encryptMessage(newKey, sharedSecret) ?: newKey
                    
                    val payload = groupProtocol.createKeyRotationPayload(groupId, encryptedNewKey)
                    sendRawText(payload.toString())
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to send rotated key to ${member.peerId.take(8)}", e)
                }
            }
        }
        Log.i(TAG, "Group key rotated for $groupId, sent to ${members.size - 1} members")
    }

    /**
     * Remove a member from a group (admin action).
     * Triggers key rotation to prevent the removed member from reading future messages.
     */
    suspend fun removeGroupMember(groupId: String, peerId: String) {
        val myId = keyManager.getPublicKeyBase64()
        val group = database.groupDao().getGroupById(groupId) ?: return
        if (group.ownerId != myId) {
            Log.w(TAG, "Only group owner can remove members")
            return
        }
        
        database.groupDao().removeMemberById(groupId, peerId)
        
        val removePayload = groupProtocol.createRemoveMemberPayload(groupId, peerId)
        sendRawText(removePayload.toString())
        
        // Rotate key so removed member can't read future messages
        rotateGroupKey(groupId)
        Log.i(TAG, "Removed member $peerId from group $groupId and rotated key")
    }

    suspend fun announcePublicGroup(chat: ChatEntity) {
        if (!chat.isGroup || !chat.isPublic) return
        val ownerId = keyManager.getPublicKeyBase64()
        val announce = JSONObject().apply {
            put("type", GROUP_ANNOUNCE_TYPE)
            put("groupId", chat.id)
            put("groupName", chat.name)
            put("groupDescription", chat.groupDescription ?: "")
            put("joinPolicy", chat.joinPolicy)
            put("ownerId", ownerId)
            put("timestamp", DateUtils.getCurrentIsoTimestamp())
        }
        sendRawText(announce.toString())
    }

    suspend fun sendGroupJoinEvent(groupId: String, peerId: String) {
        val nickname = context.getSharedPreferences("sada_app_state", Context.MODE_PRIVATE)
            .getString("user_nickname", "Peer ${peerId.take(8)}")
            ?: "Peer ${peerId.take(8)}"
        val event = JSONObject().apply {
            put("type", GroupProtocol.TYPE_GROUP_JOIN)
            put("groupId", groupId)
            put("peerId", peerId)
            put("nickname", nickname)
            put("timestamp", DateUtils.getCurrentIsoTimestamp())
        }
        sendRawText(event.toString())
    }

    private fun syncPublicGroupsCatalog() {
        scope.launch {
            val ownerId = keyManager.getPublicKeyBase64()
            val groups = runCatching {
                database.groupDao().getOwnedPublicGroups(ownerId).first()
            }.getOrDefault(emptyList())
            groups.forEach { group ->
                runCatching { announcePublicGroup(group) }
            }
        }
    }

    suspend fun sendGroupChatMessage(groupId: String, content: String) {
        val chat = database.chatDao().getChatById(groupId) ?: return
        val groupKey = chat.groupKey ?: return
        val myPeerId = keyManager.getPublicKeyBase64()
        val now = Date()
        
        val encrypted = encryptionManager.encryptWithSharedKey(content, groupKey)
        val groupMsg = groupProtocol.createGroupMessage(
            groupId = groupId,
            encryptedContent = encrypted,
            senderId = myPeerId
        )
        
        // Broadcast to all connected peers
        // In a more advanced version, we'd route this via MeshMessage
        sendRawText(groupMsg.toString())
        
        // Save locally in the correct group chat timeline.
        val localMessageId = UUID.randomUUID().toString()
        database.messageDao().insertMessage(
            MessageEntity(
                id = localMessageId,
                chatId = groupId,
                senderId = myPeerId,
                content = content,
                type = "text",
                status = "sent",
                timestamp = now,
                isFromMe = true
            )
        )
        database.chatDao().insertChat(
            chat.copy(
                lastMessage = content,
                lastMessageAt = now
            )
        )
    }

    private fun handleMediaHeader(json: JSONObject) {
        if (!FEATURE_MEDIA_ENABLED) {
            // Act as Raw Relay only: Do not process locally, just forward to peers
            scope.launch {
                val meshMsg = MeshMessage.fromJson(json)
                storeAndForward(meshMsg)
            }
            return
        }
        val messageId = json.getString("messageId")
        val fileName = json.getString("fileName")
        val mimeType = json.getString("mimeType")
        val senderId = json.optString("senderId", "unknown")
        val destinationId = json.optString("destinationId", "")
        val mediaKind = json.optString("mediaKind", "file")
        val durationMs = json.optLong("durationMs", 0L)
        val myId = keyManager.getPublicKeyBase64()
        if (destinationId.isNotBlank() && destinationId != myId) {
            return
        }
        mediaHeaderCache[messageId] = json
        
        scope.launch {
            val contactById = database.contactDao().getContactById(senderId)
            val contact = contactById ?: database.contactDao().getContactByPublicKey(senderId)
            val stableChatId = contact?.id ?: senderId
            val existingChat = database.chatDao().getChatById(stableChatId)
            database.chatDao().insertChat(
                if (existingChat != null) {
                    existingChat.copy(name = contact?.name ?: existingChat.name)
                } else {
                    ChatEntity(
                        id = stableChatId,
                        name = contact?.name ?: "Chat ${senderId.take(8)}"
                    )
                }
            )
            // Pre-create the message record as "pending"
            database.messageDao().insertMessage(
                MessageEntity(
                    id = messageId,
                    chatId = stableChatId,
                    senderId = senderId,
                    content = if (mediaKind == "voice") {
                        "Voice message (${durationMs / 1000}s)"
                    } else {
                        "Receiving file: $fileName"
                    },
                    type = if (mediaKind == "voice") "voice" else "media",
                    status = "receiving",
                    attachmentType = mimeType
                )
            )

            tryFinalizeMediaIfComplete(messageId)
        }
    }

    private fun handleMediaChunk(json: JSONObject) {
        if (!FEATURE_MEDIA_ENABLED) {
            // Act as Raw Relay only: Do not process locally, just forward to peers
            scope.launch {
                val meshMsg = MeshMessage.fromJson(json)
                storeAndForward(meshMsg)
            }
            return
        }
        val messageId = json.getString("messageId")
        val destinationId = json.optString("destinationId", "")
        val myId = keyManager.getPublicKeyBase64()
        if (destinationId.isNotBlank() && destinationId != myId) {
            return
        }
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
            tryFinalizeMediaIfComplete(messageId)
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

    private suspend fun tryFinalizeMediaIfComplete(messageId: String) {
        val header = mediaHeaderCache[messageId] ?: return
        val expectedChunks = header.optInt("chunkCount", 0)
        if (expectedChunks <= 0) return

        val receivedChunks = database.mediaChunkDao().getChunkCount(messageId)
        if (receivedChunks < expectedChunks) return

        val fileName = header.optString("fileName", "$messageId.bin")
        val mimeType = header.optString("mimeType", "application/octet-stream")
        val senderId = header.optString("senderId", "unknown")
        val mediaKind = header.optString("mediaKind", "file")
        val encrypted = header.optBoolean("encrypted", false)
        val checksum = header.optString("checksumSha256", "")

        val reassembled = reassembleMedia(messageId, fileName) ?: return
        var finalFile = reassembled

        if (encrypted) {
            val senderPublicKey = try {
                Base64.decode(senderId, Base64.DEFAULT)
            } catch (_: Exception) {
                null
            }
            if (senderPublicKey == null) {
                Log.e(TAG, "Cannot decrypt media $messageId: invalid sender key")
                return
            }

            runCatching {
                val encryptedBytes = reassembled.readBytes()
                if (checksum.isNotBlank() && sha256Bytes(encryptedBytes) != checksum) {
                    throw SecurityException("Encrypted media checksum mismatch")
                }
                val sharedSecret = encryptionManager.calculateSharedSecret(senderPublicKey)
                val plainBytes = encryptionManager.decryptBytes(encryptedBytes, sharedSecret)
                val decryptedFile = File(context.filesDir, "media/received/dec_$fileName")
                decryptedFile.parentFile?.mkdirs()
                decryptedFile.writeBytes(plainBytes)
                reassembled.delete()
                finalFile = decryptedFile
            }.onFailure { e ->
                Log.e(TAG, "Failed decrypting media $messageId", e)
                return
            }
        }

        database.messageDao().insertMessage(
            MessageEntity(
                id = messageId,
                chatId = senderId,
                senderId = senderId,
                content = if (mediaKind == "voice") {
                    "Voice message"
                } else {
                    "Received file: ${finalFile.name}"
                },
                type = if (mediaKind == "voice") "voice" else "media",
                status = "received",
                attachmentPath = finalFile.absolutePath,
                attachmentType = mimeType,
                isFromMe = false
            )
        )
        val mediaPreview = if (mediaKind == "voice") "Voice message" else "Received file: ${finalFile.name}"
        val existingChat = database.chatDao().getChatById(senderId)
        val contactById = database.contactDao().getContactById(senderId)
        val contact = contactById ?: database.contactDao().getContactByPublicKey(senderId)
        val stableChatId = contact?.id ?: senderId
        val stableChat = database.chatDao().getChatById(stableChatId)
        database.chatDao().insertChat(
            if (stableChat != null) {
                stableChat.copy(
                    name = contact?.name ?: stableChat.name,
                    lastMessage = mediaPreview,
                    lastMessageAt = Date(),
                    unreadCount = stableChat.unreadCount + 1
                )
            } else {
                ChatEntity(
                    id = stableChatId,
                    name = contact?.name ?: "Chat ${senderId.take(8)}",
                    lastMessage = mediaPreview,
                    lastMessageAt = Date(),
                    unreadCount = 1
                )
            }
        )
        mediaHeaderCache.remove(messageId)
    }

    suspend fun sendMedia(chatId: String, file: File, mimeType: String) {
        val messageId = UUID.randomUUID().toString()
        val data = file.readBytes()
        val totalChunks = (data.size + MediaProtocol.CHUNK_SIZE - 1) / MediaProtocol.CHUNK_SIZE
        val contactById = database.contactDao().getContactById(chatId)
        val contact = contactById ?: database.contactDao().getContactByPublicKey(chatId)
        val destinationId = contact?.publicKey?.takeIf { it.isNotBlank() } ?: contact?.id ?: ""
        if (destinationId.isBlank()) {
            Log.w(TAG, "sendMedia failed: destination not found for chatId=$chatId")
            return
        }
        
        // 1. Send Header
        val header = mediaProtocol.createHeader(messageId, file.name, file.length(), totalChunks, mimeType).apply {
            put("senderId", keyManager.getPublicKeyBase64())
            put("destinationId", destinationId)
        }
        sendRawText(header.toString())
        
        // 2. Send Chunks with slight delay for mesh safety
        for (i in 0 until totalChunks) {
            val start = i * MediaProtocol.CHUNK_SIZE
            val end = Math.min(start + MediaProtocol.CHUNK_SIZE, data.size)
            val chunkData = data.sliceArray(start until end)
            
            val chunk = mediaProtocol.createChunk(messageId, i, totalChunks, chunkData).apply {
                put("senderId", keyManager.getPublicKeyBase64())
                put("destinationId", destinationId)
            }
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

    suspend fun sendVoiceMessage(chatId: String, audioFile: File, durationMs: Long): Boolean {
        if (!audioFile.exists()) {
            Log.e(TAG, "Voice send failed: File does not exist")
            return false
        }
        val fileSize = audioFile.length()
        if (fileSize > 360 * 1024) { // 360KB limit
            Log.e(TAG, "Voice send failed: File too large ($fileSize bytes)")
            return false
        }

        val contactById = database.contactDao().getContactById(chatId)
        val contact = contactById ?: database.contactDao().getContactByPublicKey(chatId)
        if (contact == null) {
            Log.w(TAG, "Voice send failed: contact not found for $chatId")
            return false
        }

        val destinationPeerId = contact.publicKey?.takeIf { it.isNotBlank() } ?: contact.id
        val remotePubKey = runCatching { Base64.decode(destinationPeerId, Base64.DEFAULT) }.getOrNull()
        if (remotePubKey == null) {
            Log.w(TAG, "Voice send failed: destination public key invalid")
            return false
        }

        val messageId = UUID.randomUUID().toString()
        val senderId = keyManager.getPublicKeyBase64()

        return try {
            val audioBytes = audioFile.readBytes()
            val sharedSecret = encryptionManager.calculateSharedSecret(remotePubKey)
            val encryptedBytes = encryptionManager.encryptBytes(audioBytes, sharedSecret)
            val encryptedBase64 = Base64.encodeToString(encryptedBytes, Base64.DEFAULT)

            val meshMessage = MeshMessage(
                messageId = messageId,
                originalSenderId = senderId,
                finalDestinationId = destinationPeerId, // This is the contact's public key (stable)
                encryptedContent = encryptedBase64,
                type = MeshMessage.TYPE_VOICE,
                timestamp = Date(),
                metadata = mapOf("durationSeconds" to (durationMs / 1000).toInt(), "senderPublicKey" to senderId)
            )

            // Save locally first
            database.messageDao().insertMessage(
                MessageEntity(
                    id = messageId,
                    chatId = chatId,
                    senderId = senderId,
                    content = "[Voice Message]",
                    type = "voice",
                    status = "sending",
                    mediaLocalPath = audioFile.absolutePath,
                    mediaDuration = (durationMs / 1000).toInt(),
                    isFromMe = true,
                    timestamp = meshMessage.timestamp
                )
            )

            storeAndForward(meshMessage)
            database.messageDao().updateMessageStatus(messageId, "sent")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Voice message send failed", e)
            false
        }
    }

    private fun saveVoiceToCache(messageId: String, decryptedBytes: ByteArray): String? {
        return try {
            val dir = File(context.cacheDir, "media/voice")
            dir.mkdirs()
            val file = File(dir, "voice_${messageId}_${System.currentTimeMillis()}.m4a")
            file.writeBytes(decryptedBytes)
            file.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save voice to cache", e)
            null
        }
    }

    private suspend fun handleSos(json: JSONObject, rssi: Int?, snr: Double?) {
        val messageId = json.getString("messageId")
        val senderId = json.getString("senderId")
        val latitude = json.optDouble("latitude")
        val longitude = json.optDouble("longitude")
        val timestamp = parseTimestampMillis(json, "timestamp")
        val hopCount = json.optInt("hopCount", 0)

        if (processedMessageIds.contains(messageId)) return
        markSeen(messageId)

        Log.w(TAG, "EMERGENCY: Received SOS from $senderId (Hops: $hopCount)")

        // 1. Save to Emergency Chat
        val emergencyChatId = "SYSTEM_EMERGENCY"
        val emergencyExisting = database.chatDao().getChatById(emergencyChatId)
        database.chatDao().insertChat(
            if (emergencyExisting != null) {
                emergencyExisting.copy(
                    lastMessage = "SOS from ${senderId.take(8)}",
                    lastMessageAt = Date(timestamp),
                    unreadCount = emergencyExisting.unreadCount + 1
                )
            } else {
                ChatEntity(
                    id = emergencyChatId,
                    name = "EMERGENCY / طوارئ",
                    lastMessage = "SOS from ${senderId.take(8)}",
                    lastMessageAt = Date(timestamp),
                    unreadCount = 1
                )
            }
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
        if (!isAppInForeground()) {
            notificationManager.showSosNotification(
                body = "SOS from ${senderId.take(8)}"
            )
        }

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
        val timestamp = System.currentTimeMillis()

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

    suspend fun sendMissingPersonBroadcast(name: String, description: String, lastSeen: String) {
        val messageId = UUID.randomUUID().toString()
        val myId = keyManager.getPublicKeyBase64()
        val timestamp = System.currentTimeMillis()

        val payload = JSONObject().apply {
            put("type", TYPE_BROADCAST_MISSING)
            put("messageId", messageId)
            put("senderId", myId)
            put("name", name)
            put("description", description)
            put("lastSeen", lastSeen)
            put("timestamp", timestamp)
            put("hopCount", 0)
        }

        val jsonStr = payload.toString()

        // 1. Save locally
        handleMissingPersonBroadcast(payload)

        // 2. Broadcast (Flooding)
        _connectedPeers.value.forEach { sendRawText(jsonStr) }

        if (loraInterface?.isConnected?.value == true) {
            val data = jsonStr.toByteArray(Charsets.UTF_8)
            val fragments = loraPacketizer.fragment(messageId, data)
            fragments.forEach { loraInterface.sendData(it) }
        }
    }

    private suspend fun handleMissingPersonBroadcast(json: JSONObject) {
        val messageId = json.getString("messageId")
        val senderId = json.getString("senderId")
        val name = json.getString("name")
        val description = json.getString("description")
        val lastSeen = json.getString("lastSeen")
        val timestamp = parseTimestampMillis(json, "timestamp")
        val hopCount = json.optInt("hopCount", 0)

        if (processedMessageIds.contains(messageId)) return
        markSeen(messageId)

        Log.w(TAG, "MISSING PERSON ALERT: Received for $name (Hops: $hopCount)")

        val chatId = "SYSTEM_EMERGENCY"
        database.messageDao().insertMessage(
            MessageEntity(
                id = messageId,
                chatId = chatId,
                senderId = senderId,
                content = "🚨 مفقود: $name\nوصف: $description\nآخر ظهور: $lastSeen",
                type = "missing_person",
                status = "received",
                timestamp = Date(timestamp),
                isRelayed = hopCount > 0
            )
        )

        if (!isAppInForeground()) {
            notificationManager.showMissingPersonNotification(
                body = "🚨 بلاغ عن مفقود: $name"
            )
        }

        // Rebroadcast if within limit
        if (hopCount < SOS_MAX_HOPS) {
            val rebroadcast = JSONObject(json.toString()).apply {
                put("hopCount", hopCount + 1)
            }
            val jsonStr = rebroadcast.toString()
            _connectedPeers.value.forEach { sendRawText(jsonStr) }
            
            if (loraInterface?.isConnected?.value == true) {
                val data = jsonStr.toByteArray(Charsets.UTF_8)
                val fragments = loraPacketizer.fragment(messageId, data)
                fragments.forEach { loraInterface.sendData(it) }
            }
        }
    }

    private fun parseTimestampMillis(json: JSONObject, key: String): Long {
        val raw = json.opt(key) ?: return System.currentTimeMillis()
        return when (raw) {
            is Number -> raw.toLong()
            is String -> raw.toLongOrNull()
                ?: runCatching { DateUtils.parseIso(raw).time }.getOrDefault(System.currentTimeMillis())
            else -> System.currentTimeMillis()
        }
    }

    fun getDiagnostics(): Map<String, Any> {
        val bleDiag = bleMeshManager.getDiagnostics()
        val wfdDiag = wifiDirectManager.getDiagnostics()
        val socketDiag = socketManager.getDiagnosticsInfo()
        return mapOf(
            "myPeerId" to keyManager.getPublicKeyBase64(),
            "connectedPeers" to _connectedPeers.value,
            "handshakeAttempts" to handshakeAttempts,
            "handshakeAcks" to handshakeAcks,
            "handshakeTimeouts" to handshakeTimeouts,
            "lastHandshakeReason" to lastHandshakeReason,
            "peerHandshakeState" to peerHandshakeState.toMap(),
            "peerHandshakeReason" to peerHandshakeReason.toMap(),
            "processedMessagesCount" to processedMessageIds.size,
            "knownBloomFilters" to peerBloomFilters.size,
            "lastError" to (_transportError.value ?: "None"),
            "isSocketConnected" to socketManager.isSocketConnected(),
            "isTransportConnected" to transportIsConnected(),
            "activeTransport" to activeTransportProvider(),
            "transportSentNearby" to transportSentNearby,
            "transportSentLan" to transportSentLan,
            "transportReceivedNearby" to transportReceivedNearby,
            "transportReceivedLan" to transportReceivedLan,
            "relayQueueActiveCount" to relayQueueActiveCount,
            "relayFlushedCount" to relayFlushedCount,
            "ackCleanupCount" to ackCleanupCount,
            "spamBlockedRequestsCount" to spamBlockedRequestsCount,
            "voice_sentCount" to voiceMessagesSent,
            "voice_receivedCount" to voiceMessagesReceived,
            // BLE diagnostics
            "service_ble_isAdvertising" to (bleDiag["isAdvertising"] ?: false),
            "service_ble_isScanning" to (bleDiag["isScanning"] ?: false),
            "service_ble_discoveredPeersCount" to (bleDiag["discoveredPeersCount"] ?: 0),
            "service_ble_peerIdLength" to (bleDiag["peerIdLength"] ?: 0),
            "service_ble_lastDiscoveredId" to (bleDiag["lastDiscoveredId"] ?: ""),
            // Wi-Fi Direct diagnostics
            "service_wifidirect_isDiscovering" to (wfdDiag["isDiscovering"] ?: false),
            "service_wifidirect_isConnected" to (wfdDiag["isConnected"] ?: false),
            "service_wifidirect_groupFormed" to (wfdDiag["groupFormed"] ?: false),
            "service_wifidirect_isGroupOwner" to (wfdDiag["isGroupOwner"] ?: false),
            "service_wifidirect_groupOwnerIp" to (wfdDiag["groupOwnerIp"] ?: "none"),
            // Socket diagnostics
            "socket_retryAttempts" to (socketDiag["retryAttempts"] ?: 0),
            "socket_lastConnectDelay" to (socketDiag["lastConnectDelay"] ?: "0ms"),
            "socket_serverReadyAt" to (socketDiag["serverReadyAt"] ?: 0L)
        )
    }

    private fun sha256(input: String): String {
        val bytes = input.toByteArray(Charsets.UTF_8)
        val md = java.security.MessageDigest.getInstance("SHA-256")
        val digest = md.digest(bytes)
        return digest.fold("") { str, it -> str + "%02x".format(it) }
    }

    private fun sha256Bytes(input: ByteArray): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(input)
        return digest.fold("") { str, byte -> str + "%02x".format(byte) }
    }

    private fun isAppInForeground(): Boolean {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager ?: return false
        val running = manager.runningAppProcesses ?: return false
        val packageName = context.packageName
        return running.any { proc ->
            proc.processName == packageName &&
                proc.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
        }
    }

    /**
     * Send a message to a group
     */
    suspend fun sendGroupMessage(groupId: String, message: MeshMessage): Result<Boolean> {
        // TODO: Implement group message routing
        return Result.success(true)
    }

    /**
     * Send a group announcement (admin only)
     */
    suspend fun sendGroupAnnouncement(groupId: String, message: MeshMessage): Result<Boolean> {
        // TODO: Implement group announcement routing
        return Result.success(true)
    }

    /*
     * ROADMAP: CONFLICT-ZONE SECURITY EXTENSIONS
     * ------------------------------------------
     * TODO [SECURITY-L2]: Anti-Forensics - Implement 'Stealth Mode' where the relay_queue is 
     * encrypted with a transient key derived from biometric/pattern unlock, making data 
     * unreadable if the device is seized while locked.
     * 
     * TODO [SECURITY-L3]: Self-Destruct - Add a 'Panic Trigger' in the UI and a 'Duress PIN'
     * that triggers immediate wipe of message history and the relay_queue.
     * 
     * TODO [SECURITY-L4]: Plausible Deniability - Implement 'Hidden Chats' inside the 
     * SQLite database using SQLCipher or similar, appearing as corrupted or random data 
     * unless the specific hidden key is provided.
     * 
     * TODO [NETWORK-L5]: Traffic Obfuscation - Mask Mesh packets as standard HTTPS or 
     * Bluetooth HID traffic to bypass Deep Packet Inspection (DPI) if used in-region.
     */

    private fun handleGroupRemove(json: JSONObject) {
        val groupId = json.getString("groupId")
        val removedPeerId = json.getString("removedPeerId")
        val senderId = json.optString("senderId", "")
        val senderRole = json.optString("senderRole", "admin")
        val timestamp = json.optLong("timestamp", System.currentTimeMillis())

        scope.launch {
            val chat = database.chatDao().getChatById(groupId)
            if (chat == null || !chat.isGroup) return@launch

            // 1. Conflict Resolution Logic
            if (!shouldApplyGroupAction(groupId, senderId, senderRole, timestamp)) {
                Log.d(TAG, "Group removal ignored: conflict resolution rejected action from $senderId")
                return@launch
            }

            // 2. Apply action
            database.groupDao().removeMemberById(groupId, removedPeerId)
            
            // If I am the one removed
            if (removedPeerId == keyManager.getPublicKeyBase64()) {
                database.chatDao().updateChatStatus(groupId, "removed")
                Log.w(TAG, "I have been removed from group $groupId")
            }
        }
    }

    private suspend fun shouldApplyGroupAction(
        groupId: String,
        senderId: String,
        senderRole: String,
        newTimestamp: Long
    ): Boolean {
        val currentUserId = keyManager.getPublicKeyBase64()
        if (senderId == currentUserId || senderId.isEmpty()) return true 

        val chat = database.chatDao().getChatById(groupId) ?: return true
        
        // Ownership Supremacy
        if (senderId == chat.ownerId) return true 
        
        // Check sender's actual role in our local database
        val senderMember = database.groupDao().getMember(groupId, senderId)
        val actualRole = senderMember?.role ?: senderRole

        // Hierarchy: Owner > Admin > Member
        val rolePriority = mapOf("owner" to 3, "admin" to 2, "member" to 1, "banned" to 0)
        val senderPriority = rolePriority[actualRole] ?: 0
        
        // If sender is a member trying to perform admin action, reject
        if (senderPriority < 2) return false 

        return true 
    }

    private fun handleSyncRequest(json: JSONObject) {
        val groupId = json.getString("groupId")
        val limit = json.optInt("limit", 50)

        scope.launch {
            val chat = database.chatDao().getChatById(groupId) ?: return@launch
            if (!chat.isGroup) return@launch

            val messages = database.messageDao().getLatestMessagesForChat(groupId, limit)
            val jsonMessages = JSONArray()
            val groupKey = database.chatDao().getGroupKey(groupId) ?: return@launch
            
            messages.forEach { msg ->
                val encrypted = encryptionManager.encryptWithSharedKey(msg.content, groupKey)
                if (encrypted.isNotEmpty()) {
                    val m = JSONObject().apply {
                        put("senderId", msg.senderId)
                        put("content", encrypted)
                        put("timestamp", msg.timestamp.time)
                    }
                    jsonMessages.put(m)
                }
            }

            if (jsonMessages.length() > 0) {
                val response = syncProtocol.createSyncResponse(groupId, jsonMessages)
                sendRawText(response.toString())
            }
        }
    }

    private fun handleSyncResponse(json: JSONObject) {
        val groupId = json.getString("groupId")
        val messages = json.getJSONArray("messages")

        scope.launch {
            for (i in 0 until messages.length()) {
                val msgJson = messages.getJSONObject(i)
                val senderId = msgJson.getString("senderId")
                val encryptedContent = msgJson.getString("content")
                val timestamp = msgJson.getLong("timestamp")

                val groupKey = database.chatDao().getGroupKey(groupId) ?: continue
                val decrypted = encryptionManager.decryptWithSharedKey(encryptedContent, groupKey) ?: continue
                val existing = database.messageDao().getMessageByContentAndTimestamp(decrypted, timestamp)
                if (existing == null) {
                    database.messageDao().insertMessage(
                        MessageEntity(
                            id = UUID.randomUUID().toString(),
                            chatId = groupId,
                            senderId = senderId,
                            content = decrypted,
                            type = "text",
                            status = "received",
                            timestamp = Date(timestamp)
                        )
                    )
                }
            }
        }
    }

    suspend fun requestGroupHistory(groupId: String) {
        val request = syncProtocol.createSyncRequest(groupId)
        sendRawText(request.toString())
    }
}
