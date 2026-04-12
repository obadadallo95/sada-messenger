package org.sada.messenger.domain.usecase

import io.mockk.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.data.entities.ChatEntity
import org.sada.messenger.data.entities.MessageEntity
import org.sada.messenger.network.MeshEngine
import org.sada.messenger.security.KeyManager
import org.sada.messenger.security.EncryptionManager
import java.util.*

/**
 * Unit tests for SendMessageUseCase
 */
@OptIn(ExperimentalCoroutinesApi::class)
class SendMessageUseCaseTest {

    private lateinit var database: AppDatabase
    private lateinit var meshEngine: MeshEngine
    private lateinit var keyManager: KeyManager
    private lateinit var encryptionManager: EncryptionManager
    private lateinit var useCase: SendMessageUseCase

    @Before
    fun setup() {
        database = mockk(relaxed = true)
        meshEngine = mockk(relaxed = true)
        keyManager = mockk(relaxed = true)
        encryptionManager = mockk(relaxed = true)

        useCase = SendMessageUseCase(database, meshEngine, keyManager, encryptionManager)
    }

    @Test
    fun `send message with empty content should return failure`() = runTest {
        // Given
        val chatId = "chat123"
        val content = "   " // Empty after trim

        // When
        val result = useCase(chatId, content).first()

        // Then
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is IllegalArgumentException)
    }

    @Test
    fun `send message successfully`() = runTest {
        // Given
        val chatId = "chat123"
        val content = "Hello World"
        val myId = "user123"

        every { keyManager.getPublicKeyBase64() } returns myId
        coEvery { database.chatDao().getChatById(chatId) } returns null
        coEvery { database.messageDao().insertMessage(any()) } just Runs
        coEvery { database.chatDao().insertChat(any()) } just Runs

        // When
        val result = useCase(chatId, content).first()

        // Then
        assertTrue(result.isSuccess)
        coVerify { database.messageDao().insertMessage(any()) }
    }

    @Test
    fun `send message with reply info`() = runTest {
        // Given
        val chatId = "chat123"
        val content = "Reply message"
        val myId = "user123"
        val replyToId = "msg456"
        val replyToSender = "Other User"
        val replyToContent = "Original message"

        every { keyManager.getPublicKeyBase64() } returns myId
        coEvery { database.chatDao().getChatById(chatId) } returns null
        coEvery { database.messageDao().insertMessage(any()) } just Runs
        coEvery { database.chatDao().insertChat(any()) } just Runs

        // When
        val result = useCase(
            chatId = chatId,
            content = content,
            replyToId = replyToId,
            replyToSender = replyToSender,
            replyToContent = replyToContent
        ).first()

        // Then
        assertTrue(result.isSuccess)
        
        // Verify message was created with reply info
        val messageSlot = slot<MessageEntity>()
        coVerify { database.messageDao().insertMessage(capture(messageSlot)) }
        
        assertEquals(replyToId, messageSlot.captured.replyToId)
        assertEquals(replyToSender, messageSlot.captured.replyToSender)
        assertEquals(replyToContent, messageSlot.captured.replyToContent)
    }

    @Test
    fun `send message in group with slow mode restriction`() = runTest {
        // Given
        val chatId = "group123"
        val content = "Test message"
        val myId = "user123"
        
        val chat = ChatEntity(
            id = chatId,
            isGroup = true,
            slowModeSeconds = 60,
            name = "Test Group"
        )

        every { keyManager.getPublicKeyBase64() } returns myId
        coEvery { database.chatDao().getChatById(chatId) } returns chat
        coEvery { database.groupDao().isUserAdminOrOwner(chatId, myId) } returns false

        // Simulate recent message (within slow mode window) via chatDao
        val recentMessage = MessageEntity(
            id = "old_msg",
            chatId = chatId,
            senderId = myId,
            content = "Previous",
            timestamp = Date(System.currentTimeMillis() - 30000), // 30 seconds ago
            isFromMe = true,
            status = "sent"
        )
        coEvery { database.chatDao().getLatestMessage(chatId) } returns recentMessage

        // When
        val result = useCase(chatId, content).first()

        // Then
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is SecurityException)
    }

    @Test
    fun `admin bypasses slow mode restriction`() = runTest {
        // Given
        val chatId = "group123"
        val content = "Admin message"
        val myId = "admin123"
        
        val chat = ChatEntity(
            id = chatId,
            isGroup = true,
            slowModeSeconds = 60,
            name = "Test Group"
        )

        every { keyManager.getPublicKeyBase64() } returns myId
        coEvery { database.chatDao().getChatById(chatId) } returns chat
        coEvery { database.groupDao().isUserAdminOrOwner(chatId, myId) } returns true
        coEvery { database.messageDao().insertMessage(any()) } just Runs
        coEvery { database.chatDao().insertChat(any()) } just Runs

        // When
        val result = useCase(chatId, content).first()

        // Then
        assertTrue(result.isSuccess)
    }
}
