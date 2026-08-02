package org.sada.messenger.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.runtime.MeshRuntimeController
import org.sada.messenger.security.EncryptionManager
import org.sada.messenger.security.KeyManager
import org.sada.messenger.managers.VideoEngine
import org.sada.messenger.managers.AudioRecorderManager

class SadaViewModelFactory(
    private val database: AppDatabase,
    private val meshRuntime: MeshRuntimeController,
    private val keyManager: KeyManager,
    private val encryptionManager: EncryptionManager,
    private val videoEngine: VideoEngine,
    private val audioRecorderManager: AudioRecorderManager
) : ViewModelProvider.Factory {
    
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: androidx.lifecycle.viewmodel.CreationExtras): T {
        return when {
            modelClass.isAssignableFrom(HomeViewModel::class.java) -> {
                HomeViewModel(database, meshRuntime, keyManager) as T
            }
            modelClass.isAssignableFrom(ContactsViewModel::class.java) -> {
                ContactsViewModel(database, meshRuntime) as T
            }
            modelClass.isAssignableFrom(CrisisReportViewModel::class.java) -> {
                CrisisReportViewModel(videoEngine, audioRecorderManager) as T
            }
            // Note: ChatViewModel needs chatId which we'll provide via a custom method or assist 
            else -> throw IllegalArgumentException("Unknown ViewModel class")
        }
    }

    fun createChatViewModel(chatId: String): ChatViewModel {
        return ChatViewModel(
            chatId,
            database,
            meshRuntime,
            keyManager,
            encryptionManager,
            audioRecorderManager
        )
    }
}
