package org.sada.messenger.data.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Service Profile Entity
 * Represents a public service/business profile
 */
@Entity(tableName = "service_profiles")
data class ServiceProfileEntity(
    @PrimaryKey val userId: String,
    val displayName: String = "",
    val tagline: String = "",
    val workingHours: String = "",
    val phone: String? = null,
    val email: String? = null,
    val website: String? = null,
    val address: String? = null,
    val isActive: Boolean = false
)
