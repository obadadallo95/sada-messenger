package org.sada.messenger.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import org.sada.messenger.ui.theme.*
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.derivedStateOf

/**
 * Glass-morphism Design System Components
 * Provides frosted glass effects optimized for dark mode
 */

/**
 * Glass Card - Main container with glass effect
 */
@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 16.dp,
    blurRadius: Dp = 8.dp,
    borderWidth: Dp = 0.5.dp,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = modifier
            .glassBackground(cornerRadius, blurRadius, borderWidth)
            .padding(16.dp),
        content = content
    )
}

/**
 * Glass Surface - Lower level glass effect
 */
@Composable
fun GlassSurface(
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 12.dp,
    content: @Composable BoxScope.() -> Unit
) {
    val c = LocalSadaPalette.current
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(cornerRadius))
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        c.surface.copy(alpha = 0.7f),
                        c.surfaceVariant.copy(alpha = 0.5f)
                    )
                )
            )
            .border(
                width = 0.5.dp,
                color = c.textSecondary.copy(alpha = 0.2f),
                shape = RoundedCornerShape(cornerRadius)
            ),
        content = content
    )
}

/**
 * Glass Button - Button with glass effect
 */
@Composable
fun GlassButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    content: @Composable RowScope.() -> Unit
) {
    val c = LocalSadaPalette.current
    Button(
        onClick = onClick,
        modifier = modifier,
        enabled = enabled,
        colors = ButtonDefaults.buttonColors(
            containerColor = c.neonTeal.copy(alpha = 0.2f),
            contentColor = c.textPrimary,
            disabledContainerColor = c.surface.copy(alpha = 0.3f),
            disabledContentColor = c.textSecondary
        ),
        shape = RoundedCornerShape(12.dp),
        border = androidx.compose.foundation.BorderStroke(
            width = 1.dp,
            color = SadaPrimary.copy(alpha = 0.3f)
        )
    ) {
        content()
    }
}

/**
 * Glass Input Field - Text input with glass effect
 */
@Composable
fun GlassInputField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "",
    leadingIcon: @Composable (() -> Unit)? = null,
    trailingIcon: @Composable (() -> Unit)? = null
) {
    val c = LocalSadaPalette.current
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = modifier,
        placeholder = { Text(placeholder, color = c.textSecondary) },
        leadingIcon = leadingIcon,
        trailingIcon = trailingIcon,
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = c.surface.copy(alpha = 0.5f),
            unfocusedContainerColor = c.surface.copy(alpha = 0.3f),
            focusedBorderColor = c.neonTeal.copy(alpha = 0.5f),
            unfocusedBorderColor = c.textSecondary.copy(alpha = 0.2f),
            focusedTextColor = c.textPrimary,
            unfocusedTextColor = c.textPrimary
        ),
        shape = RoundedCornerShape(12.dp)
    )
}

/**
 * Glass Message Bubble - Enhanced message bubble
 */
@Composable
fun GlassMessageBubble(
    isFromMe: Boolean,
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit
) {
    val backgroundColor = if (isFromMe) {
        SadaPrimary.copy(alpha = 0.15f)
    } else {
        SadaSurfaceVariant.copy(alpha = 0.5f)
    }
    
    val borderColor = if (isFromMe) {
        SadaPrimary.copy(alpha = 0.3f)
    } else {
        TextSecondary.copy(alpha = 0.2f)
    }
    
    Box(
        modifier = modifier
            .padding(horizontal = 8.dp, vertical = 4.dp)
            .background(
                color = backgroundColor,
                shape = RoundedCornerShape(
                    topStart = if (isFromMe) 16.dp else 4.dp,
                    topEnd = if (isFromMe) 4.dp else 16.dp,
                    bottomStart = 16.dp,
                    bottomEnd = 16.dp
                )
            )
            .border(
                width = 0.5.dp,
                color = borderColor,
                shape = RoundedCornerShape(
                    topStart = if (isFromMe) 16.dp else 4.dp,
                    topEnd = if (isFromMe) 4.dp else 16.dp,
                    bottomStart = 16.dp,
                    bottomEnd = 16.dp
                )
            )
            .padding(12.dp),
        content = content
    )
}

/**
 * Glass App Bar - Top navigation bar with glass effect
 */
@Composable
fun GlassAppBar(
    title: String,
    modifier: Modifier = Modifier,
    navigationIcon: @Composable (() -> Unit)? = null,
    actions: @Composable RowScope.() -> Unit = {}
) {
    val c = LocalSadaPalette.current
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(56.dp)
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        c.background.copy(alpha = 0.95f),
                        c.background.copy(alpha = 0.8f)
                    )
                )
            )
            .border(
                width = 0.5.dp,
                color = c.textSecondary.copy(alpha = 0.1f),
                shape = RoundedCornerShape(bottomStart = 16.dp, bottomEnd = 16.dp)
            ),
        contentAlignment = Alignment.CenterStart
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                navigationIcon?.invoke()
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    color = c.textPrimary
                )
            }
            Row {
                actions()
            }
        }
    }
}

