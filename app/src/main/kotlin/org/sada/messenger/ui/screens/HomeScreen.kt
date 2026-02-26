package org.sada.messenger.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.res.stringResource
import org.sada.messenger.R
import org.sada.messenger.data.entities.ChatEntity
import org.sada.messenger.ui.viewmodels.HomeViewModel
import org.sada.messenger.ui.theme.NeonTeal
import org.sada.messenger.ui.theme.CyberBlue

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    viewModel: HomeViewModel,
    onChatClick: (String) -> Unit,
    onSettingsClick: () -> Unit,
    onCreateGroupClick: () -> Unit,
    onDiagnosticsClick: () -> Unit
) {
    val chats by viewModel.chats.collectAsState()
    var showSosConfirm by remember { mutableStateOf(false) }
    var isSpeedDialOpen by remember { mutableStateOf(false) }
    
    // Mock data for parity (would be connected to MeshEngine in production)
    val relayCount = 0 

    Box(modifier = Modifier.fillMaxSize()) {
        // Shared Mesh Background
        MeshBackground()

        Scaffold(
            topBar = {
                LargeTopAppBar(
                    title = { 
                        Column {
                            Text(
                                "صدى / Sada", 
                                fontWeight = FontWeight.ExtraBold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Text(
                                stringResource(R.string.mesh_status_active),
                                style = MaterialTheme.typography.labelSmall,
                                color = NeonTeal.copy(alpha = 0.7f)
                            )
                        }
                    },
                    actions = {
                        IconButton(onClick = onDiagnosticsClick) {
                            Icon(Icons.Default.CellTower, contentDescription = "Diagnostics", tint = NeonTeal)
                        }
                        IconButton(onClick = onSettingsClick) {
                            Icon(Icons.Default.Settings, contentDescription = "Settings")
                        }
                        IconButton(onClick = { showSosConfirm = true }) {
                            Icon(Icons.Default.Warning, contentDescription = "SOS", tint = Color.Red)
                        }
                    },
                    colors = TopAppBarDefaults.largeTopAppBarColors(
                        containerColor = Color.Transparent,
                        scrolledContainerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.8f)
                    ),
                    modifier = Modifier.blur(if (showSosConfirm) 10.dp else 0.dp)
                )
            },
            floatingActionButton = {
                SpeedDialFAB(
                    isOpen = isSpeedDialOpen,
                    onToggle = { isSpeedDialOpen = !isSpeedDialOpen },
                    onAction = { action ->
                        isSpeedDialOpen = false
                        when (action) {
                            "scan" -> { /* Navigate to Scan */ }
                            "notes" -> { /* Navigate to Notes */ }
                            "group" -> onCreateGroupClick()
                        }
                    }
                )
            },
            containerColor = Color.Transparent
        ) { padding ->
            Column(modifier = Modifier.padding(padding)) {
                // Mesh Participation Banner
                RelayParticipationBanner(relayCount = relayCount)

                if (chats.isEmpty()) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(32.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "لا توجد محادثات نشطة حالياً.\nابحث عن عقد قريبة للبدء.",
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
                            textAlign = TextAlign.Center,
                            lineHeight = 26.sp
                        )
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(chats) { chat ->
                            GlassChatTile(chat = chat, onClick = { onChatClick(chat.id) })
                        }
                    }
                }
            }
        }

        if (showSosConfirm) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.6f))
                    .clickable { showSosConfirm = false }
            )

            AlertDialog(
                onDismissRequest = { showSosConfirm = false },
                title = { Text("بث طوارئ / Emergency SOS") },
                text = { Text("هل أنت متأكد من رغبتك في إرسال نداء استغاثة لجميع الأجهزة القريبة؟ سيتم تضمين موقعك الحالي.") },
                confirmButton = {
                    Button(
                        onClick = {
                            viewModel.triggerSos()
                            showSosConfirm = false
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = Color.Red),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text("إرسال نداء الاستغاثة", fontWeight = FontWeight.Bold)
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showSosConfirm = false }) {
                        Text("إلغاء", color = Color.White.copy(alpha = 0.6f))
                    }
                },
                containerColor = Color(0xFF1A1A1A),
                shape = RoundedCornerShape(24.dp)
            )
        }
    }
}

