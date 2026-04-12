package org.sada.messenger.presentation.navigation

import androidx.navigation.NavController
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * App Navigator
 * Centralized navigation manager for the app
 * Allows navigation from ViewModels and Use Cases
 */
@Singleton
class AppNavigator @Inject constructor() {

    private val _navigationCommand = MutableSharedFlow<NavigationCommand>(extraBufferCapacity = 1)
    val navigationCommand: SharedFlow<NavigationCommand> = _navigationCommand.asSharedFlow()

    private var navController: NavController? = null

    fun setNavController(controller: NavController) {
        navController = controller
    }

    fun navigateTo(route: String, args: Map<String, Any>? = null) {
        _navigationCommand.tryEmit(NavigationCommand.NavigateTo(route, args))
    }

    fun navigateBack() {
        _navigationCommand.tryEmit(NavigationCommand.NavigateBack)
    }

    fun navigateUp() {
        navController?.navigateUp()
    }

    sealed class NavigationCommand {
        data class NavigateTo(val route: String, val args: Map<String, Any>? = null) : NavigationCommand()
        object NavigateBack : NavigationCommand()
    }
}

/**
 * Screen Routes
 */
sealed class Screen(val route: String) {
    object Home : Screen("home")
    object Chat : Screen("chat/{chatId}") {
        fun createRoute(chatId: String) = "chat/$chatId"
    }
    object Contacts : Screen("contacts")
    object Groups : Screen("groups")
    object CreateGroup : Screen("create_group")
    object GroupDetails : Screen("group_details/{groupId}") {
        fun createRoute(groupId: String) = "group_details/$groupId"
    }
    object Settings : Screen("settings")
    object Profile : Screen("profile")
}
