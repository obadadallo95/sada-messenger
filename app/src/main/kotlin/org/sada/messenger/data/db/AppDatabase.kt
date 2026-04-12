package org.sada.messenger.data.db

import androidx.room.*
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import org.sada.messenger.data.entities.*
import java.util.Date
import kotlinx.coroutines.flow.Flow

/**
 * Group Join Request with Chat Info
 */
data class GroupJoinRequestWithChat(
    val id: String,
    val groupId: String,
    val requesterId: String,
    val requesterName: String,
    val status: String,
    val createdAt: Date,
    val chatName: String
)

/**
 * Group Member Count
 */
data class GroupMemberCount(
    val groupId: String,
    val memberCount: Int
)

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

    @Query("SELECT * FROM contacts WHERE isVerified = 1 AND isBlocked = 0")
    fun getVerifiedContacts(): Flow<List<ContactEntity>>

    @Query("SELECT * FROM contacts WHERE isVerified = 1 AND isBlocked = 0")
    suspend fun getVerifiedContactsOnce(): List<ContactEntity>

    @Query("SELECT * FROM contacts WHERE isVerified = 0 AND isBlocked = 0")
    fun getPendingContacts(): Flow<List<ContactEntity>>

    @Query("SELECT * FROM contacts WHERE isVerified = 0 AND isBlocked = 0")
    suspend fun getPendingContactsOnce(): List<ContactEntity>

    @Query("SELECT * FROM contacts WHERE isBlocked = 1")
    fun getBlockedContacts(): Flow<List<ContactEntity>>

    @Query("SELECT * FROM contacts WHERE id = :id")
    suspend fun getContactById(id: String): ContactEntity?

    @Query("SELECT * FROM contacts WHERE id = :id")
    fun getContactByIdFlow(id: String): Flow<ContactEntity?>

    @Query("SELECT * FROM contacts WHERE publicKey = :publicKey LIMIT 1")
    suspend fun getContactByPublicKey(publicKey: String): ContactEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertContact(contact: ContactEntity)

    @Query("UPDATE contacts SET isVerified = :isVerified WHERE id = :id")
    suspend fun setVerified(id: String, isVerified: Boolean)

    @Query("UPDATE contacts SET isBlocked = :isBlocked WHERE id = :id")
    suspend fun setBlocked(id: String, isBlocked: Boolean)

    @Query("UPDATE contacts SET statusText = :statusText, statusExpiresAt = :expiresAt, updatedAt = :updatedAt WHERE id = :id")
    suspend fun setStatus(id: String, statusText: String?, expiresAt: Date?, updatedAt: Date = Date())

    @Query("UPDATE contacts SET statusText = NULL, statusExpiresAt = NULL WHERE statusExpiresAt IS NOT NULL AND statusExpiresAt < :now")
    suspend fun clearExpiredStatuses(now: Date): Int

    @Query("SELECT COUNT(*) FROM contacts WHERE isVerified = 1")
    fun getVerifiedCount(): Flow<Int>

    @Query("SELECT COUNT(*) FROM contacts WHERE isVerified = 0 AND isBlocked = 0")
    fun getPendingCount(): Flow<Int>

    @Query("SELECT COUNT(*) FROM contacts WHERE isBlocked = 1")
    fun getBlockedCount(): Flow<Int>

    @Query("DELETE FROM contacts WHERE id = :id")
    suspend fun deleteContactById(id: String)

    @Delete
    suspend fun deleteContact(contact: ContactEntity)
}

@Dao
interface ChatDao {
    @Query("SELECT * FROM chats ORDER BY lastMessageAt DESC")
    fun getAllChats(): Flow<List<ChatEntity>>

    @Query("SELECT * FROM chats WHERE id = :chatId")
    suspend fun getChatById(chatId: String): ChatEntity?

    @Upsert
    suspend fun insertChat(chat: ChatEntity)

    @Query("DELETE FROM chats WHERE id = :chatId")
    suspend fun deleteChatById(chatId: String)

    @Query("SELECT * FROM messages WHERE chatId = :chatId ORDER BY timestamp DESC LIMIT 1")
    suspend fun getLatestMessage(chatId: String): MessageEntity?
}

@Dao
interface MessageDao {
    @Query("SELECT * FROM messages WHERE chatId = :chatId ORDER BY timestamp ASC")
    fun getMessagesByChatId(chatId: String): Flow<List<MessageEntity>>

    @Query("SELECT * FROM messages WHERE chatId = :chatId ORDER BY timestamp ASC")
    suspend fun getMessagesForChat(chatId: String): List<MessageEntity>

    @Query("SELECT * FROM messages WHERE chatId = :chatId OR senderId = :chatId ORDER BY timestamp ASC")
    fun getMessagesByChatOrSender(chatId: String): Flow<List<MessageEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessage(message: MessageEntity)

    @Query("DELETE FROM messages WHERE chatId = :chatId OR senderId = :chatId")
    suspend fun deleteByChatOrSender(chatId: String)

