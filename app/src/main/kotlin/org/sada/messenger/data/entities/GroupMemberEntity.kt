package org.sada.messenger.data.entities

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.Date

/**
 * Group Member Entity
 * Represents a member of a group chat
 */
@Entity(tableName = "group_members", primaryKeys = ["groupId", "peerId"])
data class GroupMemberEntity(
    val groupId: String,
    val peerId: String,
    val role: String, // "owner", "admin", "member", "banned"
    val joinedAt: Date = Date(),
    val displayName: String? = null,
    val lastSeen: Date? = null
)
