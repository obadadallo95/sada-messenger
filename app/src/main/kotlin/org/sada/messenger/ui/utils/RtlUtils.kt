package org.sada.messenger.ui.utils

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.composed
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp

/**
 * RTL (Right-to-Left) Utilities
 * Provides comprehensive support for Arabic and other RTL languages
 */

/**
 * RTL Layout Wrapper
 * Automatically mirrors layout for RTL languages
 */
@Composable
fun RtlLayout(
    isRtl: Boolean = true,
    content: @Composable () -> Unit
) {
    val direction = if (isRtl) LayoutDirection.Rtl else LayoutDirection.Ltr
    
    CompositionLocalProvider(
        LocalLayoutDirection provides direction
    ) {
        content()
    }
}

/**
 * Row that supports both LTR and RTL
 */
@Composable
fun DirectionalRow(
    modifier: Modifier = Modifier,
    horizontalArrangement: Arrangement.Horizontal = Arrangement.Start,
    verticalAlignment: Alignment.Vertical = Alignment.Top,
    content: @Composable RowScope.() -> Unit
) {
    val layoutDirection = LocalLayoutDirection.current
    
    Row(
        modifier = modifier,
        horizontalArrangement = if (layoutDirection == LayoutDirection.Rtl) {
            // Mirror arrangement for RTL
            when (horizontalArrangement) {
                Arrangement.Start -> Arrangement.End
                Arrangement.End -> Arrangement.Start
                else -> horizontalArrangement
            }
        } else {
            horizontalArrangement
        },
        verticalAlignment = verticalAlignment,
        content = content
    )
}

/**
 * Text alignment that adapts to layout direction
 */
fun getDirectionalAlignment(isRtl: Boolean = true): androidx.compose.ui.text.style.TextAlign {
    return if (isRtl) {
        androidx.compose.ui.text.style.TextAlign.Right
    } else {
        androidx.compose.ui.text.style.TextAlign.Left
    }
}

/**
 * Modifier extension for RTL padding
 */
fun Modifier.rtlPadding(
    start: androidx.compose.ui.unit.Dp = 0.dp,
    end: androidx.compose.ui.unit.Dp = 0.dp,
    top: androidx.compose.ui.unit.Dp = 0.dp,
    bottom: androidx.compose.ui.unit.Dp = 0.dp
): Modifier = this.composed {
    padding(
        start = if (LocalLayoutDirection.current == LayoutDirection.Rtl) end else start,
        end = if (LocalLayoutDirection.current == LayoutDirection.Rtl) start else end,
        top = top,
        bottom = bottom
    )
}

/**
 * Modifier for mirrored horizontal arrangement
 */
fun Modifier.mirrorForRtl(): Modifier = this.composed {
    val layoutDirection = LocalLayoutDirection.current
    layout { measurable, constraints ->
        val placeable = measurable.measure(constraints)
        layout(placeable.width, placeable.height) {
            if (layoutDirection == LayoutDirection.Rtl) {
                placeable.placeRelative(placeable.width, 0)
            } else {
                placeable.placeRelative(0, 0)
            }
        }
    }
}

/**
 * Directional start padding
 */
fun Modifier.startPadding(padding: androidx.compose.ui.unit.Dp): Modifier = this.composed {
    if (LocalLayoutDirection.current == LayoutDirection.Rtl) {
        padding(end = padding)
    } else {
        padding(start = padding)
    }
}

/**
 * Directional end padding
 */
fun Modifier.endPadding(padding: androidx.compose.ui.unit.Dp): Modifier = this.composed {
    if (LocalLayoutDirection.current == LayoutDirection.Rtl) {
        padding(start = padding)
    } else {
        padding(end = padding)
    }
}

/**
 * Bi-directional text alignment helper
 */
@Composable
fun BidiText(
    text: String,
    modifier: Modifier = Modifier,
    style: androidx.compose.ui.text.TextStyle = androidx.compose.material3.MaterialTheme.typography.bodyLarge,
    maxLines: Int = Int.MAX_VALUE
) {
    // Detect if text contains RTL characters
    val hasRtl = text.any { char ->
        val directionality = java.lang.Character.getDirectionality(char)
        directionality == java.lang.Character.DIRECTIONALITY_RIGHT_TO_LEFT ||
        directionality == java.lang.Character.DIRECTIONALITY_RIGHT_TO_LEFT_ARABIC
    }
    
    val layoutDirection = if (hasRtl) LayoutDirection.Rtl else LayoutDirection.Ltr
    
    androidx.compose.material3.Text(
        text = text,
        modifier = modifier,
        style = style,
        textAlign = if (hasRtl) androidx.compose.ui.text.style.TextAlign.Right else androidx.compose.ui.text.style.TextAlign.Left,
        maxLines = maxLines
    )
}

