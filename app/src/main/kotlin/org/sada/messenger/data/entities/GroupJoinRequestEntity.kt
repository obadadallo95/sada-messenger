package org.sada.messenger.data.entities

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.Date

/**
 * Group Join Request Entity
 * Represents a pending request to join a group
 */
@Entity(tableName = "group_join_requests")
data class GroupJoinRequestEntity(
    @PrimaryKey val id: String,
    val groupId: String,
    val requesterId: String,
    val requesterName: String,
    val status: String, // "pending", "approved", "rejected"
    val createdAt: Date = Date(),
    val resolvedAt: Date? = null
)
