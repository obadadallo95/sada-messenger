package org.sada.messenger.data.entities

import androidx.room.*
import java.util.Date

@Entity(tableName = "contacts")
data class ContactEntity(
    @PrimaryKey val id: String,
    val name: String,
    val publicKey: String? = null,
    val avatar: String? = null,
    val lastSeen: Date? = null,
    val lastRssi: Int? = null,
    val lastSnr: Double? = null,
    val isBlocked: Boolean = false,
    val createdAt: Date = Date(),
    val updatedAt: Date = Date()
)

@Entity(tableName = "chats")
data class ChatEntity(
    @PrimaryKey val id: String,
    val name: String,
    val lastMessage: String? = null,
    val lastMessageAt: Date? = null,
    val unreadCount: Int = 0,
    val isGroup: Boolean = false,
    val groupKey: String? = null, // Shared symmetric key (Base64)
    val ownerId: String? = null
)

@Entity(
    tableName = "group_members",
    primaryKeys = ["groupId", "peerId"],
    foreignKeys = [
        ForeignKey(
            entity = ChatEntity::class,
            parentColumns = ["id"],
            childColumns = ["groupId"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class GroupMemberEntity(
    val groupId: String,
    val peerId: String,
    val role: String = "member",
    val joinedAt: Date = Date()
)

@Entity(
    tableName = "messages",
    indices = [
        Index(value = ["chatId"], name = "messages_chat_id_idx"),
        Index(value = ["timestamp"], name = "messages_timestamp_idx")
    ],
    foreignKeys = [
        ForeignKey(
            entity = ChatEntity::class,
            parentColumns = ["id"],
            childColumns = ["chatId"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class MessageEntity(
    @PrimaryKey val id: String,
    val chatId: String,
    val senderId: String,
    val content: String, // Encrypted
    val type: String = "text",
    val status: String = "sending",
    val timestamp: Date = Date(),
    val isFromMe: Boolean = false,
    val isRelayed: Boolean = false, // True if delivered via intermediate node
    val attachmentPath: String? = null,
    val attachmentType: String? = null, // "image", "audio", "video"
    val latitude: Double? = null,
    val longitude: Double? = null,
    val replyToId: String? = null,
    val retryCount: Int = 0
)

@Entity(
    tableName = "media_chunks",
    primaryKeys = ["messageId", "chunkIndex"]
)
data class MediaChunkEntity(
    val messageId: String,
    val chunkIndex: Int,
    val totalChunks: Int,
    val data: ByteArray,
    val createdAt: Date = Date()
)

@Entity(tableName = "relay_queue")
data class RelayQueueEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val messageId: String,
    val recipientHash: String, // SHA256 of recipient ID for Blind Relay
    val payload: String,
    val expiresAt: Date
)
