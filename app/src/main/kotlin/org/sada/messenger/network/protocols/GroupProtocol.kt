package org.sada.messenger.network.protocols

import android.util.Base64
import org.json.JSONObject
import org.sada.messenger.security.EncryptionManager
import org.sada.messenger.security.KeyManager
import java.security.SecureRandom
import java.util.*

/**
 * Handles Group Management Logic (Invitations, Joins, Key Exchange, Admin Actions)
 *
 * SECURITY CHANGE: Group keys are now encrypted per-member using ECDH
 * before being sent over the mesh. They NEVER appear in plaintext on the wire.
 */
class GroupProtocol(
    private val keyManager: KeyManager,
    private val encryptionManager: EncryptionManager
) {
    companion object {
        const val TYPE_GROUP_INVITE = "GROUP_INVITE"
        const val TYPE_GROUP_JOIN = "GROUP_JOIN"
        const val TYPE_GROUP_MSG = "GROUP_MSG"
        const val TYPE_GROUP_KEY_ROTATION = "GROUP_KEY_ROTATION"
        const val TYPE_GROUP_REMOVE = "GROUP_REMOVE"
        const val TYPE_GROUP_TRANSFER = "GROUP_TRANSFER"
    }

    /**
     * Generate a new group symmetric key (32 bytes, Base64 encoded)
     */
    fun generateGroupKey(): String {
        val key = ByteArray(32)
        SecureRandom().nextBytes(key)
        return Base64.encodeToString(key, Base64.NO_WRAP)
    }

    /**
     * Create an Invitation payload with ENCRYPTED group key.
     * The groupKey is encrypted using the recipient's public key via ECDH
     * so only the intended recipient can decrypt it.
     *
     * @param encryptedGroupKey The group key already encrypted for the specific recipient
     */
    fun createInvitation(
        groupId: String,
        groupName: String,
        encryptedGroupKey: String,
        senderNickname: String,
        senderRole: String = "admin",
        version: Int = 1
    ): JSONObject {
        return JSONObject().apply {
            put("type", TYPE_GROUP_INVITE)
            put("groupId", groupId)
            put("groupName", groupName)
            put("encryptedGroupKey", encryptedGroupKey)  // ENCRYPTED, not plaintext
            put("senderNickname", senderNickname)
            put("senderRole", senderRole)
            put("version", version)
            put("timestamp", Date().time)
        }
    }

    /**
     * Create a Group Message payload
     */
    fun createGroupMessage(
        groupId: String,
        encryptedContent: String,
        senderId: String
    ): JSONObject {
        return JSONObject().apply {
            put("type", TYPE_GROUP_MSG)
            put("groupId", groupId)
            put("content", encryptedContent)
            put("senderId", senderId)
            put("timestamp", Date().time)
        }
    }

    /**
     * Create a key rotation payload — sent to each member individually
     * with the new key encrypted per-member.
     */
    fun createKeyRotationPayload(
        groupId: String,
        encryptedNewKey: String,
        reason: String = "member_removed"
    ): JSONObject {
        return JSONObject().apply {
            put("type", TYPE_GROUP_KEY_ROTATION)
            put("groupId", groupId)
            put("encryptedGroupKey", encryptedNewKey)
            put("reason", reason)
            put("timestamp", Date().time)
        }
    }

    /**
     * Create a member removal notification
     */
    fun createRemoveMemberPayload(
        groupId: String,
        removedPeerId: String,
        senderRole: String = "admin",
        version: Int = 1
    ): JSONObject {
        return JSONObject().apply {
            put("type", TYPE_GROUP_REMOVE)
            put("groupId", groupId)
            put("removedPeerId", removedPeerId)
            put("senderRole", senderRole)
            put("version", version)
            put("timestamp", Date().time)
        }
    }

    /**
     * Create ownership transfer payload
     */
    fun createTransferOwnershipPayload(
        groupId: String,
        newOwnerId: String
    ): JSONObject {
        return JSONObject().apply {
            put("type", TYPE_GROUP_TRANSFER)
            put("groupId", groupId)
            put("newOwnerId", newOwnerId)
            put("timestamp", Date().time)
        }
    }
}