/**
 * Glass Bottom Bar - Bottom navigation with glass effect
 */
@Composable
fun GlassBottomBar(
    modifier: Modifier = Modifier,
    content: @Composable RowScope.() -> Unit
) {
    val c = LocalSadaPalette.current
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(64.dp)
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        c.background.copy(alpha = 0.7f),
                        c.background.copy(alpha = 0.9f)
                    )
                )
            )
            .border(
                width = 0.5.dp,
                color = c.textSecondary.copy(alpha = 0.1f),
                shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)
            )
            .clip(RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)),
        contentAlignment = Alignment.Center
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically,
            content = content
        )
    }
}

/**
 * Glass Chip - Small selectable chip
 */
@Composable
fun GlassChip(
    text: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: @Composable (() -> Unit)? = null
) {
    val backgroundColor = if (selected) {
        SadaPrimary.copy(alpha = 0.25f)
    } else {
        SadaSurface.copy(alpha = 0.4f)
    }
    
    val borderColor = if (selected) {
        SadaPrimary.copy(alpha = 0.5f)
    } else {
        TextSecondary.copy(alpha = 0.2f)
    }
    
    Surface(
        onClick = onClick,
        modifier = modifier,
        color = backgroundColor,
        shape = RoundedCornerShape(20.dp),
        border = androidx.compose.foundation.BorderStroke(
            width = 0.5.dp,
            color = borderColor
        )
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            icon?.invoke()
            Text(
                text = text,
                style = MaterialTheme.typography.labelLarge,
                color = if (selected) SadaPrimary else TextPrimary
            )
        }
    }
}

/**
 * Glass Dialog - Modal dialog with glass effect
 */
@Composable
fun GlassDialog(
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        containerColor = SadaSurface.copy(alpha = 0.9f),
        shape = RoundedCornerShape(20.dp),
        text = { content() },
        confirmButton = {}
    )
}

@Composable
fun GlassAlertDialog(
    onDismissRequest: () -> Unit,
    title: String,
    text: String,
    confirmButton: @Composable () -> Unit,
    dismissButton: @Composable (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val c = LocalSadaPalette.current
    AlertDialog(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        containerColor = c.surface.copy(alpha = 0.95f),
        shape = RoundedCornerShape(20.dp),
        title = { Text(title, color = c.textPrimary) },
        text = { Text(text, color = c.textSecondary) },
        confirmButton = confirmButton,
        dismissButton = dismissButton
    )
}

/**
 * Modifier extension for glass background effect
 */
fun Modifier.glassBackground(
    cornerRadius: Dp = 16.dp,
    blurRadius: Dp = 8.dp,
    borderWidth: Dp = 0.5.dp
): Modifier = this
    .clip(RoundedCornerShape(cornerRadius))
    .background(
        Brush.verticalGradient(
            colors = listOf(
                SadaSurface.copy(alpha = 0.6f),
                SadaSurfaceVariant.copy(alpha = 0.4f)
            )
        )
    )
    .border(
        width = borderWidth,
        brush = Brush.linearGradient(
            colors = listOf(
                TextSecondary.copy(alpha = 0.3f),
                SadaPrimary.copy(alpha = 0.1f)
            )
        ),
        shape = RoundedCornerShape(cornerRadius)
    )

/**
 * Gradient text effect
 */
@Composable
fun GradientText(
    text: String,
    gradient: Brush = Brush.linearGradient(
        colors = listOf(NeonTeal, CyberBlue),
        start = Offset(0f, 0f),
        end = Offset(100f, 0f)
    ),
    style: androidx.compose.ui.text.TextStyle = MaterialTheme.typography.titleLarge
) {
    Text(
        text = text,
        style = style.copy(
            brush = gradient
        )
    )
}

/**
 * Mesh status indicator with glass effect
 */
@Composable
fun MeshStatusIndicator(
    isConnected: Boolean,
    peerCount: Int,
    modifier: Modifier = Modifier
) {
    GlassSurface(
        modifier = modifier,
        cornerRadius = 20.dp
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .background(
                        color = if (isConnected) SuccessGreen else ErrorRed,
                        shape = RoundedCornerShape(4.dp)
                    )
            )
            Text(
                text = if (isConnected) "$peerCount peers" else "Offline",
                style = MaterialTheme.typography.labelSmall,
                color = if (isConnected) SuccessGreen else ErrorRed
            )
        }
    }
}
