package org.sada.messenger.domain.usecase

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import org.sada.messenger.data.db.AppDatabase
import javax.inject.Inject

/**
 * Use Case: Delete Message
 * Deletes a message if the user has permission
 */
class DeleteMessageUseCase @Inject constructor(
    private val database: AppDatabase
) {
    operator fun invoke(messageId: String, userId: String): Flow<Result<Boolean>> = flow {
        try {
            val message = database.messageDao().getMessageById(messageId)
                ?: run {
                    emit(Result.failure(IllegalArgumentException("Message not found")))
                    return@flow
                }

            // Only message owner can delete
            if (message.senderId != userId) {
                emit(Result.failure(SecurityException("Not authorized to delete this message")))
                return@flow
            }

            database.messageDao().deleteMessageById(messageId)
            emit(Result.success(true))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
}
