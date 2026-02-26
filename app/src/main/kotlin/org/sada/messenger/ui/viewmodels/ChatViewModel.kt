package org.sada.messenger.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.data.entities.MessageEntity
import org.sada.messenger.data.models.MeshMessage
import org.sada.messenger.network.MeshEngine
import org.sada.messenger.security.EncryptionManager
import org.sada.messenger.security.KeyManager
import java.util.*

class ChatViewModel(
    private val chatId: String,
    private val database: AppDatabase,
    private val meshEngine: MeshEngine,
    private val keyManager: KeyManager,
    private val encryptionManager: EncryptionManager
) : ViewModel() {

    val messages: StateFlow<List<MessageEntity>> = database.messageDao()
        .getMessagesByChatId(chatId)
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    fun sendMessage(content: String) {
        viewModelScope.launch {
            val chat = database.chatDao().getChatById(chatId) ?: return@launch
            val myId = keyManager.getPublicKeyBase64()
            val timestamp = Date()
            val messageId = UUID.randomUUID().toString()

            if (chat.isGroup) {
                // Group Message
                meshEngine.sendGroupChatMessage(chatId, content)
            } else {
                // Direct Message
                val contact = database.contactDao().getContactById(chatId) ?: return@launch
                val remotePublicKey = contact.publicKey
                if (remotePublicKey.isNullOrBlank()) {
                    database.messageDao().insertMessage(
                        MessageEntity(
                            id = messageId,
                            chatId = chatId,
                            senderId = myId,
                            content = content,
                            timestamp = timestamp,
                            isFromMe = true,
                            status = "failed"
                        )
                    )
                    return@launch
                }
                val remotePubKey = android.util.Base64.decode(
                    remotePublicKey,
                    android.util.Base64.DEFAULT
                )
                
                val sharedSecret = encryptionManager.calculateSharedSecret(remotePubKey)
                val encrypted = encryptionManager.encryptMessage(content, sharedSecret)
                
                val meshMessage = MeshMessage(
                    messageId = messageId,
                    originalSenderId = myId,
                    finalDestinationId = chatId,
                    encryptedContent = encrypted,
                    timestamp = timestamp
                )
                
                // Save locally first
                database.messageDao().insertMessage(
                    MessageEntity(
                        id = messageId,
                        chatId = chatId,
                        senderId = myId,
                        content = content,
                        timestamp = timestamp,
                        isFromMe = true,
                        status = "sending"
                    )
                )
                
                // Hand over to mesh engine (actual transport path)
                val sent = meshEngine.sendMeshMessage(meshMessage)
                if (!sent) {
                    database.messageDao().updateMessageStatus(messageId, "failed")
                } else {
                    database.messageDao().updateMessageStatus(messageId, "sent")
                }
            }
        }
    }

    fun sendMediaMessage(file: java.io.File, mimeType: String) {
        viewModelScope.launch {
            meshEngine.sendMedia(chatId, file, mimeType)
        }
    }
}
