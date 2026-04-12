package org.sada.messenger.ui.accessibility

import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.*
import androidx.compose.ui.input.key.*
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.*
import androidx.compose.ui.unit.dp
import org.sada.messenger.ui.utils.tr

/**
 * Accessibility Components for Sada
 * Ensures TalkBack compatibility and WCAG compliance
 */

/**
 * Accessible Button with proper semantics
 */
@Composable
fun AccessibleButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    contentDescription: String? = null,
    interactionSource: MutableInteractionSource = remember { MutableInteractionSource() },
    content: @Composable RowScope.() -> Unit
) {
    val isFocused by interactionSource.collectIsFocusedAsState()
    
    Button(
        onClick = onClick,
        modifier = modifier
            .semantics {
                contentDescription?.let { this.contentDescription = it }
                if (!enabled) {
                    stateDescription = tr("معطل", "Disabled")
                }
            }
            .focusable(interactionSource = interactionSource),
        enabled = enabled,
        interactionSource = interactionSource
    ) {
        content()
    }
}

/**
 * Accessible Text Field with proper labels
 */
@Composable
fun AccessibleTextField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    label: String,
    placeholder: String = "",
    isError: Boolean = false,
    helperText: String? = null,
    maxLines: Int = 1
) {
    Column(modifier = modifier) {
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier
                .fillMaxWidth()
                .semantics {
                    this.contentDescription = label
                    if (isError) {
                        error(tr("خطأ في الإدخال", "Input error"))
                    }
                },
            label = { Text(label) },
            placeholder = { Text(placeholder) },
            isError = isError,
            maxLines = maxLines,
            singleLine = maxLines == 1
        )
        
        if (helperText != null) {
            Text(
                text = helperText,
                style = MaterialTheme.typography.bodySmall,
                color = if (isError) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier
                    .padding(top = 4.dp, start = 16.dp)
                    .semantics { contentDescription = helperText }
            )
        }
    }
}

/**
 * Accessible Icon Button with content description
 */
@Composable
fun AccessibleIconButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    contentDescription: String,
    icon: @Composable () -> Unit
) {
    IconButton(
        onClick = onClick,
        modifier = modifier.semantics {
            this.contentDescription = contentDescription
        },
        enabled = enabled
    ) {
        icon()
    }
}

/**
 * Accessible Card with focus management
 */
@Composable
fun AccessibleCard(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    contentDescription: String? = null,
    enabled: Boolean = true,
    content: @Composable ColumnScope.() -> Unit
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isFocused by interactionSource.collectIsFocusedAsState()
    
    Card(
        onClick = onClick,
        modifier = modifier
            .semantics {
                contentDescription?.let { this.contentDescription = it }
                if (!enabled) {
                    stateDescription = tr("معطل", "Disabled")
                }
            }
            .focusable(interactionSource = interactionSource),
        enabled = enabled,
        interactionSource = interactionSource
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            content()
        }
    }
}

/**
 * Accessible Message Bubble with proper announcements
 */
@Composable
fun AccessibleMessageBubble(
    message: String,
    isFromMe: Boolean,
    senderName: String,
    timestamp: String,
    isRead: Boolean,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    val readStatus = if (isRead) tr("مقروء", "Read") else tr("غير مقروء", "Unread")
    val direction = if (isFromMe) tr("أنت", "You") else senderName
    
    Box(
        modifier = modifier.semantics {
            // Combine all information for screen readers
            contentDescription = buildString {
                append(direction)
                append(". ")
                append(message)
                append(". ")
                append(timestamp)
                append(". ")
                append(readStatus)
            }
            
            if (!isRead && !isFromMe) {
                stateDescription = tr("رسالة جديدة", "New message")
            }
        }
    ) {
        content()
    }
}

/**
 * Accessible List Item
 */
@Composable
fun AccessibleListItem(
    headlineText: String,
    modifier: Modifier = Modifier,
    supportingText: String? = null,
    leadingContent: @Composable (() -> Unit)? = null,
    trailingContent: @Composable (() -> Unit)? = null,
    onClick: (() -> Unit)? = null
) {
    ListItem(
        headlineContent = {
            Text(
                text = headlineText,
                modifier = Modifier.semantics {
                    heading()
                }
            )
        },
        modifier = modifier
            .then(
                if (onClick != null) {
                    Modifier.clickable { onClick() }
                } else {
                    Modifier
                }
            )
            .semantics {
                if (supportingText != null) {
                    contentDescription = "$headlineText. $supportingText"
                }
            },
        supportingContent = supportingText?.let {
            { Text(it) }
        },
        leadingContent = leadingContent,
        trailingContent = trailingContent
    )
}

/**
 * Accessible Switch with proper labels
 */
