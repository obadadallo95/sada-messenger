package org.sada.messenger.ui.viewmodels

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.data.db.GroupJoinRequestWithChat
import org.sada.messenger.data.entities.ChatEntity
import org.sada.messenger.data.entities.ContactEntity
import org.sada.messenger.data.entities.GroupMemberEntity
import org.sada.messenger.data.entities.GroupJoinRequestEntity
import org.sada.messenger.network.MeshEngine
import org.sada.messenger.runtime.MeshRuntimeController
import org.sada.messenger.security.KeyManager
import java.util.*

enum class JoinGroupResult {
    JOINED,
    REQUEST_SENT,
    INVITE_REQUIRED,
    ALREADY_MEMBER,
    GROUP_NOT_FOUND
}

data class ServiceDirectoryItem(
    val chatId: String,
    val name: String,
    val category: String?,
    val address: String?,
    val workingHours: String?,
    val contactInfo: String?,
    val deliveryAvailable: Boolean,
    val deliveryRadiusKm: String?,
    val updatedAtMs: Long,
    val lastSeenMs: Long?,
    val lastRssi: Int?
)

class HomeViewModel(
    private val database: AppDatabase,
    private val meshRuntime: MeshRuntimeController,
    private val keyManager: KeyManager
) : ViewModel() {
    private val meshEngine: MeshEngine get() = meshRuntime.meshEngine
    private val TAG = "HomeViewModel"
    private val myPeerId: String = keyManager.getPublicKeyBase64()

    val chats: StateFlow<List<ChatEntity>> = combine(
        database.chatDao().getAllChats(),
        database.contactDao().getAllContacts()
    ) { allChats, allContacts ->
        val verifiedIds = allContacts
            .asSequence()
            .filter { it.isVerified && !it.isBlocked }
            .map { it.id }
            .toSet()

        allChats.filter { chat ->
            when {
                chat.isGroup -> true
                chat.id.startsWith("SYSTEM_", ignoreCase = true) -> true
                chat.id.startsWith("public_", ignoreCase = true) -> true
                else -> verifiedIds.contains(chat.id) || !chat.lastMessage.isNullOrBlank()
            }
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )

    val myGroups: StateFlow<List<ChatEntity>> = database.groupDao()
        .getMyGroups(myPeerId)
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val nearbyGroups: StateFlow<List<ChatEntity>> = database.groupDao()
        .getAllGroups()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val pendingJoinRequests: StateFlow<List<GroupJoinRequestWithChat>> = database.groupDao()
        .getPendingJoinRequestsForOwner(myPeerId)
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val relayQueueCount: StateFlow<Int> = database.relayQueueDao()
        .observeTotalCount()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = 0
        )

    val outgoingUndeliveredCount: StateFlow<Int> = database.messageDao()
        .getOutgoingUndeliveredCount()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = 0
        )

    val connectedPeersCount: StateFlow<Int> = meshEngine.connectedPeers
        .map { it.size }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = 0
        )

    val networkConnected: StateFlow<Boolean> = combine(
        meshEngine.transportConnected,
        connectedPeersCount
    ) { transportConnected, peersCount ->
        transportConnected || peersCount > 0
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = false
    )

    val serviceDirectory: StateFlow<List<ServiceDirectoryItem>> = combine(
        database.contactDao().getAllContacts(),
        database.chatDao().getAllChats()
    ) { contacts, chats ->
        val directChats = chats.filter { !it.isGroup }.associateBy { it.id }
        contacts
            .asSequence()
            .filter { it.isServiceProfile && !it.isBlocked }
            .mapNotNull { contact -> mapServiceContact(contact, directChats) }
            .sortedBy { it.name.lowercase() }
            .toList()
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )

    val groupMemberCounts: StateFlow<Map<String, Int>> = database.groupDao()
        .observeGroupMemberCounts()
        .map { rows -> rows.associate { it.groupId to it.memberCount } }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyMap()
        )

    fun createGroup(
        name: String,
        description: String,
        isPublic: Boolean,
        joinPolicy: String,
        members: List<String>
    ) {
        viewModelScope.launch {
            val groupId = "group_" + UUID.randomUUID().toString()
            val groupKey = meshEngine.generateGroupKey()
            
            val chat = ChatEntity(
                id = groupId,
                name = name,
                isGroup = true,
                groupDescription = description,
                isPublic = isPublic,
                joinPolicy = joinPolicy,
                groupKey = groupKey,
                ownerId = myPeerId
            )
            database.chatDao().insertChat(chat)
            if (isPublic) {
                meshEngine.announcePublicGroup(chat)
            }
            database.groupDao().insertMember(
                GroupMemberEntity(
                    groupId = groupId,
                    peerId = myPeerId,
                    role = "owner"
                )
            )
            
            // Send invitations to members
            members.forEach { peerId ->
                meshEngine.sendGroupInvitation(peerId, groupId, name, groupKey)
                database.groupDao().insertMember(
                    GroupMemberEntity(
                        groupId = groupId,
                        peerId = peerId,
                        role = "invited"
                    )
                )
            }
        }
    }

    suspend fun joinGroup(groupId: String): JoinGroupResult {
        val group = database.groupDao().getGroupById(groupId) ?: return JoinGroupResult.GROUP_NOT_FOUND
        val existing = database.groupDao().getMember(groupId, myPeerId)
        if (existing != null && existing.role != "invited") return JoinGroupResult.ALREADY_MEMBER

        return when (group.joinPolicy) {
            "open" -> {
                database.groupDao().insertMember(
                    GroupMemberEntity(
                        groupId = groupId,
                        peerId = myPeerId,
                        role = "member"
                    )
                )
                meshEngine.sendGroupJoinEvent(groupId, myPeerId)
                JoinGroupResult.JOINED
            }
            "approval" -> {
                database.groupDao().upsertJoinRequest(
                    GroupJoinRequestEntity(
                        id = "req_${groupId}_${myPeerId}",
                        groupId = groupId,
                        requesterId = myPeerId,
                        requesterName = "Peer ${myPeerId.take(8)}",
                        status = "pending"
                    )
                )
                JoinGroupResult.REQUEST_SENT
            }
            "invite_only" -> {
                if (existing?.role == "invited") {
                    database.groupDao().insertMember(
                        GroupMemberEntity(
                            groupId = groupId,
                            peerId = myPeerId,
                            role = "member"
                        )
                    )
                    meshEngine.sendGroupJoinEvent(groupId, myPeerId)
                    JoinGroupResult.JOINED
                } else {
                    JoinGroupResult.INVITE_REQUIRED
                }
            }
            else -> JoinGroupResult.GROUP_NOT_FOUND
        }
    }

    fun handleJoinRequest(requestId: String, groupId: String, requesterId: String, approve: Boolean) {
        viewModelScope.launch {
            database.groupDao().updateJoinRequestStatus(
                requestId = requestId,
                status = if (approve) "approved" else "rejected",
                resolvedAt = Date()
            )
            if (approve) {
                database.groupDao().insertMember(
                    GroupMemberEntity(
                        groupId = groupId,
                        peerId = requesterId,
                        role = "member"
                    )
                )
            }
        }
    }
    
    fun triggerSos() {
        viewModelScope.launch {
            // In a real app, we'd fetch actual GPS coordinates
            // For now, we use a default/mock location
            runCatching {
                meshEngine.sendSosBroadcast(33.5138, 36.2765) // Damascus coordinates
            }.onFailure { e ->
                Log.e(TAG, "SOS send failed", e)
            }
        }
    }

    fun removeConversation(chatId: String) {
        viewModelScope.launch {
            val chat = database.chatDao().getChatById(chatId)
            database.messageDao().deleteByChatOrSender(chatId)
            database.chatDao().deleteChatById(chatId)

            // For direct chats, remove matching contact to avoid old-account collisions.
            if (chat?.isGroup != true) {
                database.contactDao().deleteContactById(chatId)
            }
        }
    }

    private fun mapServiceContact(
        contact: ContactEntity,
        directChats: Map<String, ChatEntity>
    ): ServiceDirectoryItem? {
        val chatId = contact.serviceChatId
            ?: directChats.keys.firstOrNull { it.startsWith("public_", ignoreCase = true) && (directChats[it]?.name == contact.name) }
            ?: return null
        if (!directChats.containsKey(chatId)) return null
        return ServiceDirectoryItem(
            chatId = chatId,
            name = contact.name,
            category = contact.serviceCategory,
            address = contact.serviceAddress,
            workingHours = contact.serviceWorkingHours,
            contactInfo = contact.serviceContactInfo,
            deliveryAvailable = contact.serviceDeliveryAvailable,
            deliveryRadiusKm = contact.serviceDeliveryRadiusKm,
            updatedAtMs = contact.updatedAt.time,
            lastSeenMs = contact.lastSeen?.time,
            lastRssi = contact.lastRssi
        )
    }
}
