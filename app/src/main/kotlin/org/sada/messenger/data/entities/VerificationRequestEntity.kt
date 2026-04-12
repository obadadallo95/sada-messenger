package org.sada.messenger.data.entities

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.Date

/**
 * Verification Request Entity
 * Represents an identity verification request
 */
@Entity(tableName = "verification_requests")
data class VerificationRequestEntity(
    @PrimaryKey val id: String,
    val userId: String,
    val requestType: String, // "government_id", "business_license", "phone"
    val status: String, // "pending", "approved", "rejected"
    val submittedAt: Date = Date(),
    val resolvedAt: Date? = null,
    val notes: String? = null
)