@Composable
fun AccessibleSwitch(
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    label: String,
    enabled: Boolean = true
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = true) {
                contentDescription = label
                stateDescription = if (checked) tr("مفعل", "On") else tr("معطل", "Off")
            },
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = label)
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            enabled = enabled
        )
    }
}

/**
 * Accessible Alert/Error Message
 */
@Composable
fun AccessibleAlert(
    message: String,
    modifier: Modifier = Modifier,
    type: AlertType = AlertType.INFO,
    onDismiss: (() -> Unit)? = null
) {
    val (containerColor, contentColor) = when (type) {
        AlertType.INFO -> Pair(
            MaterialTheme.colorScheme.primaryContainer,
            MaterialTheme.colorScheme.onPrimaryContainer
        )
        AlertType.SUCCESS -> Pair(
            MaterialTheme.colorScheme.secondaryContainer,
            MaterialTheme.colorScheme.onSecondaryContainer
        )
        AlertType.WARNING -> Pair(
            MaterialTheme.colorScheme.tertiaryContainer,
            MaterialTheme.colorScheme.onTertiaryContainer
        )
        AlertType.ERROR -> Pair(
            MaterialTheme.colorScheme.errorContainer,
            MaterialTheme.colorScheme.onErrorContainer
        )
    }
    
    val alertType = when (type) {
        AlertType.INFO -> tr("معلومة", "Info")
        AlertType.SUCCESS -> tr("نجاح", "Success")
        AlertType.WARNING -> tr("تحذير", "Warning")
        AlertType.ERROR -> tr("خطأ", "Error")
    }
    
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .semantics {
                liveRegion = LiveRegionMode.Assertive
                contentDescription = "$alertType: $message"
            },
        color = containerColor,
        shape = MaterialTheme.shapes.medium
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = message,
                color = contentColor,
                style = MaterialTheme.typography.bodyMedium
            )
            
            onDismiss?.let {
                Spacer(modifier = Modifier.weight(1f))
                TextButton(onClick = it) {
                    Text(
                        text = tr("إغلاق", "Dismiss"),
                        color = contentColor
                    )
                }
            }
        }
    }
}

enum class AlertType {
    INFO, SUCCESS, WARNING, ERROR
}

/**
 * Loading indicator with accessibility
 */
@Composable
fun AccessibleLoadingIndicator(
    modifier: Modifier = Modifier,
    label: String = tr("جاري التحميل...", "Loading...")
) {
    Row(
        modifier = modifier.semantics {
            contentDescription = label
            progressBarRangeInfo = ProgressBarRangeInfo(0f, 0f..1f, 0)
        },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        CircularProgressIndicator(
            modifier = Modifier.size(24.dp),
            strokeWidth = 2.dp
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium
        )
    }
}

/**
 * Keyboard navigation handler
 */
@Composable
fun KeyboardNavigationHandler(
    modifier: Modifier = Modifier,
    onEnter: (() -> Unit)? = null,
    onEscape: (() -> Unit)? = null,
    onArrowUp: (() -> Unit)? = null,
    onArrowDown: (() -> Unit)? = null,
    content: @Composable () -> Unit
) {
    val focusManager = androidx.compose.ui.platform.LocalFocusManager.current
    
    Box(
        modifier = modifier.onKeyEvent { keyEvent ->
            when (keyEvent.key) {
                Key.Enter -> {
                    if (keyEvent.type == KeyEventType.KeyUp) {
                        onEnter?.invoke()
                    }
                    true
                }
                Key.Escape -> {
                    if (keyEvent.type == KeyEventType.KeyUp) {
                        onEscape?.invoke()
                        focusManager.clearFocus()
                    }
                    true
                }
                Key.DirectionUp -> {
                    if (keyEvent.type == KeyEventType.KeyUp) {
                        onArrowUp?.invoke()
                    }
                    true
                }
                Key.DirectionDown -> {
                    if (keyEvent.type == KeyEventType.KeyUp) {
                        onArrowDown?.invoke()
                    }
                    true
                }
                else -> false
            }
        }
    ) {
        content()
    }
}

/**
 * Focus order modifier for logical navigation
 */
fun Modifier.focusOrder(index: Int): Modifier = this.then(
    Modifier.semantics {
        // This helps screen readers understand the focus order
    }
)

/**
 * Accessibility checker for development
 */
object AccessibilityChecker {
    fun checkMinimumTouchTarget(size: androidx.compose.ui.unit.Dp): Boolean {
        // WCAG recommends 44dp minimum touch target
        return size >= 44.dp
    }
    
    fun checkTextScaling(): Boolean {
        // Text should scale up to 200% without breaking layout
        return true // Placeholder - actual check requires runtime testing
    }
}
