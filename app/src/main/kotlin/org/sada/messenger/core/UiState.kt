package org.sada.messenger.core

/**
 * Sealed class for representing UI states
 * Generic state wrapper for any data type T
 */
sealed class UiState<out T> {
    object Loading : UiState<Nothing>()
    data class Success<T>(val data: T) : UiState<T>()
    data class Error(val message: String, val exception: Throwable? = null) : UiState<Nothing>()
    object Idle : UiState<Nothing>()
}

/**
 * Extension functions for UiState
 */
fun <T> UiState<T>.isLoading(): Boolean = this is UiState.Loading
fun <T> UiState<T>.isSuccess(): Boolean = this is UiState.Success
fun <T> UiState<T>.isError(): Boolean = this is UiState.Error
fun <T> UiState<T>.isIdle(): Boolean = this is UiState.Idle

fun <T> UiState<T>.getDataOrNull(): T? = (this as? UiState.Success)?.data
fun <T> UiState<T>.getErrorMessage(): String? = (this as? UiState.Error)?.message

/**
 * Transform Success data
 */
inline fun <T, R> UiState<T>.map(transform: (T) -> R): UiState<R> {
    return when (this) {
        is UiState.Success -> UiState.Success(transform(data))
        is UiState.Loading -> UiState.Loading
        is UiState.Error -> UiState.Error(message, exception)
        is UiState.Idle -> UiState.Idle
    }
}

/**
 * Handle states with callbacks
 */
inline fun <T> UiState<T>.handle(
    onLoading: () -> Unit = {},
    onSuccess: (T) -> Unit = {},
    onError: (String, Throwable?) -> Unit = { _, _ -> },
    onIdle: () -> Unit = {}
) {
    when (this) {
        is UiState.Loading -> onLoading()
        is UiState.Success -> onSuccess(data)
        is UiState.Error -> onError(message, exception)
        is UiState.Idle -> onIdle()
    }
}