    @Query("SELECT id FROM messages WHERE chatId = :chatId OR senderId = :chatId")
    suspend fun getMessageIdsByChatOrSender(chatId: String): List<String>

    @Query("UPDATE messages SET status = :status WHERE id = :messageId")
    suspend fun updateMessageStatus(messageId: String, status: String)

    @Query("UPDATE messages SET chatId = :newChatId WHERE chatId = :oldChatId")
    suspend fun updateChatIdForMessages(oldChatId: String, newChatId: String)

    @Query("UPDATE messages SET senderId = :newId WHERE senderId = :oldId")
    suspend fun updateSenderIdForMessages(oldId: String, newId: String)

    @Query("SELECT * FROM messages WHERE id = :messageId")
    suspend fun getMessageById(messageId: String): MessageEntity?

    @Query("DELETE FROM messages WHERE id = :messageId")
    suspend fun deleteMessageById(messageId: String)

    @Query("DELETE FROM messages WHERE id = :messageId")
    suspend fun deleteByMessageId(messageId: String)

    @Query("DELETE FROM messages WHERE id IN (:messageIds)")
    suspend fun deleteMessagesByIds(messageIds: List<String>)

    @Query(
        """
        SELECT COUNT(*) FROM messages
        WHERE isFromMe = 1 AND status IN ('sending','sent','failed')
        """
    )
    fun getOutgoingUndeliveredCount(): Flow<Int>

    // Pin message methods
    @Query("UPDATE messages SET isPinned = 1, pinnedAt = :timestamp, pinnedBy = :userId WHERE id = :messageId")
    suspend fun pinMessage(messageId: String, userId: String, timestamp: Date)

    @Query("UPDATE messages SET isPinned = 0, pinnedAt = null, pinnedBy = null WHERE id = :messageId")
    suspend fun unpinMessage(messageId: String)

    @Query("SELECT * FROM messages WHERE chatId = :chatId AND isPinned = 1 ORDER BY pinnedAt DESC")
    fun getPinnedMessages(chatId: String): Flow<List<MessageEntity>>

    @Query("SELECT * FROM messages WHERE chatId = :chatId AND isPinned = 1 ORDER BY pinnedAt DESC LIMIT 1")
    suspend fun getLatestPinnedMessage(chatId: String): MessageEntity?

    @Query("SELECT COUNT(*) FROM messages WHERE chatId = :chatId AND isPinned = 1")
    suspend fun getPinnedMessageCount(chatId: String): Int

    // Edit message methods
    @Query("UPDATE messages SET content = :newContent, editedAt = :timestamp WHERE id = :messageId")
    suspend fun editMessage(messageId: String, newContent: String, timestamp: Date)
}

@Dao
interface RelayQueueDao {
    @Query("SELECT * FROM relay_queue WHERE expiresAt > :now")
    suspend fun getActiveRelays(now: Date): List<RelayQueueEntity>
    
    @Query("SELECT * FROM relay_queue WHERE expiresAt > :now ORDER BY expiresAt ASC")
    suspend fun getActiveRelaysOrderedByExpiry(now: Date): List<RelayQueueEntity>

    @Query("SELECT * FROM relay_queue WHERE messageId = :messageId LIMIT 1")
    suspend fun getByMessageId(messageId: String): RelayQueueEntity?

    @Query("DELETE FROM relay_queue WHERE expiresAt <= :now")
    suspend fun removeExpired(now: Date)
    
    /**
     * Queue Pressure Control: Remove oldest low-priority messages when queue is full.
     * Keeps high-priority messages (SOS) even if they're old.
     */
    @Query("""
        DELETE FROM relay_queue 
        WHERE id IN (
            SELECT id FROM relay_queue 
            WHERE expiresAt > :now 
            ORDER BY expiresAt ASC 
            LIMIT :count
        )
    """)
    suspend fun removeOldest(count: Int, now: Date): Int

    @Query("SELECT COUNT(*) FROM relay_queue WHERE expiresAt > :now")
    suspend fun countActive(now: Date): Int
    
    @Query("SELECT COUNT(*) FROM relay_queue")
    suspend fun countTotal(): Int

    @Insert
    suspend fun addToQueue(relay: RelayQueueEntity)

    @Query("DELETE FROM relay_queue WHERE id = :id")
    suspend fun removeFromQueue(id: Int): Int

    @Query("DELETE FROM relay_queue WHERE messageId = :messageId")
    suspend fun removeByMessageId(messageId: String): Int

    @Query("SELECT COUNT(*) FROM relay_queue")
    fun observeTotalCount(): Flow<Int>

    @Query("SELECT * FROM relay_queue WHERE expiresAt > :now ORDER BY expiresAt ASC")
    suspend fun getAllPending(now: Date = Date()): List<RelayQueueEntity>
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

@Dao
interface SeenMessageDao {
    @Query("SELECT EXISTS(SELECT 1 FROM seen_messages WHERE messageId = :messageId)")
    suspend fun exists(messageId: String): Boolean

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertSeen(entry: SeenMessageEntity)

