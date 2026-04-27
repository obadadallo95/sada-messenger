package org.sada.messenger.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

data class SadaColorPalette(
    val background: Color,
    val surface: Color,
    val surfaceVariant: Color,
    val textPrimary: Color,
    val textSecondary: Color,
    val neonTeal: Color,
    val cyberBlue: Color,
    val successGreen: Color,
    val errorRed: Color,
    val isDark: Boolean
)

fun darkSadaPalette() = SadaColorPalette(
    background    = Color(0xFF000000),
    surface       = Color(0xFF13131A),
    surfaceVariant= Color(0xFF1C1C28),
    textPrimary   = Color(0xFFFFFFFF),
    textSecondary = Color(0xFF8B8FA8),
    neonTeal      = Color(0xFF00F5FF),
    cyberBlue     = Color(0xFF4F8EF7),
    successGreen  = Color(0xFF2ECC71),
    errorRed      = Color(0xFFE74C3C),
    isDark        = true
)

fun lightSadaPalette() = SadaColorPalette(
    background    = Color(0xFFDDE4EF),  // muted blue-grey — no glare
    surface       = Color(0xFFEBEFF7),  // soft off-white, no pure white
    surfaceVariant= Color(0xFFD0D8E6),  // clear contrast without harshness
    textPrimary   = Color(0xFF14223A),  // dark navy — softer than black
    textSecondary = Color(0xFF4D6278),  // readable without strain
    neonTeal      = Color(0xFF007570),  // deep teal readable on light bg
    cyberBlue     = Color(0xFF1A5BA0),  // deep blue
    successGreen  = Color(0xFF1A7A3C),
    errorRed      = Color(0xFFCC3333),
    isDark        = false
)

val LocalSadaPalette = staticCompositionLocalOf { darkSadaPalette() }

val MaterialTheme.sadaColors: SadaColorPalette
    @Composable get() = LocalSadaPalette.current

private val DarkColorScheme = darkColorScheme(
    primary = NeonTeal,
    secondary = CyberBlue,
    tertiary = ShadowGrey,
    background = OLEDBlack,
    surface = StealthSlate,
    onPrimary = Color.Black,
    onSecondary = Color.Black,
    onBackground = GhostWhite,
    onSurface = GhostWhite,
    error = ErrorRed
)

private val LightColorScheme = lightColorScheme(
    primary = Color(0xFF007570),
    secondary = Color(0xFF1A5BA0),
    tertiary = Color(0xFF4D6278),
    background = Color(0xFFDDE4EF),
    surface = Color(0xFFEBEFF7),
    surfaceVariant = Color(0xFFD0D8E6),
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = Color(0xFF14223A),
    onSurface = Color(0xFF14223A),
    onSurfaceVariant = Color(0xFF4D6278),
    error = Color(0xFFCC3333)
)

enum class SadaThemeMode {
    SYSTEM,
    DARK,
    LIGHT
}

@Composable
fun SadaTheme(
    themeMode: SadaThemeMode = SadaThemeMode.DARK,
    content: @Composable () -> Unit
) {
    val darkTheme = when (themeMode) {
        SadaThemeMode.SYSTEM -> isSystemInDarkTheme()
        SadaThemeMode.DARK -> true
        SadaThemeMode.LIGHT -> false
    }

    val palette = if (darkTheme) darkSadaPalette() else lightSadaPalette()
    CompositionLocalProvider(LocalSadaPalette provides palette) {
        MaterialTheme(
            colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme,
            typography = Typography,
            content = content
        )
    }
}
