package org.sada.messenger.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.sada.messenger.growth.UserStatusStore
import org.sada.messenger.ui.components.GlassButton
import org.sada.messenger.ui.components.GlassCard
import org.sada.messenger.ui.components.GlassSurface
// MeshBackground is in this package (OnboardingScreen.kt)
import org.sada.messenger.ui.theme.*
import org.sada.messenger.ui.utils.tr

/**
 * Status Screen - Set and view user status
 * Integrated with Glass-morphism Design System
 */
@Composable
fun StatusScreen(
    statusStore: UserStatusStore,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val statusState by remember { mutableStateOf(statusStore.load()) }
    var statusText by remember { mutableStateOf(statusState.statusText) }
    var selectedDuration by remember { mutableStateOf(24) } // hours
    
    Box(modifier = modifier.fillMaxSize().background(LocalSadaPalette.current.background)) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                IconButton(onClick = onBack) {
                    Icon(
                        imageVector = Icons.Default.ArrowBack,
                        contentDescription = tr("رجوع", "Back"),
                        tint = LocalSadaPalette.current.textPrimary
                    )
                }
                
                Text(
                    text = tr("حالتي", "My Status"),
                    style = MaterialTheme.typography.titleLarge,
                    color = LocalSadaPalette.current.textPrimary
                )
                
                IconButton(
                    onClick = {
                        // Clear status
                        statusStore.clear()
                        statusText = ""
                    }
                ) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = tr("حذف", "Delete"),
                        tint = LocalSadaPalette.current.errorRed
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Current Status Display
            if (statusState.isActive()) {
                GlassCard {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(48.dp)
                                .background(LocalSadaPalette.current.successGreen.copy(alpha = 0.2f), CircleShape)
                                .padding(8.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.CheckCircle,
                                contentDescription = null,
                                tint = LocalSadaPalette.current.successGreen
                            )
                        }
                        
                        Column {
                            Text(
                                text = tr("الحالة الحالية", "Current Status"),
                                style = MaterialTheme.typography.labelMedium,
                                color = LocalSadaPalette.current.textSecondary
                            )
                            Text(
                                text = statusState.statusText,
                                style = MaterialTheme.typography.bodyLarge,
                                color = LocalSadaPalette.current.textPrimary
                            )
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
            }
            
            // Status Input
            GlassCard {
                Column {
                    Text(
                        text = tr("حالة جديدة", "New Status"),
                        style = MaterialTheme.typography.labelMedium,
                        color = LocalSadaPalette.current.textSecondary
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    BasicTextField(
                        value = statusText,
                        onValueChange = { 
                            if (it.length <= 100) statusText = it 
                        },
                        modifier = Modifier.fillMaxWidth(),
                        textStyle = TextStyle(
                            color = LocalSadaPalette.current.textPrimary,
                            fontSize = 16.sp
                        ),
                        decorationBox = { innerTextField ->
                            GlassSurface(
                                modifier = Modifier.fillMaxWidth(),
                                cornerRadius = 12.dp
                            ) {
                                Box(
                                    modifier = Modifier
                                        .padding(16.dp)
                                        .fillMaxWidth()
                                ) {
                                    if (statusText.isEmpty()) {
                                        Text(
                                            text = tr("ما الذي يدور في ذهنك؟", "What's on your mind?"),
                                            color = LocalSadaPalette.current.textSecondary
                                        )
                                    }
                                    innerTextField()
                                }
                            }
                        }
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Text(
                        text = "${statusText.length}/100",
                        style = MaterialTheme.typography.labelSmall,
                        color = if (statusText.length >= 90) LocalSadaPalette.current.errorRed else LocalSadaPalette.current.textSecondary,
                        modifier = Modifier.align(Alignment.End)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Duration Selection
            GlassCard {
                Column {
                    Text(
                        text = tr("مدة الحالة", "Status Duration"),
                        style = MaterialTheme.typography.labelMedium,
                        color = LocalSadaPalette.current.textSecondary
                    )
                    
                    Spacer(modifier = Modifier.height(12.dp))
                    
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        listOf(1, 4, 24, 72).forEach { hours ->
                            val isSelected = selectedDuration == hours
                            val label = when (hours) {
                                1 -> tr("1 ساعة", "1 hour")
                                4 -> tr("4 ساعات", "4 hours")
                                24 -> tr("24 ساعة", "24 hours")
                                72 -> tr("3 أيام", "3 days")
                                else -> "$hours hours"
                            }
                            
                            Surface(
                                onClick = { selectedDuration = hours },
                                shape = RoundedCornerShape(20.dp),
                                color = if (isSelected) SadaPrimary.copy(alpha = 0.3f) 
                                        else LocalSadaPalette.current.surface.copy(alpha = 0.5f),
                                border = androidx.compose.foundation.BorderStroke(
                                    width = 0.5.dp,
                                    color = if (isSelected) SadaPrimary else LocalSadaPalette.current.textSecondary.copy(alpha = 0.3f)
                                )
                            ) {
                                Text(
                                    text = label,
                                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                                    color = if (isSelected) SadaPrimary else LocalSadaPalette.current.textPrimary,
                                    style = MaterialTheme.typography.labelMedium
                                )
                            }
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            // Save Button
            GlassButton(
                onClick = {
                    if (statusText.isNotBlank()) {
                        val expiresAt = System.currentTimeMillis() + (selectedDuration * 60 * 60 * 1000)
                        statusStore.save(statusText, expiresAt)
                        onBack()
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = statusText.isNotBlank()
            ) {
                Icon(
                    imageVector = Icons.Default.Save,
                    contentDescription = null,
                    modifier = Modifier.padding(end = 8.dp)
                )
                Text(tr("حفظ الحالة", "Save Status"))
            }
        }
    }
}