    @Query("DELETE FROM seen_messages WHERE seenAt < :cutoff")
    suspend fun deleteOlderThan(cutoff: Date): Int
}

@Dao
interface ConnectionRequestDao {
    @Query("SELECT * FROM connection_requests WHERE status = 'pending' ORDER BY createdAt DESC")
    fun getPendingRequests(): Flow<List<ConnectionRequestEntity>>

    @Query("SELECT * FROM connection_requests WHERE peerId = :peerId LIMIT 1")
    suspend fun getRequestByPeerId(peerId: String): ConnectionRequestEntity?
    
    @Query("SELECT * FROM connection_requests WHERE peerId = :peerId LIMIT 1")
    fun getRequestByPeerIdFlow(peerId: String): Flow<ConnectionRequestEntity?>

    @Query("SELECT * FROM connection_requests WHERE publicKey = :publicKey LIMIT 1")
    suspend fun getRequestByPublicKey(publicKey: String): ConnectionRequestEntity?

    @Query("SELECT COUNT(*) FROM connection_requests WHERE type = 'incoming' AND status = 'pending'")
    suspend fun getPendingIncomingCount(): Int

    @Upsert
    suspend fun upsertRequest(request: ConnectionRequestEntity)

    @Query("UPDATE connection_requests SET peerId = :newPeerId WHERE peerId = :oldPeerId")
    suspend fun updatePeerIdForRequests(oldPeerId: String, newPeerId: String)

    @Query("UPDATE connection_requests SET status = :status, resolvedAt = :resolvedAt WHERE id = :requestId")
    suspend fun updateRequestStatus(requestId: String, status: String, resolvedAt: Date)

    @Query("DELETE FROM connection_requests WHERE id = :requestId")
    suspend fun deleteRequest(requestId: String)

    @Query("DELETE FROM connection_requests WHERE peerId = :peerId OR publicKey = :publicKey")
    suspend fun deleteByPeerIdOrPublicKey(peerId: String, publicKey: String)
    
    @Query("DELETE FROM connection_requests WHERE resolvedAt < :cutoff AND status != 'pending'")
    suspend fun purgeOldResolved(cutoff: Date)

    @Query("DELETE FROM connection_requests WHERE type = 'incoming' AND status = 'pending' AND createdAt < :cutoff")
    suspend fun purgeStalePendingIncoming(cutoff: Date): Int
}

@Dao
interface GroupDao {
    @Query("SELECT * FROM group_members WHERE groupId = :groupId")
    fun getGroupMembers(groupId: String): Flow<List<GroupMemberEntity>>

    @Query("SELECT * FROM group_members WHERE groupId = :groupId")
    suspend fun getAllMembersList(groupId: String): List<GroupMemberEntity>

    @Query("SELECT groupId, COUNT(*) AS memberCount FROM group_members GROUP BY groupId")
    fun observeGroupMemberCounts(): Flow<List<GroupMemberCount>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMember(member: GroupMemberEntity)

    @Delete
    suspend fun removeMember(member: GroupMemberEntity)

    @Query("DELETE FROM group_members WHERE groupId = :groupId AND peerId = :peerId")
    suspend fun removeMemberById(groupId: String, peerId: String)

    @Query("UPDATE group_members SET role = :newRole WHERE groupId = :groupId AND peerId = :peerId")
    suspend fun updateMemberRole(groupId: String, peerId: String, newRole: String)

    @Query("SELECT * FROM group_members WHERE groupId = :groupId AND peerId = :peerId LIMIT 1")
    suspend fun getMember(groupId: String, peerId: String): GroupMemberEntity?

    @Query("SELECT EXISTS(SELECT 1 FROM group_members WHERE groupId = :groupId AND peerId = :peerId AND (role = 'admin' OR role = 'owner'))")
    suspend fun isUserAdminOrOwner(groupId: String, peerId: String): Boolean

    @Query("SELECT EXISTS(SELECT 1 FROM chats WHERE id = :groupId AND ownerId = :peerId)")
    suspend fun isUserOwner(groupId: String, peerId: String): Boolean

    @Query("UPDATE group_members SET role = 'banned' WHERE groupId = :groupId AND peerId = :peerId")
    suspend fun banMember(groupId: String, peerId: String)

    @Query("UPDATE group_members SET role = 'member' WHERE groupId = :groupId AND peerId = :peerId AND role = 'banned'")
    suspend fun unbanMember(groupId: String, peerId: String)

    @Query("SELECT * FROM group_members WHERE groupId = :groupId AND role = 'banned'")
    fun getBannedMembers(groupId: String): Flow<List<GroupMemberEntity>>

    @Query("SELECT * FROM chats WHERE isGroup = 1")
    fun getAllGroups(): Flow<List<ChatEntity>>

