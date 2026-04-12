package org.sada.messenger.core

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Base ViewModel with common functionality
 * All ViewModels should extend this class
 */
abstract class BaseViewModel<State : Any, Event : Any>(
    initialState: State
) : ViewModel() {

    private val _uiState = MutableStateFlow(initialState)
    val uiState: StateFlow<State> = _uiState.asStateFlow()

    private val _uiEvent = EventHandler<Event>()
    val uiEvent = _uiEvent.events

    protected val currentState: State
        get() = _uiState.value

    /**
     * Update state safely
     */
    protected fun updateState(update: (State) -> State) {
        _uiState.value = update(_uiState.value)
    }

    /**
     * Emit one-time event
     */
    protected fun emitEvent(event: Event) {
        _uiEvent.tryEmit(event)
    }

    /**
     * Launch coroutine with loading state handling
     */
    protected fun <T> launchWithLoading(
        loadingState: (State, Boolean) -> State,
        onSuccess: (State, T) -> State,
        onError: (State, Throwable) -> State,
        dispatcher: CoroutineDispatcher = Dispatchers.IO,
        block: suspend () -> T
    ) {
        viewModelScope.launch {
            updateState { loadingState(it, true) }
            try {
                val result = withContext(dispatcher) { block() }
                updateState { onSuccess(it, result) }
            } catch (e: Exception) {
                updateState { onError(it, e) }
            } finally {
                updateState { loadingState(it, false) }
            }
        }
    }

    /**
     * Execute use case and handle result
     */
    protected fun <T> executeUseCase(
        useCaseFlow: kotlinx.coroutines.flow.Flow<Result<T>>,
        onSuccess: (State, T) -> State,
        onError: (State, Throwable) -> State,
        onLoading: ((State) -> State)? = null
    ) {
        viewModelScope.launch {
            useCaseFlow.collect { result ->
                when (result) {
                    is Result.Loading -> {
                        onLoading?.let { updateState { it(it) } }
                    }
                    is Result.Success -> {
                        updateState { onSuccess(it, result.data) }
                    }
                    is Result.Error -> {
                        updateState { onError(it, result.exception) }
                    }
                }
            }
        }
    }
}

/**
 * Empty state for simple ViewModels
 */
object EmptyState

/**
 * Empty event for simple ViewModels
 */
object EmptyEvent