@Composable
fun SpeedDialFAB(
    isOpen: Boolean,
    onToggle: () -> Unit,
    onAction: (String) -> Unit
) {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    
    Column(horizontalAlignment = Alignment.End) {
        AnimatedVisibility(
            visible = isOpen,
            enter = expandVertically() + fadeIn(),
            exit = shrinkVertically() + fadeOut()
        ) {
            Column(
                horizontalAlignment = Alignment.End,
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.padding(bottom = 16.dp)
            ) {
                SpeedDialItem(
                    label = stringResource(R.string.fab_scan_qr),
                    icon = Icons.Default.QrCodeScanner,
                    color = MaterialTheme.colorScheme.tertiary,
                    onClick = { onAction("scan") }
                )
                SpeedDialItem(
                    label = stringResource(R.string.fab_safe_notes),
                    icon = Icons.Default.Notes,
                    color = MaterialTheme.colorScheme.secondary,
                    onClick = { onAction("notes") }
                )
                SpeedDialItem(
                    label = stringResource(R.string.fab_create_group),
                    icon = Icons.Default.GroupAdd,
                    color = CyberBlue,
                    onClick = { onAction("group") }
                )
            }
        }

        Box(contentAlignment = Alignment.Center) {
            // Triple Pulse Animation (Matching Flutter Parity)
            val pulses = listOf(0f, 0.3f, 0.6f)
            pulses.forEach { delay ->
                val progress by infiniteTransition.animateFloat(
                    initialValue = 0f,
                    targetValue = 1f,
                    animationSpec = infiniteRepeatable(
                        animation = tween(2000, easing = LinearEasing),
                        repeatMode = RepeatMode.Restart,
                        initialStartOffset = StartOffset((delay * 2000).toInt())
                    ),
                    label = "pulse_$delay"
                )
                
                Box(
                    modifier = Modifier
                        .size(64.dp + (progress * 48).dp)
                        .graphicsLayer {
                            alpha = (1f - progress) * 0.4f
                            scaleX = 1f + (progress * 0.5f)
                            scaleY = 1f + (progress * 0.5f)
                        }
                        .border(2.dp, NeonTeal.copy(alpha = (1f - progress) * 0.3f), CircleShape)
                        .blur(4.dp)
                )
            }

            FloatingActionButton(
                onClick = onToggle,
                containerColor = NeonTeal,
                contentColor = Color.Black,
                shape = CircleShape,
                modifier = Modifier
                    .size(64.dp)
                    .shadow(12.dp, CircleShape, spotColor = NeonTeal)
            ) {
                Icon(
                    if (isOpen) Icons.Default.Close else Icons.Default.Radar, 
                    contentDescription = null, 
                    modifier = Modifier.size(32.dp)
                )
            }
        }
    }
}

@Composable
fun SpeedDialItem(
    label: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    color: Color,
    onClick: () -> Unit
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.clickable(onClick = onClick)
    ) {
        Surface(
            shape = RoundedCornerShape(12.dp),
            color = Color.Black.copy(alpha = 0.8f),
            border = androidx.compose.foundation.BorderStroke(1.dp, color.copy(alpha = 0.3f))
        ) {
            Text(
                text = label,
                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                style = MaterialTheme.typography.labelMedium,
                color = Color.White
            )
        }
        Spacer(modifier = Modifier.width(12.dp))
        FloatingActionButton(
            onClick = onClick,
            containerColor = color,
            contentColor = Color.Black,
            shape = CircleShape,
            modifier = Modifier.size(48.dp)
        ) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(24.dp))
        }
    }
}

@Composable
fun RelayParticipationBanner(relayCount: Int) {
    val text = if (relayCount > 0) 
        stringResource(R.string.mesh_relaying_packets, relayCount)
    else 
        stringResource(R.string.mesh_no_packets)

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        shape = RoundedCornerShape(16.dp),
        color = NeonTeal.copy(alpha = 0.05f),
        border = androidx.compose.foundation.BorderStroke(1.dp, NeonTeal.copy(alpha = 0.2f))
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(Icons.Default.LocalShipping, contentDescription = null, tint = NeonTeal, modifier = Modifier.size(20.dp))
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = text,
                style = MaterialTheme.typography.bodySmall,
                color = Color.White,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun GlassChatTile(chat: ChatEntity, onClick: () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .clickable(onClick = onClick),
        color = Color.White.copy(alpha = 0.05f),
        border = androidx.compose.foundation.BorderStroke(
            1.dp, 
            Brush.linearGradient(listOf(Color.White.copy(alpha = 0.1f), Color.Transparent))
        )
    ) {
        ListItem(
            headlineContent = { 
                Text(
                    chat.name, 
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                ) 
            },
            supportingContent = { 
                Text(
                    chat.lastMessage ?: "لا توجد رسائل بعد", 
                    maxLines = 1,
                    color = Color.White.copy(alpha = 0.6f)
                ) 
            },
            leadingContent = {
                Surface(
                    shape = CircleShape,
                    color = (if (chat.isGroup) CyberBlue else NeonTeal).copy(alpha = 0.1f),
                    modifier = Modifier.size(52.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, (if (chat.isGroup) CyberBlue else NeonTeal).copy(alpha = 0.3f))
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            if (chat.isGroup) Icons.Default.Groups else Icons.Default.Person,
                            contentDescription = null,
                            tint = if (chat.isGroup) CyberBlue else NeonTeal,
                            modifier = Modifier.size(28.dp)
                        )
                    }
                }
            },
            trailingContent = {
                Column(horizontalAlignment = Alignment.End) {
                    if (chat.unreadCount > 0) {
                        Badge(containerColor = NeonTeal) { 
                            Text(chat.unreadCount.toString(), color = Color.Black, fontWeight = FontWeight.Bold) 
                        }
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Icon(
                        Icons.Default.ChevronRight, 
                        contentDescription = null, 
                        tint = Color.White.copy(alpha = 0.2f),
                        modifier = Modifier.size(16.dp)
                    )
                }
            },
            colors = ListItemDefaults.colors(containerColor = Color.Transparent)
        )
    }
}