    @Query("""
        SELECT * FROM chats
        WHERE isGroup = 1
          AND (
            ownerId = :peerId
            OR id IN (SELECT groupId FROM group_members WHERE peerId = :peerId)
          )
        ORDER BY lastMessageAt DESC
    """)
    fun getMyGroups(peerId: String): Flow<List<ChatEntity>>

    @Query("UPDATE chats SET inviteCode = :code WHERE id = :groupId")
    suspend fun setInviteCode(groupId: String, code: String?)

    @Query("SELECT * FROM chats WHERE inviteCode = :code AND isGroup = 1 LIMIT 1")
    suspend fun findGroupByInviteCode(code: String): ChatEntity?

    @Query("UPDATE chats SET restrictNewMembers = :restricted WHERE id = :groupId")
    suspend fun setRestrictNewMembers(groupId: String, restricted: Boolean)

    @Query("UPDATE chats SET requireAdminApproval = :required WHERE id = :groupId")
    suspend fun setRequireAdminApproval(groupId: String, required: Boolean)

    @Query("SELECT slowModeSeconds FROM chats WHERE id = :groupId")
    suspend fun getSlowModeSeconds(groupId: String): Int?

    @Query("""
        SELECT r.id, r.groupId, r.requesterId, r.requesterName, r.status, r.createdAt, c.name AS chatName
        FROM group_join_requests r
        INNER JOIN chats c ON c.id = r.groupId
        WHERE r.status = 'pending' AND c.ownerId = :ownerPeerId
        ORDER BY r.createdAt DESC
    """)
    fun getPendingJoinRequestsForOwner(ownerPeerId: String): Flow<List<GroupJoinRequestWithChat>>

    @Query("UPDATE group_join_requests SET status = :status, resolvedAt = :resolvedAt WHERE id = :requestId")
    suspend fun updateJoinRequestStatus(requestId: String, status: String, resolvedAt: Date)

    @Query("UPDATE chats SET ownerId = :newOwnerId WHERE id = :groupId")
    suspend fun transferOwnership(groupId: String, newOwnerId: String)

    @Query("UPDATE chats SET slowModeSeconds = :seconds WHERE id = :groupId")
    suspend fun setSlowMode(groupId: String, seconds: Int)

    @Query("SELECT * FROM chats WHERE id = :groupId AND isGroup = 1 LIMIT 1")
    suspend fun getGroupById(groupId: String): ChatEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertJoinRequest(request: GroupJoinRequestEntity)

    @Query("SELECT * FROM chats WHERE isGroup = 1 AND ownerId = :ownerPeerId")
    fun getOwnedPublicGroups(ownerPeerId: String): Flow<List<ChatEntity>>

