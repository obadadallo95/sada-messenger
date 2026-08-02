package org.sada.messenger.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.data.entities.ChatEntity
import org.sada.messenger.data.entities.ContactEntity
import java.util.Date
import org.sada.messenger.runtime.MeshRuntimeController

class ContactsViewModel(
    private val database: AppDatabase,
    private val meshRuntime: MeshRuntimeController
) : ViewModel() {
    private val meshEngine get() = meshRuntime.meshEngine
    companion object {
        // Discovery contacts are ephemeral UI entities unless the user verifies via QR.
        private const val DISCOVERY_PENDING_TTL_MS = 90_000L
        private const val DISCOVERY_CLEANUP_INTERVAL_MS = 30_000L
    }

    val contacts: StateFlow<List<ContactEntity>> = database.contactDao()
        .getAllContacts()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val verifiedContacts: StateFlow<List<ContactEntity>> = database.contactDao()
        .getVerifiedContacts()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val pendingContacts: StateFlow<List<ContactEntity>> = database.contactDao()
        .getPendingContacts()
        .map { contacts ->
            contacts.filter { contact ->
                // Keep manually added pending contacts, hide only stale discovery ghosts.
                !isStaleDiscovery(contact)
            }
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val blockedContacts: StateFlow<List<ContactEntity>> = database.contactDao()
        .getBlockedContacts()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    init {
        // Periodic cleanup to remove stale discovery ghosts from DB.
        viewModelScope.launch {
            while (true) {
                pruneStalePendingDiscovery()
                database.contactDao().clearExpiredStatuses(Date())
                delay(DISCOVERY_CLEANUP_INTERVAL_MS)
            }
        }
    }

    fun addContact(name: String, publicKey: String) {
        viewModelScope.launch { addContactFromQr(name, publicKey, null, "private") }
    }

    /**
     * Add contact from QR code scan — marks as VERIFIED.
     * This is the only path to full verification in the QR-first model.
     */
    suspend fun addContactFromQr(
        name: String,
        publicKey: String,
        chatId: String? = null,
        channelType: String = "private",
        serviceCategory: String? = null,
        serviceAddress: String? = null,
        serviceWorkingHours: String? = null,
        serviceContactInfo: String? = null,
        serviceDeliveryAvailable: Boolean = false,
        serviceDeliveryRadiusKm: String? = null,
        serviceQuickReply: String? = null
    ): String? {
        return withContext(Dispatchers.IO) {
            val normalizedKey = publicKey.trim()
            val normalizedName = name.trim()
            val normalizedChatId = chatId?.trim().orEmpty()
            val isPublicChannel = channelType.equals("public", ignoreCase = true)
            if (normalizedKey.isBlank() || normalizedName.isBlank()) {
                return@withContext null
            }
            val targetChatId = if (isPublicChannel && normalizedChatId.isNotBlank()) {
                normalizedChatId
            } else {
                normalizedKey
            }

            val existing = database.contactDao().getContactById(normalizedKey)
            // QR scan is a trusted explicit action: verify immediately.
            val contact = ContactEntity(
                id = normalizedKey,
                name = normalizedName,
                publicKey = normalizedKey,
                isServiceProfile = isPublicChannel,
                serviceCategory = serviceCategory,
                serviceChatId = if (isPublicChannel) targetChatId else null,
                serviceAddress = serviceAddress,
                serviceWorkingHours = serviceWorkingHours,
                serviceContactInfo = serviceContactInfo,
                serviceDeliveryAvailable = serviceDeliveryAvailable,
                serviceDeliveryRadiusKm = serviceDeliveryRadiusKm,
                serviceQuickReply = serviceQuickReply,
                isVerified = true,
                updatedAt = Date(),
                createdAt = existing?.createdAt ?: Date()
            )
            database.contactDao().insertContact(contact)

            // Ensure direct chat exists
            val existingChat = database.chatDao().getChatById(targetChatId)
            if (existingChat == null) {
                database.chatDao().insertChat(
                    ChatEntity(
                        id = targetChatId,
                        name = normalizedName,
                        isGroup = false,
                        isPublic = isPublicChannel
                    )
                )
            }

            // ربط الـ QR بطلب الإضافة: إرسال طلب اتصال للطرف الآخر
            // Link QR to connection request: send request to the other party
            if (!isPublicChannel) {
                meshEngine.sendConnectionRequest(
                    peerId = normalizedKey,
                    peerName = normalizedName,
                    publicKey = normalizedKey
                )
            }

            // Remove stale pending requests for this peer after QR trust is established.
            database.connectionRequestDao().deleteByPeerIdOrPublicKey(
                peerId = normalizedKey,
                publicKey = normalizedKey
            )

            targetChatId
        }
    }

    fun deleteContact(contact: ContactEntity) {
        viewModelScope.launch {
            database.contactDao().deleteContact(contact)
        }
    }

    fun blockContact(contactId: String) {
        viewModelScope.launch {
            database.contactDao().setBlocked(contactId, true)
            // Also delete the chat content if needed, or just keep it blocked.
        }
    }

    fun deleteChat(chatId: String) {
        viewModelScope.launch {
            database.chatDao().deleteChatById(chatId)
            database.messageDao().deleteMessagesByChatId(chatId)
        }
    }

    fun unblockContact(contactId: String) {
        viewModelScope.launch {
            database.contactDao().setBlocked(contactId, false)
            database.contactDao().setVerified(contactId, false) // Explicitly move to Pending
        }
    }

    fun unverifyContact(contactId: String) {
        viewModelScope.launch {
            database.contactDao().setVerified(contactId, false)
        }
    }

    fun renameContact(contactId: String, newName: String) {
        val normalizedName = newName.trim()
        if (normalizedName.isBlank()) return

        viewModelScope.launch {
            val existing = database.contactDao().getContactById(contactId) ?: return@launch
            database.contactDao().insertContact(
                existing.copy(
                    name = normalizedName,
                    updatedAt = Date()
                )
            )
        }
    }

    private suspend fun pruneStalePendingDiscovery() = withContext(Dispatchers.IO) {
        val all = database.contactDao().getPendingContactsOnce()
        val stale = all.filter { isStaleDiscovery(it) }
        stale.forEach { contact ->
            database.contactDao().deleteContactById(contact.id)
        }
    }

    private fun isStaleDiscovery(contact: ContactEntity): Boolean {
        if (contact.isVerified || contact.isBlocked) return false
        if (!contact.name.startsWith("Discovery:", ignoreCase = true)) return false
        val ageMs = System.currentTimeMillis() - contact.updatedAt.time
        return ageMs > DISCOVERY_PENDING_TTL_MS
    }
}
