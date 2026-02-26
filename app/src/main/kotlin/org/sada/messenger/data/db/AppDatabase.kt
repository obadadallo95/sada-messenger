package org.sada.messenger.data.db

import androidx.room.*
import org.sada.messenger.data.entities.*
import java.util.Date
import kotlinx.coroutines.flow.Flow

class Converters {
    @TypeConverter
    fun fromTimestamp(value: Long?): Date? = value?.let { Date(it) }

    @TypeConverter
    fun dateToTimestamp(date: Date?): Long? = date?.time
}

@Dao
interface ContactDao {
    @Query("SELECT * FROM contacts")
    fun getAllContacts(): Flow<List<ContactEntity>>

    @Query("SELECT * FROM contacts WHERE id = :id")
    suspend fun getContactById(id: String): ContactEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertContact(contact: ContactEntity)

    @Delete
    suspend fun deleteContact(contact: ContactEntity)
}

@Dao
interface ChatDao {
    @Query("SELECT * FROM chats ORDER BY lastMessageAt DESC")
    fun getAllChats(): Flow<List<ChatEntity>>

    @Query("SELECT * FROM chats WHERE id = :chatId")
    suspend fun getChatById(chatId: String): ChatEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertChat(chat: ChatEntity)
}

@Dao
interface MessageDao {
    @Query("SELECT * FROM messages WHERE chatId = :chatId ORDER BY timestamp ASC")
    fun getMessagesByChatId(chatId: String): Flow<List<MessageEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessage(message: MessageEntity)

    @Query("UPDATE messages SET status = :status WHERE id = :messageId")
    suspend fun updateMessageStatus(messageId: String, status: String)

    @Query("SELECT * FROM messages WHERE id = :messageId")
    suspend fun getMessageById(messageId: String): MessageEntity?
}

@Dao
interface RelayQueueDao {
    @Query("SELECT * FROM relay_queue WHERE expiresAt > :now")
    suspend fun getActiveRelays(now: Date): List<RelayQueueEntity>

    @Insert
    suspend fun addToQueue(relay: RelayQueueEntity)

    @Query("DELETE FROM relay_queue WHERE id = :id")
    suspend fun removeFromQueue(id: Int)

    @Query("DELETE FROM relay_queue WHERE messageId = :messageId")
    suspend fun removeByMessageId(messageId: String)
}

@Dao
interface GroupDao {
    @Query("SELECT * FROM group_members WHERE groupId = :groupId")
    fun getGroupMembers(groupId: String): Flow<List<GroupMemberEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMember(member: GroupMemberEntity)

    @Delete
    suspend fun removeMember(member: GroupMemberEntity)

    @Query("SELECT * FROM chats WHERE isGroup = 1")
    fun getAllGroups(): Flow<List<ChatEntity>>
}

@Dao
interface MediaChunkDao {
    @Query("SELECT * FROM media_chunks WHERE messageId = :messageId ORDER BY chunkIndex ASC")
    suspend fun getChunksForMessage(messageId: String): List<MediaChunkEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertChunk(chunk: MediaChunkEntity)

    @Query("DELETE FROM media_chunks WHERE messageId = :messageId")
    suspend fun deleteChunksForMessage(messageId: String)

    @Query("SELECT COUNT(*) FROM media_chunks WHERE messageId = :messageId")
    suspend fun getChunkCount(messageId: String): Int
}

@Database(
    entities = [
        ContactEntity::class, 
        ChatEntity::class, 
        MessageEntity::class, 
        RelayQueueEntity::class,
        GroupMemberEntity::class,
        MediaChunkEntity::class
    ],
    version = 6, // Upgraded version for RelayQueue schema change
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun contactDao(): ContactDao
    abstract fun chatDao(): ChatDao
    abstract fun messageDao(): MessageDao
    abstract fun relayQueueDao(): RelayQueueDao
    abstract fun groupDao(): GroupDao
    abstract fun mediaChunkDao(): MediaChunkDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: android.content.Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "sada_database"
                )
                .fallbackToDestructiveMigration() // Simplified for dev
                .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
