package org.sada.messenger.ui.theme

import android.content.Context
import android.content.res.Configuration
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.LocalContext
import kotlinx.coroutines.flow.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Theme Manager
 * Handles Dark/Light mode switching and system theme detection
 */
@Singleton
class ThemeManager @Inject constructor(
    private val context: Context
) {
    private val _themeMode = MutableStateFlow(SadaThemeMode.SYSTEM)
    val themeMode: StateFlow<SadaThemeMode> = _themeMode.asStateFlow()

    private val _isDarkTheme = MutableStateFlow(false)
    val isDarkTheme: StateFlow<Boolean> = _isDarkTheme.asStateFlow()

    init {
        loadSavedTheme()
    }

    private fun loadSavedTheme() {
        val prefs = context.getSharedPreferences("sada_theme", Context.MODE_PRIVATE)
        val savedMode = prefs.getString("theme_mode", SadaThemeMode.SYSTEM.name)
        _themeMode.value = SadaThemeMode.valueOf(savedMode ?: "SYSTEM")
        updateIsDarkTheme()
    }

    private fun updateIsDarkTheme() {
        val isSystemDark = context.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES

        _isDarkTheme.value = when (_themeMode.value) {
            SadaThemeMode.DARK -> true
            SadaThemeMode.LIGHT -> false
            SadaThemeMode.SYSTEM -> isSystemDark
        }
    }

    fun setThemeMode(mode: SadaThemeMode) {
        _themeMode.value = mode
        updateIsDarkTheme()

        // Save preference
        context.getSharedPreferences("sada_theme", Context.MODE_PRIVATE)
            .edit()
            .putString("theme_mode", mode.name)
            .apply()
    }

    fun toggleTheme() {
        val newMode = when (_themeMode.value) {
            SadaThemeMode.LIGHT -> SadaThemeMode.DARK
            SadaThemeMode.DARK -> SadaThemeMode.LIGHT
            SadaThemeMode.SYSTEM -> {
                if (_isDarkTheme.value) SadaThemeMode.LIGHT else SadaThemeMode.DARK
            }
        }
        setThemeMode(newMode)
    }
}

/**
 * Adaptive Sada Theme
 * Automatically adapts to system theme changes
 */
@Composable
fun AdaptiveSadaTheme(
    themeManager: ThemeManager,
    content: @Composable () -> Unit
) {
    val themeMode by themeManager.themeMode.collectAsState()
    val isDarkTheme by themeManager.isDarkTheme.collectAsState()

    // Listen to system theme changes
    val systemInDarkTheme = isSystemInDarkTheme()

    LaunchedEffect(systemInDarkTheme, themeMode) {
        if (themeMode == SadaThemeMode.SYSTEM) {
            themeManager.setThemeMode(SadaThemeMode.SYSTEM)
        }
    }

    val colorScheme = if (isDarkTheme) {
        DarkColorScheme
    } else {
        LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}

// Extended color schemes
private val LightColorScheme = lightColorScheme(
    primary = Color(0xFF00897B),
    onPrimary = Color.White,
    primaryContainer = Color(0xFFB2DFDB),
    onPrimaryContainer = Color(0xFF004D40),
    secondary = Color(0xFF0277BD),
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFB3E5FC),
    onSecondaryContainer = Color(0xFF01579B),
    tertiary = Color(0xFF455A64),
    onTertiary = Color.White,
    background = Color(0xFFF5F5F5),
    onBackground = Color(0xFF212121),
    surface = Color(0xFFFFFFFF),
    onSurface = Color(0xFF212121),
    surfaceVariant = Color(0xFFE0E0E0),
    onSurfaceVariant = Color(0xFF616161),
    error = Color(0xFFD32F2F),
    onError = Color.White,
    errorContainer = Color(0xFFFFCDD2),
    onErrorContainer = Color(0xFFB71C1C)
)

private val DarkColorScheme = darkColorScheme(
    primary = NeonTeal,
    onPrimary = Color.Black,
    primaryContainer = Color(0xFF004D40),
    onPrimaryContainer = Color(0xFFB2DFDB),
    secondary = CyberBlue,
    onSecondary = Color.Black,
    secondaryContainer = Color(0xFF01579B),
    onSecondaryContainer = Color(0xFFB3E5FC),
    tertiary = ShadowGrey,
    onTertiary = Color.White,
    background = OLEDBlack,
    onBackground = GhostWhite,
    surface = StealthSlate,
    onSurface = GhostWhite,
    surfaceVariant = ShadowGrey,
    onSurfaceVariant = GhostWhite.copy(alpha = 0.7f),
    error = ErrorRed,
    onError = Color.White,
    errorContainer = Color(0xFFB71C1C),
    onErrorContainer = Color(0xFFFFCDD2)
)

// Contrast ratios for accessibility
object ContrastRatios {
    const val NORMAL_TEXT = 4.5f
    const val LARGE_TEXT = 3.0f
    const val UI_COMPONENTS = 3.0f
}

// Color contrast checker
fun Color.contrastRatio(background: Color): Float {
    val luminance1 = this.luminance()
    val luminance2 = background.luminance()
    val lighter = kotlin.math.max(luminance1, luminance2)
    val darker = kotlin.math.min(luminance1, luminance2)
    return (lighter + 0.05f) / (darker + 0.05f)
}

// Check if color meets WCAG AA standard
fun Color.meetsWcagAa(background: Color, isLargeText: Boolean = false): Boolean {
    val ratio = contrastRatio(background)
    return if (isLargeText) {
        ratio >= ContrastRatios.LARGE_TEXT
    } else {
        ratio >= ContrastRatios.NORMAL_TEXT
    }
}