/**
 * Arabic number formatting
 * Converts Western numerals (0-9) to Arabic numerals (٠-٩)
 */
fun String.toArabicNumerals(): String {
    val arabicNumerals = charArrayOf('٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩')
    return this.map { char ->
        if (char in '0'..'9') {
            arabicNumerals[char - '0']
        } else {
            char
        }
    }.joinToString("")
}

/**
 * Format Arabic date
 */
fun formatArabicDate(timestamp: Long): String {
    val date = java.util.Date(timestamp)
    val formatter = java.text.SimpleDateFormat("dd MMMM yyyy", java.util.Locale("ar"))
    return formatter.format(date)
}

/**
 * Format Arabic time
 */
fun formatArabicTime(timestamp: Long): String {
    val date = java.util.Date(timestamp)
    val formatter = java.text.SimpleDateFormat("HH:mm", java.util.Locale("ar"))
    return formatter.format(date).toArabicNumerals()
}

/**
 * Mirror icons for RTL
 */
@Composable
fun RtlIcon(
    icon: @Composable () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = if (LocalLayoutDirection.current == LayoutDirection.Rtl) {
            modifier.scale(-1f, 1f) // Mirror horizontally
        } else {
            modifier
        }
    ) {
        icon()
    }
}

/**
 * Message bubble alignment helper
 */
@Composable
fun RtlMessageBubbleLayout(
    isFromMe: Boolean,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    val layoutDirection = LocalLayoutDirection.current
    val isRtl = layoutDirection == LayoutDirection.Rtl
    
    // In RTL, "from me" bubbles should be on the left (not right)
    val actualAlignment = when {
        isRtl && isFromMe -> Alignment.CenterStart
        isRtl && !isFromMe -> Alignment.CenterEnd
        !isRtl && isFromMe -> Alignment.CenterEnd
        else -> Alignment.CenterStart
    }
    
    Box(
        modifier = modifier.fillMaxWidth(),
        contentAlignment = actualAlignment
    ) {
        content()
    }
}

/**
 * Layout direction detector
 */
@Composable
fun isRtl(): Boolean {
    return LocalLayoutDirection.current == LayoutDirection.Rtl
}

/**
 * Get start/end based on layout direction
 */
@Composable
fun <T> directionalValue(ltrValue: T, rtlValue: T): T {
    return if (LocalLayoutDirection.current == LayoutDirection.Rtl) rtlValue else ltrValue
}

/**
 * Mirror arrangement for RTL
 */
fun Arrangement.Horizontal.mirror(): Arrangement.Horizontal {
    return when (this) {
        Arrangement.Start -> Arrangement.End
        Arrangement.End -> Arrangement.Start
        else -> this
    }
}

/**
 * RTL Spacer
 */
@Composable
fun RtlSpacer(width: androidx.compose.ui.unit.Dp) {
    Spacer(
        modifier = Modifier
            .width(width)
            .rtlPadding(start = 0.dp, end = 0.dp)
    )
}

/**
 * Directional divider
 */
@Composable
fun DirectionalDivider(
    modifier: Modifier = Modifier,
    thickness: androidx.compose.ui.unit.Dp = 1.dp,
    color: androidx.compose.ui.graphics.Color = org.sada.messenger.ui.theme.TextSecondary.copy(alpha = 0.2f)
) {
    val layoutDirection = LocalLayoutDirection.current
    
    androidx.compose.material3.HorizontalDivider(
        modifier = modifier,
        thickness = thickness,
        color = color
    )
}

/**
 * RTL List with proper item alignment
 */
@Composable
fun <T> RtlLazyColumn(
    items: List<T>,
    modifier: Modifier = Modifier,
    itemContent: @Composable (T) -> Unit
) {
    val layoutDirection = LocalLayoutDirection.current
    
    androidx.compose.foundation.lazy.LazyColumn(
        modifier = modifier,
        horizontalAlignment = if (layoutDirection == LayoutDirection.Rtl) {
            Alignment.End
        } else {
            Alignment.Start
        }
    ) {
        items(items.size) { index ->
            itemContent(items[index])
        }
    }
}

/**
 * Force RTL for specific content
 */
@Composable
fun ForceRtl(content: @Composable () -> Unit) {
    CompositionLocalProvider(
        LocalLayoutDirection provides LayoutDirection.Rtl
    ) {
        content()
    }
}

/**
 * Force LTR for specific content (e.g., phone numbers, codes)
 */
@Composable
fun ForceLtr(content: @Composable () -> Unit) {
    CompositionLocalProvider(
        LocalLayoutDirection provides LayoutDirection.Ltr
    ) {
        content()
    }
}
