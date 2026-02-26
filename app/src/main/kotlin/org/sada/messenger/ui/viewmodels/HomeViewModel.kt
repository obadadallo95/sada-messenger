package org.sada.messenger.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.data.entities.ChatEntity
import org.sada.messenger.network.MeshEngine
import java.util.*

class HomeViewModel(
    private val database: AppDatabase,
    private val meshEngine: MeshEngine
) : ViewModel() {
    val chats: StateFlow<List<ChatEntity>> = database.chatDao()
        .getAllChats()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    fun createGroup(name: String, members: List<String>) {
        viewModelScope.launch {
            val groupId = "group_" + UUID.randomUUID().toString()
            val groupKey = meshEngine.generateGroupKey()
            
            val chat = ChatEntity(
                id = groupId,
                name = name,
                isGroup = true,
                groupKey = groupKey
            )
            database.chatDao().insertChat(chat)
            
            // Send invitations to members
            members.forEach { peerId ->
                meshEngine.sendGroupInvitation(peerId, groupId, name, groupKey)
            }
        }
    }
    
    fun triggerSos() {
        viewModelScope.launch {
            // In a real app, we'd fetch actual GPS coordinates
            // For now, we use a default/mock location
            meshEngine.sendSosBroadcast(33.5138, 36.2765) // Damascus coordinates
        }
    }
}