    @Query("SELECT * FROM chats WHERE isGroup = 1")
    suspend fun getNearbyGroups(): List<ChatEntity>
}

@Dao
interface PollDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPoll(poll: PollEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPollOptions(options: List<PollOptionEntity>)

    @Query("SELECT * FROM polls WHERE id = :pollId")
    suspend fun getPoll(pollId: String): PollEntity?

    @Query("SELECT * FROM polls WHERE chatId = :chatId AND isClosed = 0 ORDER BY createdAt DESC")
    fun getActivePolls(chatId: String): Flow<List<PollEntity>>

    @Query("UPDATE polls SET isClosed = 1 WHERE id = :pollId")
    suspend fun closePoll(pollId: String)

    @Query("DELETE FROM polls WHERE id = :pollId")
    suspend fun deletePoll(pollId: String)

    @Query("SELECT * FROM poll_options WHERE pollId = :pollId ORDER BY position")
    fun getPollOptions(pollId: String): Flow<List<PollOptionEntity>>

    @Query("SELECT * FROM poll_options WHERE pollId = :pollId ORDER BY position")
    suspend fun getPollOptionsList(pollId: String): List<PollOptionEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertVote(vote: PollVoteEntity)

    @Query("SELECT * FROM poll_votes WHERE pollId = :pollId")
    fun getVotesForPoll(pollId: String): Flow<List<PollVoteEntity>>

    @Query("SELECT COUNT(*) FROM poll_votes WHERE optionId = :optionId")
    fun getVoteCountForOption(optionId: String): Flow<Int>

    @Query("SELECT * FROM poll_votes WHERE pollId = :pollId AND voterId = :voterId")
    suspend fun getUserVotes(pollId: String, voterId: String): List<PollVoteEntity>

    @Query("SELECT EXISTS(SELECT 1 FROM poll_votes WHERE pollId = :pollId AND voterId = :voterId)")
    suspend fun hasUserVoted(pollId: String, voterId: String): Boolean

    @Query("DELETE FROM poll_votes WHERE pollId = :pollId AND voterId = :voterId")
    suspend fun removeUserVotes(pollId: String, voterId: String)
}

@Database(
    entities = [
        ContactEntity::class, 
        MessageEntity::class, 
        ChatEntity::class,
        GroupMemberEntity::class,
        GroupJoinRequestEntity::class,
        ServiceProfileEntity::class,
        VerificationRequestEntity::class,
        RelayQueueEntity::class,
        PollEntity::class,
        PollOptionEntity::class,
        PollVoteEntity::class,
        MediaChunkEntity::class,
        SeenMessageEntity::class,
        ConnectionRequestEntity::class
    ],
    version = 18,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun contactDao(): ContactDao
    abstract fun chatDao(): ChatDao
    abstract fun messageDao(): MessageDao
    abstract fun groupDao(): GroupDao
    abstract fun pollDao(): PollDao
    abstract fun relayQueueDao(): RelayQueueDao
    abstract fun mediaChunkDao(): MediaChunkDao
    abstract fun seenMessageDao(): SeenMessageDao
    abstract fun connectionRequestDao(): ConnectionRequestDao

    companion object {
        private const val DB_NAME = "sada_database"

        private val MIGRATION_1_7 = object : Migration(1, 7) {
            override fun migrate(database: SupportSQLiteDatabase) = migrateToV7(database)
        }
        private val MIGRATION_2_7 = object : Migration(2, 7) {
            override fun migrate(database: SupportSQLiteDatabase) = migrateToV7(database)
        }
        private val MIGRATION_3_7 = object : Migration(3, 7) {
            override fun migrate(database: SupportSQLiteDatabase) = migrateToV7(database)
        }
        private val MIGRATION_4_7 = object : Migration(4, 7) {
            override fun migrate(database: SupportSQLiteDatabase) = migrateToV7(database)
        }
        private val MIGRATION_5_7 = object : Migration(5, 7) {
            override fun migrate(database: SupportSQLiteDatabase) = migrateToV7(database)
        }
        private val MIGRATION_6_7 = object : Migration(6, 7) {
            override fun migrate(database: SupportSQLiteDatabase) = migrateToV7(database)
        }
        private val MIGRATION_7_8 = object : Migration(7, 8) {
            override fun migrate(database: SupportSQLiteDatabase) = migrateToV8(database)
        }
        private val MIGRATION_8_9 = object : Migration(8, 9) {
            override fun migrate(database: SupportSQLiteDatabase) = migrateToV9(database)
        }
        private val MIGRATION_9_10 = object : Migration(9, 10) {
            override fun migrate(database: SupportSQLiteDatabase) = migrateToV10(database)
        }
        private val MIGRATION_10_11 = object : Migration(10, 11) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL("ALTER TABLE messages ADD COLUMN mediaLocalPath TEXT")
                database.execSQL("ALTER TABLE messages ADD COLUMN mediaDuration INTEGER")
            }
        }
        private val MIGRATION_11_12 = object : Migration(11, 12) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL("ALTER TABLE contacts ADD COLUMN lastActionAt INTEGER")
                database.execSQL("""
                    CREATE TABLE IF NOT EXISTS connection_requests (
                        id TEXT NOT NULL PRIMARY KEY,
                        peerId TEXT NOT NULL,
                        peerName TEXT NOT NULL,
                        publicKey TEXT NOT NULL,
                        status TEXT NOT NULL DEFAULT 'pending',
                        type TEXT NOT NULL DEFAULT 'incoming',
                        createdAt INTEGER NOT NULL,
                        resolvedAt INTEGER
                    )
                """.trimIndent())
                database.execSQL("CREATE UNIQUE INDEX IF NOT EXISTS index_connection_requests_peerId ON connection_requests(peerId)")
            }
        }
        private val MIGRATION_12_13 = object : Migration(12, 13) {
            override fun migrate(database: SupportSQLiteDatabase) {
                ensureColumn(database, "contacts", "statusText", "TEXT")
                ensureColumn(database, "contacts", "statusExpiresAt", "INTEGER")
            }
        }
        private val MIGRATION_13_14 = object : Migration(13, 14) {
            override fun migrate(database: SupportSQLiteDatabase) {
                ensureColumn(database, "contacts", "isServiceProfile", "INTEGER NOT NULL DEFAULT 0")
                ensureColumn(database, "contacts", "serviceCategory", "TEXT")
                ensureColumn(database, "contacts", "serviceAddress", "TEXT")
                ensureColumn(database, "contacts", "serviceWorkingHours", "TEXT")
                ensureColumn(database, "contacts", "serviceContactInfo", "TEXT")
                ensureColumn(database, "contacts", "serviceDeliveryAvailable", "INTEGER NOT NULL DEFAULT 0")
                ensureColumn(database, "contacts", "serviceDeliveryRadiusKm", "TEXT")
                ensureColumn(database, "contacts", "serviceQuickReply", "TEXT")
            }
        }
        private val MIGRATION_14_15 = object : Migration(14, 15) {
            override fun migrate(database: SupportSQLiteDatabase) {
                ensureColumn(database, "contacts", "serviceChatId", "TEXT")
            }
        }
        private val MIGRATION_15_16 = object : Migration(15, 16) {
            override fun migrate(database: SupportSQLiteDatabase) {
                ensureColumn(database, "messages", "isPinned", "INTEGER NOT NULL DEFAULT 0")
                ensureColumn(database, "messages", "pinnedAt", "INTEGER")
                ensureColumn(database, "messages", "pinnedBy", "TEXT")
            }
        }
        private val MIGRATION_16_17 = object : Migration(16, 17) {
            override fun migrate(database: SupportSQLiteDatabase) {
                ensureColumn(database, "messages", "editedAt", "INTEGER")
            }
        }
        private val MIGRATION_17_18 = object : Migration(17, 18) {
            override fun migrate(database: SupportSQLiteDatabase) {
                // Add group restriction fields
                ensureColumn(database, "chats", "slowModeSeconds", "INTEGER NOT NULL DEFAULT 0")
                ensureColumn(database, "chats", "restrictNewMembers", "INTEGER NOT NULL DEFAULT 0")
                ensureColumn(database, "chats", "requireAdminApproval", "INTEGER NOT NULL DEFAULT 0")
                // Create poll tables
                database.execSQL("""
                    CREATE TABLE IF NOT EXISTS polls (
                        id TEXT PRIMARY KEY NOT NULL,
                        chatId TEXT NOT NULL,
                        creatorId TEXT NOT NULL,
                        question TEXT NOT NULL,
                        isMultipleChoice INTEGER NOT NULL DEFAULT 0,
                        isAnonymous INTEGER NOT NULL DEFAULT 1,
                        createdAt INTEGER NOT NULL,
                        endsAt INTEGER,
                        isClosed INTEGER NOT NULL DEFAULT 0
                    )
                """)
                database.execSQL("""
                    CREATE TABLE IF NOT EXISTS poll_options (
                        id TEXT PRIMARY KEY NOT NULL,
                        pollId TEXT NOT NULL,
                        optionText TEXT NOT NULL,
                        position INTEGER NOT NULL
                    )
                """)
                database.execSQL("""
                    CREATE TABLE IF NOT EXISTS poll_votes (
                        id TEXT PRIMARY KEY NOT NULL,
                        pollId TEXT NOT NULL,
                        optionId TEXT NOT NULL,
                        voterId TEXT NOT NULL,
                        votedAt INTEGER NOT NULL
                    )
                """)
            }
        }

        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: android.content.Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    DB_NAME
                )
                .addMigrations(
                    MIGRATION_1_7,
                    MIGRATION_2_7,
                    MIGRATION_3_7,
                    MIGRATION_4_7,
                    MIGRATION_5_7,
                    MIGRATION_6_7,
                    MIGRATION_7_8,
                    MIGRATION_8_9,
                    MIGRATION_9_10,
                    MIGRATION_10_11,
                    MIGRATION_11_12,
                    MIGRATION_12_13,
                    MIGRATION_13_14,
                    MIGRATION_14_15,
                    MIGRATION_15_16,
                    MIGRATION_16_17,
                    MIGRATION_17_18,
                )
                .build()
                INSTANCE = instance
                instance
            }
        }

        /**
         * Reconcile schema to v7 without destructive resets.
         * This migration is idempotent and safe to run on partially old schemas.
         */
        private fun migrateToV7(db: SupportSQLiteDatabase) {
            // contacts
            db.execSQL(
                """
                CREATE TABLE IF NOT EXISTS contacts (
                    id TEXT NOT NULL PRIMARY KEY,
                    name TEXT NOT NULL,
                    publicKey TEXT,
                    avatar TEXT,
                    lastSeen INTEGER,
                    lastRssi INTEGER,
                    lastSnr REAL,
                    isBlocked INTEGER NOT NULL DEFAULT 0,
                    createdAt INTEGER NOT NULL,
                    updatedAt INTEGER NOT NULL
                )
                """.trimIndent(),
            )
            ensureColumn(db, "contacts", "publicKey", "TEXT")
            ensureColumn(db, "contacts", "avatar", "TEXT")
            ensureColumn(db, "contacts", "lastSeen", "INTEGER")
            ensureColumn(db, "contacts", "lastRssi", "INTEGER")
            ensureColumn(db, "contacts", "lastSnr", "REAL")
            ensureColumn(db, "contacts", "isBlocked", "INTEGER NOT NULL DEFAULT 0")
            ensureColumn(db, "contacts", "statusText", "TEXT")
            ensureColumn(db, "contacts", "statusExpiresAt", "INTEGER")
            ensureColumn(db, "contacts", "isServiceProfile", "INTEGER NOT NULL DEFAULT 0")
            ensureColumn(db, "contacts", "serviceCategory", "TEXT")
            ensureColumn(db, "contacts", "serviceChatId", "TEXT")
            ensureColumn(db, "contacts", "serviceAddress", "TEXT")
            ensureColumn(db, "contacts", "serviceWorkingHours", "TEXT")
            ensureColumn(db, "contacts", "serviceContactInfo", "TEXT")
            ensureColumn(db, "contacts", "serviceDeliveryAvailable", "INTEGER NOT NULL DEFAULT 0")
            ensureColumn(db, "contacts", "serviceDeliveryRadiusKm", "TEXT")
            ensureColumn(db, "contacts", "serviceQuickReply", "TEXT")
            ensureColumn(db, "contacts", "createdAt", "INTEGER NOT NULL DEFAULT 0")
            ensureColumn(db, "contacts", "updatedAt", "INTEGER NOT NULL DEFAULT 0")

            // chats
            db.execSQL(
                """
                CREATE TABLE IF NOT EXISTS chats (
                    id TEXT NOT NULL PRIMARY KEY,
                    name TEXT NOT NULL,
                    lastMessage TEXT,
                    lastMessageAt INTEGER,
                    unreadCount INTEGER NOT NULL DEFAULT 0,
                    isGroup INTEGER NOT NULL DEFAULT 0,
                    groupKey TEXT,
                    ownerId TEXT
                )
                """.trimIndent(),
            )
            ensureColumn(db, "chats", "lastMessage", "TEXT")
            ensureColumn(db, "chats", "lastMessageAt", "INTEGER")
            ensureColumn(db, "chats", "unreadCount", "INTEGER NOT NULL DEFAULT 0")
            ensureColumn(db, "chats", "isGroup", "INTEGER NOT NULL DEFAULT 0")
            ensureColumn(db, "chats", "groupDescription", "TEXT")
            ensureColumn(db, "chats", "isPublic", "INTEGER NOT NULL DEFAULT 1")
            ensureColumn(db, "chats", "joinPolicy", "TEXT NOT NULL DEFAULT 'open'")
            ensureColumn(db, "chats", "groupKey", "TEXT")
            ensureColumn(db, "chats", "ownerId", "TEXT")

            // messages
            db.execSQL(
                """
                CREATE TABLE IF NOT EXISTS messages (
                    id TEXT NOT NULL PRIMARY KEY,
                    chatId TEXT NOT NULL,
                    senderId TEXT NOT NULL,
                    content TEXT NOT NULL,
                    type TEXT NOT NULL DEFAULT 'text',
                    status TEXT NOT NULL DEFAULT 'sending',
                    timestamp INTEGER NOT NULL,
                    isFromMe INTEGER NOT NULL DEFAULT 0,
                    isRelayed INTEGER NOT NULL DEFAULT 0,
                    attachmentPath TEXT,
                    attachmentType TEXT,
                    latitude REAL,
                    longitude REAL,
                    replyToId TEXT,
                    retryCount INTEGER NOT NULL DEFAULT 0,
                    FOREIGN KEY(chatId) REFERENCES chats(id) ON DELETE CASCADE
                )
                """.trimIndent(),
            )
            ensureColumn(db, "messages", "type", "TEXT NOT NULL DEFAULT 'text'")
            ensureColumn(db, "messages", "status", "TEXT NOT NULL DEFAULT 'sending'")
            ensureColumn(db, "messages", "isFromMe", "INTEGER NOT NULL DEFAULT 0")
            ensureColumn(db, "messages", "isRelayed", "INTEGER NOT NULL DEFAULT 0")
            ensureColumn(db, "messages", "attachmentPath", "TEXT")
            ensureColumn(db, "messages", "attachmentType", "TEXT")
            ensureColumn(db, "messages", "latitude", "REAL")
            ensureColumn(db, "messages", "longitude", "REAL")
            ensureColumn(db, "messages", "replyToId", "TEXT")
            ensureColumn(db, "messages", "retryCount", "INTEGER NOT NULL DEFAULT 0")

            // relay_queue
            db.execSQL(
                """
                CREATE TABLE IF NOT EXISTS relay_queue (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    messageId TEXT NOT NULL,
                    recipientHash TEXT NOT NULL,
                    payload TEXT NOT NULL,
                    expiresAt INTEGER NOT NULL
                )
                """.trimIndent(),
            )
            ensureColumn(db, "relay_queue", "messageId", "TEXT NOT NULL DEFAULT ''")
            ensureColumn(db, "relay_queue", "recipientHash", "TEXT NOT NULL DEFAULT ''")
            ensureColumn(db, "relay_queue", "payload", "TEXT NOT NULL DEFAULT ''")
            ensureColumn(db, "relay_queue", "expiresAt", "INTEGER NOT NULL DEFAULT 0")

            // group_members
            db.execSQL(
                """
                CREATE TABLE IF NOT EXISTS group_members (
                    groupId TEXT NOT NULL,
                    peerId TEXT NOT NULL,
                    role TEXT NOT NULL DEFAULT 'member',
                    joinedAt INTEGER NOT NULL,
                    PRIMARY KEY(groupId, peerId),
                    FOREIGN KEY(groupId) REFERENCES chats(id) ON DELETE CASCADE
                )
                """.trimIndent(),
            )
            ensureColumn(db, "group_members", "role", "TEXT NOT NULL DEFAULT 'member'")
            ensureColumn(db, "group_members", "joinedAt", "INTEGER NOT NULL DEFAULT 0")

            // group_join_requests
            db.execSQL(
                """
                CREATE TABLE IF NOT EXISTS group_join_requests (
                    id TEXT NOT NULL PRIMARY KEY,
                    groupId TEXT NOT NULL,
                    requesterId TEXT NOT NULL,
                    requesterName TEXT NOT NULL,
                    status TEXT NOT NULL,
                    createdAt INTEGER NOT NULL,
                    resolvedAt INTEGER,
                    FOREIGN KEY(groupId) REFERENCES chats(id) ON DELETE CASCADE
                )
                """.trimIndent(),
            )
            db.execSQL("CREATE UNIQUE INDEX IF NOT EXISTS index_group_join_requests_groupId_requesterId ON group_join_requests(groupId, requesterId)")
            db.execSQL("CREATE INDEX IF NOT EXISTS group_requests_status_idx ON group_join_requests(status)")

            // media_chunks
            db.execSQL(
                """
                CREATE TABLE IF NOT EXISTS media_chunks (
                    messageId TEXT NOT NULL,
                    chunkIndex INTEGER NOT NULL,
                    totalChunks INTEGER NOT NULL,
                    data BLOB NOT NULL,
                    createdAt INTEGER NOT NULL,
                    PRIMARY KEY(messageId, chunkIndex)
                )
                """.trimIndent(),
            )
            ensureColumn(db, "media_chunks", "totalChunks", "INTEGER NOT NULL DEFAULT 0")
            ensureColumn(db, "media_chunks", "data", "BLOB")
            ensureColumn(db, "media_chunks", "createdAt", "INTEGER NOT NULL DEFAULT 0")

            db.execSQL(
                "CREATE INDEX IF NOT EXISTS messages_chat_id_idx ON messages(chatId)",
            )
            db.execSQL(
                "CREATE INDEX IF NOT EXISTS messages_timestamp_idx ON messages(timestamp)",
            )
        }

        private fun migrateToV8(db: SupportSQLiteDatabase) {
            ensureColumn(db, "chats", "groupDescription", "TEXT")
            ensureColumn(db, "chats", "isPublic", "INTEGER NOT NULL DEFAULT 1")
            ensureColumn(db, "chats", "joinPolicy", "TEXT NOT NULL DEFAULT 'open'")

            db.execSQL("DROP TABLE IF EXISTS group_join_requests")
            db.execSQL(
                """
                CREATE TABLE IF NOT EXISTS group_join_requests (
                    id TEXT NOT NULL PRIMARY KEY,
                    groupId TEXT NOT NULL,
                    requesterId TEXT NOT NULL,
                    requesterName TEXT NOT NULL,
                    status TEXT NOT NULL,
                    createdAt INTEGER NOT NULL,
                    resolvedAt INTEGER,
                    FOREIGN KEY(groupId) REFERENCES chats(id) ON DELETE CASCADE
                )
                """.trimIndent(),
            )
            db.execSQL("CREATE UNIQUE INDEX IF NOT EXISTS index_group_join_requests_groupId_requesterId ON group_join_requests(groupId, requesterId)")
            db.execSQL("CREATE INDEX IF NOT EXISTS group_requests_status_idx ON group_join_requests(status)")
        }

        private fun migrateToV9(db: SupportSQLiteDatabase) {
            db.execSQL(
                """
                CREATE TABLE IF NOT EXISTS seen_messages (
                    messageId TEXT NOT NULL PRIMARY KEY,
                    seenAt INTEGER NOT NULL
                )
                """.trimIndent(),
            )
            db.execSQL("CREATE INDEX IF NOT EXISTS seen_messages_seen_at_idx ON seen_messages(seenAt)")
        }

        private fun migrateToV10(db: SupportSQLiteDatabase) {
            // Add isVerified column to contacts for QR-first architecture
            ensureColumn(db, "contacts", "isVerified", "INTEGER NOT NULL DEFAULT 0")
        }

        private fun migrateToV11(db: SupportSQLiteDatabase) {
            // Add replyToSender and replyToContent columns for reply functionality
            ensureColumn(db, "messages", "replyToSender", "TEXT")
            ensureColumn(db, "messages", "replyToContent", "TEXT")
        }

        private fun ensureColumn(
            db: SupportSQLiteDatabase,
            table: String,
            column: String,
            definition: String,
        ) {
            if (!columnExists(db, table, column)) {
                db.execSQL("ALTER TABLE $table ADD COLUMN $column $definition")
            }
        }

        private fun columnExists(
            db: SupportSQLiteDatabase,
            table: String,
            column: String,
        ): Boolean {
            db.query("PRAGMA table_info($table)").use { cursor ->
                val nameIndex = cursor.getColumnIndex("name")
                while (cursor.moveToNext()) {
                    if (nameIndex >= 0 && column == cursor.getString(nameIndex)) {
                        return true
                    }
                }
            }
            return false
        }
    }
}
