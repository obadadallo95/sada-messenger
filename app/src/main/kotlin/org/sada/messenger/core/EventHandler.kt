package org.sada.messenger.core

import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.receiveAsFlow

/**
 * Event Handler for one-time events
 * Used for navigation, snackbars, toasts that shouldn't survive config changes
 */
class EventHandler<T> {
    private val eventChannel = Channel<T>(Channel.BUFFERED)
    val events = eventChannel.receiveAsFlow()

    suspend fun emit(event: T) {
        eventChannel.send(event)
    }

    fun tryEmit(event: T): Boolean {
        return eventChannel.trySend(event).isSuccess
    }
}

/**
 * Common UI Events
 */
sealed class UiEvent {
    data class ShowSnackbar(val message: String) : UiEvent()
    data class ShowToast(val message: String) : UiEvent()
    data class Navigate(val route: String) : UiEvent()
    object NavigateBack : UiEvent()
    data class ShowDialog(val title: String, val message: String) : UiEvent()
}
