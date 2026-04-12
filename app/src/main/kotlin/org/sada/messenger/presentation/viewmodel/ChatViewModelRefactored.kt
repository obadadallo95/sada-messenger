package org.sada.messenger.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.data.entities.*
import org.sada.messenger.domain.usecase.*
import org.sada.messenger.network.MeshEngine
import org.sada.messenger.presentation.navigation.AppNavigator
import org.sada.messenger.security.KeyManager
import java.util.*
import javax.inject.Inject

/**
 * Refactored ChatViewModel using Clean Architecture
 * Uses UseCases for business logic, Hilt for DI
 */
@HiltViewModel
class ChatViewModelRefactored @Inject constructor(
    private val database: AppDatabase,
    private val meshEngine: MeshEngine,
    private val keyManager: KeyManager,
    private val sendMessageUseCase: SendMessageUseCase,
    private val getMessagesUseCase: GetMessagesUseCase,
    private val deleteMessageUseCase: DeleteMessageUseCase,
    private val manageGroupMemberUseCase: ManageGroupMemberUseCase,
    private val navigator: AppNavigator
) : ViewModel() {

    private val chatId: String = ""

    // StateFlows
    private val _uiState = MutableStateFlow(ChatUiState())
    val uiState: StateFlow<ChatUiState> = _uiState.asStateFlow()

    private val _replyToMessage = MutableStateFlow<MessageEntity?>(null)
    val replyToMessage: StateFlow<MessageEntity?> = _replyToMessage.asStateFlow()

    private val _editingMessage = MutableStateFlow<MessageEntity?>(null)
    val editingMessage: StateFlow<MessageEntity?> = _editingMessage.asStateFlow()

    val messages: StateFlow<List<MessageEntity>> = getMessagesUseCase(chatId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val pinnedMessages: StateFlow<List<MessageEntity>> = database.messageDao()
        .getPinnedMessages(chatId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Send message using UseCase
    fun sendMessage(content: String) {
        viewModelScope.launch {
            val replyTo = _replyToMessage.value
            
            sendMessageUseCase(
                chatId = chatId,
                content = content,
                replyToId = replyTo?.id,
                replyToSender = replyTo?.let { 
                    if (it.isFromMe) "أنت" else database.contactDao().getContactById(it.senderId)?.name ?: "Unknown"
                },
                replyToContent = replyTo?.content?.take(100)
            ).collect { result ->
                result.onSuccess {
                    clearReplyTo()
                }.onFailure { error ->
                    _uiState.update { it.copy(error = error.message) }
                }
            }
        }
    }

    // Edit message
    fun editMessage(messageId: String, newContent: String) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            database.messageDao().editMessage(messageId, newContent.trim(), Date())
            // TODO: Send edit notification via mesh
        }
    }

    // Delete message using UseCase
    fun deleteMessage(messageId: String) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            deleteMessageUseCase(messageId, myId).collect { result ->
                result.onFailure { error ->
                    _uiState.update { it.copy(error = error.message) }
                }
            }
        }
    }

    // Pin/Unpin messages
    fun pinMessage(messageId: String) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            database.messageDao().pinMessage(messageId, myId, Date())
        }
    }

    fun unpinMessage(messageId: String) {
        viewModelScope.launch {
            database.messageDao().unpinMessage(messageId)
        }
    }

    // Reply handling
    fun setReplyTo(message: MessageEntity) {
        _replyToMessage.value = message
    }

    fun clearReplyTo() {
        _replyToMessage.value = null
    }

    // Edit handling
    fun startEditing(message: MessageEntity) {
        if (message.isFromMe) {
            _editingMessage.value = message
        }
    }

    fun cancelEditing() {
        _editingMessage.value = null
    }

    // Group management using UseCase
    fun kickMember(peerId: String) {
        executeGroupAction(peerId, ManageGroupMemberUseCase.GroupAction.Kick)
    }

    fun banMember(peerId: String) {
        executeGroupAction(peerId, ManageGroupMemberUseCase.GroupAction.Ban)
    }

    fun promoteToAdmin(peerId: String) {
        executeGroupAction(peerId, ManageGroupMemberUseCase.GroupAction.PromoteToAdmin)
    }

    private fun executeGroupAction(peerId: String, action: ManageGroupMemberUseCase.GroupAction) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            manageGroupMemberUseCase(chatId, peerId, action, myId).collect { result ->
                result.onFailure { error ->
                    _uiState.update { it.copy(error = error.message) }
                }
            }
        }
    }

    // Navigation
    fun navigateBack() {
        navigator.navigateBack()
    }

    // Group restrictions
    fun setSlowMode(seconds: Int) {
        viewModelScope.launch {
            val myId = keyManager.getPublicKeyBase64()
            if (database.groupDao().isUserAdminOrOwner(chatId, myId)) {
                database.groupDao().setSlowMode(chatId, seconds)
            }
        }
    }

    data class ChatUiState(
        val isLoading: Boolean = false,
        val error: String? = null,
        val isSelectionMode: Boolean = false
    )
}
