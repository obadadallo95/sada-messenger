package org.sada.messenger.domain.usecase

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.data.entities.MessageEntity
import javax.inject.Inject

/**
 * Use Case: Get Messages for a Chat
 * Retrieves messages with pagination support
 */
class GetMessagesUseCase @Inject constructor(
    private val database: AppDatabase
) {
    operator fun invoke(chatId: String, limit: Int = 100): Flow<List<MessageEntity>> {
        return database.messageDao().getMessagesByChatId(chatId)
            .map { messages -> messages.take(limit) }
    }
}
