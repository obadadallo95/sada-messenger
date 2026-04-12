package org.sada.messenger.ui.theme

import androidx.compose.ui.graphics.Color

// === Core Palette (High-contrast for stressed users in difficult conditions) ===
val SadaBackground = Color(0xFF0A0A0F)    // Near black
val SadaSurface = Color(0xFF13131A)       // Slightly elevated
val SadaSurfaceVariant = Color(0xFF1C1C28) // Cards, dialogs
val SadaPrimary = Color(0xFF4F8EF7)       // Calm blue — trust
val SadaOnPrimary = Color(0xFFFFFFFF)

val SuccessGreen = Color(0xFF2ECC71)       // Connected / verified
val WarningAmber = Color(0xFFF39C12)       // Caution
val ErrorRed = Color(0xFFE74C3C)           // Danger / SOS
val TextPrimary = Color(0xFFFFFFFF)
val TextSecondary = Color(0xFF8B8FA8)

// === Legacy aliases (backward compat for existing screens) ===
val NeonTeal = Color(0xFF00F5FF)
val CyberBlue = Color(0xFF4F8EF7)
val DarkGrey = Color(0xFF0A0A0F)
val OLEDBlack = Color(0xFF000000)
val StealthSlate = Color(0xFF13131A)
val ShadowGrey = Color(0xFF334155)
val GhostWhite = Color(0xFFF1F5F9)

// === Semantic colors ===
val MeshActive = SuccessGreen
val MeshInactive = TextSecondary
val VerifiedBadge = SuccessGreen
val PendingBadge = WarningAmber
val BlockedBadge = ErrorRed
val UnverifiedOverlay = Color(0x80000000)
