package org.sada.messenger.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

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

@Composable
fun SadaTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    // We always use dark theme for Sada's Cyber-Stealth aesthetic
    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = Typography,
        content = content
    )
}
