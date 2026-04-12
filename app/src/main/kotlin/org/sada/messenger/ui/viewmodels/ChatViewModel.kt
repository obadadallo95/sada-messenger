package org.sada.messenger.ui.viewmodels

import android.util.Base64
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import org.sada.messenger.managers.AudioRecorderManager
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.data.entities.MessageEntity
import org.sada.messenger.data.entities.ChatEntity
import org.sada.messenger.data.entities.ContactEntity
import org.sada.messenger.data.entities.GroupMemberEntity
import org.sada.messenger.data.models.MeshMessage
import org.sada.messenger.network.MeshEngine
import org.sada.messenger.security.EncryptionManager
import org.sada.messenger.security.KeyManager
import java.util.*
import java.io.File

class ChatViewModel(
    private val chatId: String,
    private val database: AppDatabase,
    private val meshEngine: MeshEngine,
    private val keyManager: KeyManager,
    private val encryptionManager: EncryptionManager,
    private val audioRecorderManager: AudioRecorderManager
) : ViewModel() {
    private val tag = "ChatViewModel"

    private val _isVoiceRecording = MutableStateFlow(false)
    val isVoiceRecording: StateFlow<Boolean> = _isVoiceRecording.asStateFlow()

    // Reply functionality
    private val _replyToMessage = MutableStateFlow<MessageEntity?>(null)
    val replyToMessage: StateFlow<MessageEntity?> = _replyToMessage.asStateFlow()

    // Forward functionality
    private val _messageToForward = MutableStateFlow<MessageEntity?>(null)
    val messageToForward: StateFlow<MessageEntity?> = _messageToForward.asStateFlow()

    private var currentRecordingFile: File? = null
    private var recordingStartedAtMs: Long = 0L

    val messages: StateFlow<List<MessageEntity>> = database.messageDao()
        .getMessagesByChatId(chatId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val _amplitude = MutableStateFlow(0f)
    val amplitude: StateFlow<Float> = _amplitude.asStateFlow()

    private val _recordingDurationSeconds = MutableStateFlow(0)
    val recordingDurationSeconds: StateFlow<Int> = _recordingDurationSeconds.asStateFlow()

    private val _isSelectionMode = MutableStateFlow(false)
    val isSelectionMode: StateFlow<Boolean> = _isSelectionMode.asStateFlow()

    private val _selectedMessageIds = MutableStateFlow<Set<String>>(emptySet())
    val selectedMessageIds: StateFlow<Set<String>> = _selectedMessageIds.asStateFlow()

    val contact: StateFlow<org.sada.messenger.data.entities.ContactEntity?> = database.contactDao()
        .getContactByIdFlow(chatId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    private val requestForChat: Flow<org.sada.messenger.data.entities.ConnectionRequestEntity?> =
        database.connectionRequestDao().getRequestByPeerIdFlow(chatId)

    val pendingConnectionRequest: StateFlow<org.sada.messenger.data.entities.ConnectionRequestEntity?> = combine(
        contact,
        requestForChat
    ) { c, r ->
        if (c?.isVerified == true) null else r?.takeIf { it.status == "pending" && it.type == "incoming" }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    val isOutgoingRequestPending: StateFlow<Boolean> = combine(
        contact,
        requestForChat
    ) { c, r ->
        c?.isVerified != true && r?.status == "pending" && r.type == "outgoing"
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), false)

    // For Forward dialog - all contacts and groups
    val allContacts: StateFlow<List<ContactEntity>> = database.contactDao()
        .getAllContacts()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    
    val allGroups: StateFlow<List<ChatEntity>> = database.groupDao()
        .getAllGroups()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    init {
        viewModelScope.launch {
            markChatAsRead()
            cleanupRequestsIfVerified()
        }
        setupAudioCallbacks()
    }

    private fun setupAudioCallbacks() {
        audioRecorderManager.onAmplitudeChanged = { amp ->
            _amplitude.value = amp
        }
        audioRecorderManager.onMaxDurationReached = {
            stopVoiceRecordingAndSend()
        }
        
        // Timer for recording duration
        viewModelScope.launch {
            while (true) {
                if (_isVoiceRecording.value && recordingStartedAtMs > 0) {
                    _recordingDurationSeconds.value = ((System.currentTimeMillis() - recordingStartedAtMs) / 1000).toInt()
                } else {
                    _recordingDurationSeconds.value = 0
                }
                kotlinx.coroutines.delay(500)
            }
        }
    }

    fun sendMessage(content: String) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            val timestamp = Date()
            val messageId = UUID.randomUUID().toString()
            val trimmedContent = content.trim()
            if (trimmedContent.isBlank()) return@launch

            // Get reply info if any
            val replyTo = _replyToMessage.value
            val replyToId = replyTo?.id
            val replyToSender = replyTo?.let { 
                if (it.isFromMe) "You" else database.contactDao().getContactById(it.senderId)?.name ?: "Unknown"
            }
            val replyToContent = replyTo?.content?.take(100) // Limit preview length

            val contact = database.contactDao().getContactById(chatId) 
                ?: database.contactDao().getContactByPublicKey(chatId)
            
            val stableChatId = contact?.id ?: chatId
            val destinationPeerId = contact?.publicKey?.takeIf { it.isNotBlank() } ?: stableChatId
            val chatName = contact?.name ?: "Chat ${stableChatId.take(8)}"

            // Check group restrictions
            val chat = database.chatDao().getChatById(stableChatId)
            if (chat?.isGroup == true) {
                // Check if new member is restricted
                if (chat.restrictNewMembers) {
                    val member = database.groupDao().getMember(stableChatId, myId)
                    if (member != null && member.joinedAt != null) {
                        val hoursSinceJoin = (System.currentTimeMillis() - member.joinedAt.time) / (1000 * 60 * 60)
                        if (hoursSinceJoin < 24 && !database.groupDao().isUserAdminOrOwner(stableChatId, myId)) {
                            // New member cannot send messages within first 24 hours
                            return@launch
                        }
                    }
                }
                
                // Check slow mode
                val slowModeSeconds = chat.slowModeSeconds
                if (slowModeSeconds > 0 && !database.groupDao().isUserAdminOrOwner(stableChatId, myId)) {
                    val lastMessage = database.chatDao().getLatestMessage(stableChatId)
                    if (lastMessage != null) {
                        val secondsSinceLastMessage = (System.currentTimeMillis() - lastMessage.timestamp.time) / 1000
                        if (secondsSinceLastMessage < slowModeSeconds.toLong()) {
                            // Too soon to send another message
                            return@launch
                        }
                    }
                }
            }

            // Local insertion
            database.messageDao().insertMessage(
                MessageEntity(
                    id = messageId,
                    chatId = stableChatId,
                    senderId = myId,
                    content = trimmedContent,
                    timestamp = timestamp,
                    isFromMe = true,
                    status = "sending",
                    replyToId = replyToId,
                    replyToSender = replyToSender,
                    replyToContent = replyToContent
                )
            )
            
            // Clear reply after sending
            clearReplyTo()
            
            // Ensure chat entry
            val existingChat = database.chatDao().getChatById(stableChatId)
            database.chatDao().insertChat(
                existingChat?.copy(
                    lastMessage = trimmedContent,
                    lastMessageAt = timestamp
                ) ?: ChatEntity(
                    id = stableChatId,
                    name = chatName,
                    lastMessage = trimmedContent,
                    lastMessageAt = timestamp
                )
            )

            // Direct Message via Mesh
            if (contact != null) {
                val sent = try {
                    val remotePubKey = Base64.decode(destinationPeerId, Base64.DEFAULT)
                    val sharedSecret = encryptionManager.calculateSharedSecret(remotePubKey)
                    val encrypted = encryptionManager.encryptMessage(trimmedContent, sharedSecret)
                    val meshMessage = MeshMessage(
                        messageId = messageId,
                        originalSenderId = myId,
                        finalDestinationId = destinationPeerId,
                        encryptedContent = encrypted,
                        timestamp = timestamp
                    )
                    meshEngine.sendMeshMessage(meshMessage)
                } catch (e: Exception) {
                    Log.e(tag, "Failed sending id=$messageId", e)
                    false
                }
                database.messageDao().updateMessageStatus(messageId, if (sent) "sent" else "failed")
            }
        }
    }

    fun startVoiceRecording() {
        if (_isVoiceRecording.value) return
        val outputFile = audioRecorderManager.createVoiceTempFile()
        val started = audioRecorderManager.startRecording(outputFile)
        if (started) {
            currentRecordingFile = outputFile
            recordingStartedAtMs = System.currentTimeMillis()
            _isVoiceRecording.value = true
        }
    }

    fun cancelVoiceRecording() {
        if (!_isVoiceRecording.value) return
        audioRecorderManager.cancelRecording()
        _isVoiceRecording.value = false
        currentRecordingFile = null
        recordingStartedAtMs = 0L
    }

    fun stopVoiceRecordingAndSend() {
        if (!_isVoiceRecording.value) return
        val durationMs = (System.currentTimeMillis() - recordingStartedAtMs).coerceAtLeast(0L)
        val recordedFile = audioRecorderManager.stopRecording() ?: currentRecordingFile
        
        _isVoiceRecording.value = false
        currentRecordingFile = null
        recordingStartedAtMs = 0L
        
        if (recordedFile == null || !recordedFile.exists() || durationMs < 500L) {
            recordedFile?.delete()
            return
        }

        viewModelScope.launch {
            meshEngine.sendVoiceMessage(chatId, recordedFile, durationMs)
        }
    }

    fun toggleMessageSelection(messageId: String) {
        val current = _selectedMessageIds.value
        _selectedMessageIds.value = if (current.contains(messageId)) {
            current - messageId
        } else {
            current + messageId
        }
        _isSelectionMode.value = _selectedMessageIds.value.isNotEmpty()
    }

    fun acceptConnectionRequest(requestId: String) {
        viewModelScope.launch {
            val contactVal = contact.value ?: return@launch
            meshEngine.acceptConnectionRequest(requestId, chatId, contactVal.publicKey ?: chatId)
        }
    }

    fun rejectConnectionRequest(requestId: String) {
        viewModelScope.launch {
            meshEngine.rejectConnectionRequest(requestId, chatId)
        }
    }

    fun resendConnectionRequest() {
        viewModelScope.launch {
            val contactVal = contact.value ?: return@launch
            meshEngine.sendConnectionRequest(chatId, contactVal.name, contactVal.publicKey ?: chatId)
        }
    }

    fun enterSelectionMode(messageId: String) {
        _isSelectionMode.value = true
        _selectedMessageIds.value = setOf(messageId)
    }

    fun exitSelectionMode() {
        _isSelectionMode.value = false
        _selectedMessageIds.value = emptySet()
    }

    // Reply functions
    fun setReplyTo(message: MessageEntity) {
        _replyToMessage.value = message
    }

    fun clearReplyTo() {
        _replyToMessage.value = null
    }

    fun setForwardMessage(message: MessageEntity) {
        _messageToForward.value = message
    }

    fun clearForwardMessage() {
        _messageToForward.value = null
    }

    // Forward message to another chat or group
    fun forwardMessage(originalMessage: MessageEntity, targetChatId: String) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            val timestamp = Date()
            val newMessageId = UUID.randomUUID().toString()
            
            // Check if target is a group
            val targetChat = database.chatDao().getChatById(targetChatId)
            val isGroup = targetChat?.isGroup ?: false
            
            // Create forwarded message
            val forwardedMessage = MessageEntity(
                id = newMessageId,
                chatId = targetChatId,
                senderId = myId,
                content = originalMessage.content,
                timestamp = timestamp,
                isFromMe = true,
                status = "sending",
                type = originalMessage.type,
                isVoice = originalMessage.isVoice,
                voiceDurationMs = originalMessage.voiceDurationMs,
                latitude = originalMessage.latitude,
                longitude = originalMessage.longitude,
                // Don't copy replyToId - forwarded message should not reference original reply
                replyToId = null,
                replyToSender = null,
                replyToContent = null
            )
            
            // Save to local database
            database.messageDao().insertMessage(forwardedMessage)
            
            // Update chat last message
            val existingChat = database.chatDao().getChatById(targetChatId)
            database.chatDao().insertChat(
                existingChat?.copy(
                    lastMessage = "[Forwarded] ${originalMessage.content.take(30)}",
                    lastMessageAt = timestamp
                ) ?: ChatEntity(
                    id = targetChatId,
                    name = "Chat ${targetChatId.take(8)}",
                    lastMessage = "[Forwarded] ${originalMessage.content.take(30)}",
                    lastMessageAt = timestamp,
                    unreadCount = 0,
                    isGroup = isGroup
                )
            )
            
            // Send via mesh
            if (isGroup && targetChat != null) {
                // Send as group message - use original content (group encryption handled in MeshEngine)
                val meshMsg = MeshMessage(
                    messageId = newMessageId,
                    originalSenderId = myId,
                    finalDestinationId = targetChatId,
                    encryptedContent = originalMessage.content,
                    timestamp = Date(),
                    type = "forward"
                )
                meshEngine.sendGroupMessage(targetChatId, meshMsg)
            } else {
                // Send as direct message
                val contact = database.contactDao().getContactById(targetChatId)
                    ?: database.contactDao().getContactByPublicKey(targetChatId)
                val destinationPeerId = contact?.publicKey?.takeIf { it.isNotBlank() } ?: targetChatId
                
                val meshMessage = MeshMessage(
                    messageId = newMessageId,
                    originalSenderId = myId,
                    finalDestinationId = destinationPeerId,
                    encryptedContent = originalMessage.content,
                    timestamp = timestamp,
                    type = forwardedMessage.type
                )

                val contactForKey = database.contactDao().getContactByPublicKey(destinationPeerId)
                val pubKey = contactForKey?.publicKey?.takeIf { it.isNotBlank() } ?: destinationPeerId
                val pubBytes = Base64.decode(pubKey, Base64.DEFAULT)
                val sharedSecret = encryptionManager.calculateSharedSecret(pubBytes)
                val encryptedContent = encryptionManager.encryptMessage(meshMessage.encryptedContent, sharedSecret)
                    ?: meshMessage.encryptedContent

                val toSend = meshMessage.copy(encryptedContent = encryptedContent)
                meshEngine.sendMeshMessage(toSend)
            }
        }
    }

    // Pin message functionality
    fun pinMessage(messageId: String) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            val timestamp = Date()
            database.messageDao().pinMessage(messageId, myId, timestamp)
        }
    }

    fun unpinMessage(messageId: String) {
        viewModelScope.launch {
            database.messageDao().unpinMessage(messageId)
        }
    }

    // Edit message functionality
    fun editMessage(messageId: String, newContent: String) {
        viewModelScope.launch {
            val message = database.messageDao().getMessageById(messageId)
            if (message != null && message.isFromMe && newContent.isNotBlank()) {
                val timestamp = Date()
                // Update local database
                database.messageDao().editMessage(messageId, newContent.trim(), timestamp)
                
                // TODO: Send edit notification via mesh network
                // This would require a new protocol message type
            }
        }
    }

    // State for message being edited
    private val _editingMessage = MutableStateFlow<MessageEntity?>(null)
    val editingMessage: StateFlow<MessageEntity?> = _editingMessage.asStateFlow()

    fun startEditing(message: MessageEntity) {
        if (message.isFromMe) {
            _editingMessage.value = message
        }
    }

    fun cancelEditing() {
        _editingMessage.value = null
    }

    val pinnedMessages: StateFlow<List<MessageEntity>> = database.messageDao()
        .getPinnedMessages(chatId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun deleteSelectedMessages() {
        val ids = _selectedMessageIds.value.toList()
        if (ids.isEmpty()) return
        viewModelScope.launch {
            database.messageDao().deleteMessagesByIds(ids)
            exitSelectionMode()
        }
    }

    fun deleteMessage(messageId: String) {
        viewModelScope.launch {
            database.messageDao().deleteMessageById(messageId)
        }
    }

    // Group admin functions
    fun promoteToAdmin(peerId: String) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            if (database.groupDao().isUserOwner(chatId, myId)) {
                database.groupDao().updateMemberRole(chatId, peerId, "admin")
                val msg = MeshMessage(messageId = java.util.UUID.randomUUID().toString(), originalSenderId = myId, finalDestinationId = chatId, encryptedContent = "User promoted to admin", timestamp = Date(), type = "announcement")
                meshEngine.sendGroupAnnouncement(chatId, msg)
            }
        }
    }

    fun demoteToMember(peerId: String) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            if (database.groupDao().isUserOwner(chatId, myId)) {
                database.groupDao().updateMemberRole(chatId, peerId, "member")
                val msg = MeshMessage(messageId = java.util.UUID.randomUUID().toString(), originalSenderId = myId, finalDestinationId = chatId, encryptedContent = "Admin demoted to member", timestamp = Date(), type = "announcement")
                meshEngine.sendGroupAnnouncement(chatId, msg)
            }
        }
    }

    fun kickMember(peerId: String) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            if (database.groupDao().isUserOwner(chatId, myId) || 
                database.groupDao().isUserAdminOrOwner(chatId, myId)) {
                meshEngine.removeGroupMember(chatId, peerId)
            }
        }
    }

    fun banMember(peerId: String) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            if (database.groupDao().isUserOwner(chatId, myId) || 
                database.groupDao().isUserAdminOrOwner(chatId, myId)) {
                database.groupDao().banMember(chatId, peerId)
                meshEngine.removeGroupMember(chatId, peerId)
                val msg = MeshMessage(messageId = java.util.UUID.randomUUID().toString(), originalSenderId = myId, finalDestinationId = chatId, encryptedContent = "User has been banned from the group", timestamp = Date(), type = "announcement")
                meshEngine.sendGroupAnnouncement(chatId, msg)
            }
        }
    }

    fun unbanMember(peerId: String) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            if (database.groupDao().isUserOwner(chatId, myId) || 
                database.groupDao().isUserAdminOrOwner(chatId, myId)) {
                database.groupDao().unbanMember(chatId, peerId)
            }
        }
    }

    val bannedMembers: StateFlow<List<GroupMemberEntity>> = if (contact.value?.isGroup == true) {
        database.groupDao().getBannedMembers(chatId)
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    } else {
        MutableStateFlow<List<GroupMemberEntity>>(emptyList())
    }

    suspend fun isCurrentUserAdminOrOwner(): Boolean {
        val myId = keyManager.getPublicKeyBase64()
        return database.groupDao().isUserAdminOrOwner(chatId, myId)
    }

    suspend fun isCurrentUserOwner(): Boolean {
        val myId = keyManager.getPublicKeyBase64()
        return database.groupDao().isUserOwner(chatId, myId)
    }

    // Group restriction management
    fun setSlowMode(seconds: Int) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            if (database.groupDao().isUserAdminOrOwner(chatId, myId)) {
                database.groupDao().setSlowMode(chatId, seconds)
            }
        }
    }

    fun setRestrictNewMembers(restricted: Boolean) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            if (database.groupDao().isUserOwner(chatId, myId)) {
                database.groupDao().setRestrictNewMembers(chatId, restricted)
            }
        }
    }

    fun setRequireAdminApproval(required: Boolean) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            if (database.groupDao().isUserOwner(chatId, myId)) {
                database.groupDao().setRequireAdminApproval(chatId, required)
            }
        }
    }

    fun clearChatContent() {
        viewModelScope.launch {
            try {
                val messageIds = database.messageDao().getMessageIdsByChatOrSender(chatId)
                messageIds.forEach { id ->
                    database.relayQueueDao().removeByMessageId(id)
                }
                database.messageDao().deleteByChatOrSender(chatId)
                
                val chat = database.chatDao().getChatById(chatId)
                if (chat != null) {
                    database.chatDao().insertChat(chat.copy(lastMessage = null, lastMessageAt = null, unreadCount = 0))
                }
            } catch (e: Exception) {
                Log.e(tag, "Clear chat failed", e)
            }
        }
    }

    private suspend fun markChatAsRead() {
        val chat = database.chatDao().getChatById(chatId)
        if (chat != null && chat.unreadCount > 0) {
            database.chatDao().insertChat(chat.copy(unreadCount = 0))
        }
    }

    private suspend fun cleanupRequestsIfVerified() {
        val c = contact.value ?: return
        if (!c.isVerified) return
        val key = c.publicKey?.takeIf { it.isNotBlank() } ?: c.id
        database.connectionRequestDao().deleteByPeerIdOrPublicKey(chatId, key)
        if (chatId != c.id) {
            database.connectionRequestDao().deleteByPeerIdOrPublicKey(c.id, key)
        }
    }

    fun sendMediaMessage(file: java.io.File, mimeType: String) {
        viewModelScope.launch {
            meshEngine.sendMedia(chatId, file, mimeType)
        }
    }
}
