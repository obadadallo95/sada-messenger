package org.sada.messenger.network.protocols

import android.util.Base64
import org.json.JSONObject
import org.sada.messenger.data.entities.ChatEntity
import org.sada.messenger.data.entities.GroupMemberEntity
import org.sada.messenger.security.EncryptionManager
import org.sada.messenger.security.KeyManager
import java.security.SecureRandom
import java.util.*

/**
 * Handles Group Management Logic (Invitations, Joins, Key Exchange)
 */
class GroupProtocol(
    private val keyManager: KeyManager,
    private val encryptionManager: EncryptionManager
) {
    companion object {
        const val TYPE_GROUP_INVITE = "GROUP_INVITE"
        const val TYPE_GROUP_JOIN = "GROUP_JOIN"
        const val TYPE_GROUP_MSG = "GROUP_MSG"
    }

    /**
     * Generate a new group symmetric key (XSalsa20)
     */
    fun generateGroupKey(): String {
        val key = ByteArray(32)
        SecureRandom().nextBytes(key)
        return Base64.encodeToString(key, Base64.NO_WRAP)
    }

    /**
     * Create an Invitation payload for a peer
     */
    fun createInvitation(
        groupId: String,
        groupName: String,
        groupKey: String,
        senderNickname: String
    ): JSONObject {
        return JSONObject().apply {
            put("type", TYPE_GROUP_INVITE)
            put("groupId", groupId)
            put("groupName", groupName)
            put("groupKey", groupKey)
            put("senderNickname", senderNickname)
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
}
