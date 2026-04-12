package org.sada.messenger.data.entities

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.Date

/**
 * Poll Entity
 * Represents a poll in a chat
 */
@Entity(tableName = "polls")
data class PollEntity(
    @PrimaryKey val id: String,
    val chatId: String,
    val question: String,
    val createdBy: String,
    val createdAt: Date = Date(),
    val isClosed: Boolean = false,
    val isMultipleChoice: Boolean = false,
    val allowAnonymous: Boolean = true,
    val closedAt: Date? = null
)

/**
 * Poll Option Entity
 * Represents an option in a poll
 */
@Entity(tableName = "poll_options", primaryKeys = ["id", "pollId"])
data class PollOptionEntity(
    val id: String,
    val pollId: String,
    val text: String,
    val position: Int
)

/**
 * Poll Vote Entity
 * Represents a vote on a poll option
 */
@Entity(tableName = "poll_votes", primaryKeys = ["pollId", "optionId", "voterId"])
data class PollVoteEntity(
    val pollId: String,
    val optionId: String,
    val voterId: String,
    val votedAt: Date = Date()
)
