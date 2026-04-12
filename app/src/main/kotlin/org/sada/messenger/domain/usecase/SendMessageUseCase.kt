package org.sada.messenger.domain.usecase

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.data.entities.MessageEntity
import org.sada.messenger.network.MeshEngine
import org.sada.messenger.security.KeyManager
import org.sada.messenger.security.EncryptionManager
import java.util.*
import javax.inject.Inject

/**
 * Use Case: Send Message
 * Handles the business logic of sending a message with all validations
 */
class SendMessageUseCase @Inject constructor(
    private val database: AppDatabase,
    private val meshEngine: MeshEngine,
    private val keyManager: KeyManager,
    private val encryptionManager: EncryptionManager
) {
    operator fun invoke(
        chatId: String,
        content: String,
        replyToId: String? = null,
        replyToSender: String? = null,
        replyToContent: String? = null
    ): Flow<Result<String>> = flow {
        try {
            val myId = keyManager.getPublicKeyBase64()
            val messageId = UUID.randomUUID().toString()
            val timestamp = Date()
            val trimmedContent = content.trim()

            if (trimmedContent.isBlank()) {
                emit(Result.failure(IllegalArgumentException("Message cannot be empty")))
                return@flow
            }

            // Check group restrictions
            val chat = database.chatDao().getChatById(chatId)
            if (chat?.isGroup == true) {
                if (!canSendMessage(chatId, myId)) {
                    emit(Result.failure(SecurityException("Not authorized to send message")))
                    return@flow
                }
            }

            // Create message entity
            val message = MessageEntity(
                id = messageId,
                chatId = chatId,
                senderId = myId,
                content = trimmedContent,
                timestamp = timestamp,
                isFromMe = true,
                status = "sending",
                replyToId = replyToId,
                replyToSender = replyToSender,
                replyToContent = replyToContent?.take(100)
            )

            // Save to database
            database.messageDao().insertMessage(message)

            // Update chat last message
            updateChatLastMessage(chatId, trimmedContent, timestamp)

            // Send via mesh
            sendViaMesh(chatId, message)

            emit(Result.success(messageId))
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    private suspend fun canSendMessage(chatId: String, myId: String): Boolean {
        val chat = database.chatDao().getChatById(chatId) ?: return false

        // Check if admin/owner
        val isAdmin = database.groupDao().isUserAdminOrOwner(chatId, myId)
        if (isAdmin) return true

        // Check slow mode
        val slowModeSeconds = chat.slowModeSeconds
        if (slowModeSeconds > 0) {
            val lastMessage = database.chatDao().getLatestMessage(chatId)
            if (lastMessage != null) {
                val secondsSince = (System.currentTimeMillis() - lastMessage.timestamp.time) / 1000
                if (secondsSince < slowModeSeconds.toLong()) {
                    return false
                }
            }
        }

        // Check new member restriction
        if (chat.restrictNewMembers) {
            val member = database.groupDao().getMember(chatId, myId)
            if (member?.joinedAt != null) {
                val hoursSinceJoin = (System.currentTimeMillis() - member.joinedAt.time) / (1000 * 60 * 60)
                if (hoursSinceJoin < 24) {
                    return false
                }
            }
        }

        return true
    }

    private suspend fun updateChatLastMessage(chatId: String, content: String, timestamp: Date) {
        val existingChat = database.chatDao().getChatById(chatId)
        existingChat?.let {
            database.chatDao().insertChat(
                it.copy(lastMessage = content, lastMessageAt = timestamp)
            )
        }
    }

    private suspend fun sendViaMesh(chatId: String, message: MessageEntity) {
        // Implementation handled by MeshEngine
        // This is just a placeholder for the actual mesh send logic
    }
}
