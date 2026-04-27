@file:OptIn(
    androidx.compose.foundation.ExperimentalFoundationApi::class,
    androidx.compose.material3.ExperimentalMaterial3Api::class
)
package org.sada.messenger.ui.screens

import android.Manifest
import android.content.pm.PackageManager
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.Canvas
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import coil.compose.AsyncImage
import org.sada.messenger.data.entities.MessageEntity
import org.sada.messenger.ui.viewmodels.ChatViewModel
import org.sada.messenger.managers.MediaManager
import org.sada.messenger.ui.theme.*
import org.sada.messenger.ui.components.*
import org.sada.messenger.ui.utils.tr
import kotlin.random.Random

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(
    viewModel: ChatViewModel,
    chatName: String,
    onBackClick: () -> Unit,
    onCrisisReportClick: () -> Unit
) {
    val messages by viewModel.messages.collectAsState()
    val isVoiceRecording by viewModel.isVoiceRecording.collectAsState()
    val recordingDuration by viewModel.recordingDurationSeconds.collectAsState()
    val amplitude by viewModel.amplitude.collectAsState()
    val isSelectionMode by viewModel.isSelectionMode.collectAsState()
    val selectedIds by viewModel.selectedMessageIds.collectAsState()
    
    val listState = rememberLazyListState()
    var textState by remember { mutableStateOf("") }
    var showAttachmentMenu by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val density = LocalDensity.current
    val isImeOpen = WindowInsets.ime.getBottom(density) > 0
    var showClearChatConfirm by remember { mutableStateOf(false) }
    var showDeleteMessagesConfirm by remember { mutableStateOf(false) }
    var showBlockConfirm by remember { mutableStateOf(false) }
    var showDeleteChatConfirm by remember { mutableStateOf(false) }
    var showMenu by remember { mutableStateOf(false) }
    var showHelpSheet by remember { mutableStateOf(false) }

    LaunchedEffect(messages.size, isImeOpen) {
        if (isImeOpen && messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.lastIndex)
        }
    }

    val filePicker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri ->
        uri?.let {
            val mediaManager = MediaManager(context)
            val file = mediaManager.saveMediaToInternalStorage(it)
            if (file != null) {
                val mimeType = context.contentResolver.getType(it) ?: "application/octet-stream"
                viewModel.sendMediaMessage(file, mimeType)
            }
        }
    }

    val recordAudioPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) viewModel.startVoiceRecording()
    }

    Box(modifier = Modifier.fillMaxSize().background(LocalSadaPalette.current.background)) {
        Scaffold(
            topBar = {
                AnimatedContent(targetState = isSelectionMode, label = "TopBar") { selection ->
                    if (selection) {
                        TopAppBar(
                            title = { Text(tr("${selectedIds.size} رسائل محددة", "${selectedIds.size} messages selected")) },
                            navigationIcon = {
                                IconButton(onClick = { viewModel.exitSelectionMode() }) {
                                    Icon(Icons.Default.Close, contentDescription = "Close", tint = LocalSadaPalette.current.textPrimary)
                                }
                            },
                            actions = {
                                IconButton(onClick = { showDeleteMessagesConfirm = true }) {
                                    Icon(Icons.Default.Delete, contentDescription = "Delete", tint = ErrorRed)
                                }
                            },
                            colors = TopAppBarDefaults.topAppBarColors(
                                containerColor = LocalSadaPalette.current.background.copy(alpha = 0.9f),
                                titleContentColor = LocalSadaPalette.current.textPrimary,
                                navigationIconContentColor = LocalSadaPalette.current.textPrimary,
                                actionIconContentColor = LocalSadaPalette.current.textPrimary
                            )
                        )
                    } else {
                        TopAppBar(
                            title = {
                                Column {
                                    Text(chatName, fontWeight = FontWeight.Bold, color = LocalSadaPalette.current.textPrimary)
                                    Text(tr("تشفير طرف لطرف", "End-to-end encryption"), style = MaterialTheme.typography.labelSmall, color = LocalSadaPalette.current.surface.copy(alpha = 0.5f))
                                }
                            },
                            navigationIcon = {
                                IconButton(onClick = onBackClick) {
                                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = LocalSadaPalette.current.textPrimary)
                                }
                            },
                            actions = {
                                IconButton(onClick = { showHelpSheet = true }) {
                                    Icon(Icons.Default.HelpOutline, contentDescription = "Help", tint = LocalSadaPalette.current.textSecondary)
                                }
                                IconButton(onClick = { showMenu = true }) {
                                    Icon(Icons.Default.MoreVert, contentDescription = "More", tint = LocalSadaPalette.current.textSecondary)
                                }
                                DropdownMenu(
                                    expanded = showMenu,
                                    onDismissRequest = { showMenu = false },
                                    modifier = Modifier.background(LocalSadaPalette.current.surface)
                                ) {
                                    DropdownMenuItem(
                                        text = { Text(tr("مسح المحادثة", "Clear Chat"), color = LocalSadaPalette.current.textPrimary) },
                                        onClick = {
                                            showMenu = false
                                            showClearChatConfirm = true
                                        },
                                        leadingIcon = { Icon(Icons.Default.DeleteSweep, contentDescription = null, tint = LocalSadaPalette.current.textSecondary) }
                                    )
                                    DropdownMenuItem(
                                        text = { Text(tr("حظر المستخدم", "Block User"), color = ErrorRed) },
                                        onClick = {
                                            showMenu = false
                                            showBlockConfirm = true
                                        },
                                        leadingIcon = { Icon(Icons.Default.Block, contentDescription = null, tint = ErrorRed) }
                                    )
                                    DropdownMenuItem(
                                        text = { Text(tr("حذف المحادثة", "Delete Chat"), color = ErrorRed) },
                                        onClick = {
                                            showMenu = false
                                            showDeleteChatConfirm = true
                                        },
                                        leadingIcon = { Icon(Icons.Default.Delete, contentDescription = null, tint = ErrorRed) }
                                    )
                                }
                            },
                            colors = TopAppBarDefaults.topAppBarColors(
                                containerColor = LocalSadaPalette.current.background.copy(alpha = 0.9f),
                                titleContentColor = LocalSadaPalette.current.textPrimary,
                                navigationIconContentColor = LocalSadaPalette.current.textPrimary,
                                actionIconContentColor = LocalSadaPalette.current.textPrimary
                            )
                        )
                    }
                }
            },
            bottomBar = {
                val replyToMessage by viewModel.replyToMessage.collectAsState()
                val editingMessage by viewModel.editingMessage.collectAsState()
                Column {
                    editingMessage?.let { editMsg ->
                        ReplyBarGlass(
                            senderName = tr("تعديل رسالة", "Editing message"),
                            messagePreview = editMsg.content,
                            onCancel = { 
                                viewModel.cancelEditing()
                                textState = ""
                            }
                        )
                    }
                    if (editingMessage == null) {
                        replyToMessage?.let { replyMsg ->
                            ReplyBarGlass(
                                senderName = if (replyMsg.isFromMe) "أنت" else replyMsg.replyToSender ?: "Unknown",
                                messagePreview = replyMsg.content,
                                onCancel = { viewModel.clearReplyTo() }
                            )
                        }
                    }
                    ChatInputGlass(
                        text = textState,
                        onTextChange = { textState = it },
                        onSend = {
                            if (textState.isNotBlank()) {
                                editingMessage?.let { editMsg ->
                                    viewModel.editMessage(editMsg.id, textState)
                                    viewModel.cancelEditing()
                                } ?: viewModel.sendMessage(textState)
                                textState = ""
                            }
                        },
                        onAttach = { showAttachmentMenu = true },
                        isVoiceRecording = isVoiceRecording,
                        recordingDuration = recordingDuration,
                        amplitude = amplitude,
                        onVoiceRecordToggle = {
                            if (!isVoiceRecording) {
                                if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
                                    viewModel.startVoiceRecording()
                                } else {
                                    recordAudioPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                                }
                            } else {
                                viewModel.stopVoiceRecordingAndSend()
                            }
                        }
                    )
                }
            },
            containerColor = LocalSadaPalette.current.background
        ) { padding ->
            LazyColumn(
                state = listState,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(messages, key = { it.id }) { message ->
                    GlassMessageBubble(
                        message = message,
                        isSelected = selectedIds.contains(message.id),
                        onClick = {
                            if (isSelectionMode) {
                                viewModel.toggleMessageSelection(message.id)
                            }
                        },
                        onLongClick = {
                            viewModel.toggleMessageSelection(message.id)
                        },
                        onReply = { viewModel.setReplyTo(message) },
                        onEdit = { 
                            if (message.isFromMe && message.type == "text") {
                                viewModel.startEditing(message)
                                textState = message.content
                            }
                        },
                        onForward = { viewModel.setForwardMessage(message) }
                    )
                }
            }
        }

        if (showClearChatConfirm) {
            GlassAlertDialog(
                onDismissRequest = { showClearChatConfirm = false },
                title = tr("مسح المحادثة", "Clear Chat"),
                text = tr("هل أنت متأكد من مسح جميع الرسائل؟", "Are you sure you want to clear all messages?"),
                confirmButton = {
                    GlassButton(
                        onClick = {
                            viewModel.clearChatContent()
                            showClearChatConfirm = false
                        }
                    ) {
                        Text(tr("مسح", "Clear"))
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showClearChatConfirm = false }) {
                        Text(tr("إلغاء", "Cancel"))
                    }
                }
            )
        }

        if (showDeleteMessagesConfirm) {
            GlassAlertDialog(
                onDismissRequest = { showDeleteMessagesConfirm = false },
                title = tr("حذف الرسائل", "Delete Messages"),
                text = tr("هل أنت متأكد من حذف ${selectedIds.size} رسائل محددة؟", "Are you sure you want to delete ${selectedIds.size} selected messages?"),
                confirmButton = {
                    GlassButton(
                        onClick = {
                            viewModel.deleteSelectedMessages()
                            showDeleteMessagesConfirm = false
                        }
                    ) {
                        Text(tr("حذف", "Delete"))
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showDeleteMessagesConfirm = false }) {
                        Text(tr("إلغاء", "Cancel"))
                    }
                }
            )
        }

        if (showBlockConfirm) {
            GlassAlertDialog(
                onDismissRequest = { showBlockConfirm = false },
                title = tr("حظر المستخدم", "Block User"),
                text = tr("هل أنت متأكد من حظر هذا المستخدم؟ لن تتمكن من استلام رسائل منه.", "Are you sure you want to block this user? You won't receive messages from them."),
                confirmButton = {
                    GlassButton(
                        onClick = {
                            viewModel.blockContact()
                            showBlockConfirm = false
                            onBackClick()
                        }
                    ) {
                        Text(tr("حظر", "Block"))
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showBlockConfirm = false }) {
                        Text(tr("إلغاء", "Cancel"))
                    }
                }
            )
        }

        if (showDeleteChatConfirm) {
            GlassAlertDialog(
                onDismissRequest = { showDeleteChatConfirm = false },
                title = tr("حذف المحادثة", "Delete Chat"),
                text = tr("هل أنت متأكد من حذف هذه المحادثة وجميع رسائلها؟", "Are you sure you want to delete this chat and all its messages?"),
                confirmButton = {
                    GlassButton(
                        onClick = {
                            viewModel.deleteChat()
                            showDeleteChatConfirm = false
                            onBackClick()
                        }
                    ) {
                        Text(tr("حذف", "Delete"))
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showDeleteChatConfirm = false }) {
                        Text(tr("إلغاء", "Cancel"))
                    }
                }
            )
        }

        if (showHelpSheet) {
            QuickHelpBottomSheet(onDismiss = { showHelpSheet = false })
        }

        if (showAttachmentMenu) {
            AttachmentBottomSheetGlass(
                onDismiss = { showAttachmentMenu = false },
                onImageSelect = { filePicker.launch("image/*") },
                onFileSelect = { filePicker.launch("*/*") },
                onReportClick = onCrisisReportClick
            )
        }
    }
}

@Composable
fun GlassMessageBubble(
    message: MessageEntity,
    isSelected: Boolean,
    onClick: () -> Unit,
    onLongClick: () -> Unit,
    onReply: () -> Unit,
    onEdit: () -> Unit,
    onForward: () -> Unit
) {
    val isFromMe = message.isFromMe
    val bubbleColor = if (isFromMe) {
        LocalSadaPalette.current.surface.copy(alpha = 0.2f)
    } else {
        LocalSadaPalette.current.surfaceVariant.copy(alpha = 0.5f)
    }
    
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 2.dp)
            .background(if (isSelected) LocalSadaPalette.current.surface.copy(alpha = 0.15f) else Color.Transparent),
        contentAlignment = if (isFromMe) Alignment.CenterEnd else Alignment.CenterStart
    ) {
        GlassSurface(
            modifier = Modifier
                .widthIn(max = 280.dp)
                .combinedClickable(
                    onClick = onClick,
                    onLongClick = onLongClick
                ),
            cornerRadius = 16.dp
        ) {
            Column(
                modifier = Modifier.padding(12.dp)
            ) {
                if (message.replyToId != null && message.replyToContent != null) {
                    ReplyBubbleGlass(
                        senderName = message.replyToSender ?: tr("مستخدم", "User"),
                        content = message.replyToContent,
                        isCurrentUser = message.replyToId == message.id
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                }
                
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (message.type == "voice" || message.isVoice) {
                        VoiceMessageBubbleContent(message)
                    } else {
                        Text(
                            text = message.content,
                            color = LocalSadaPalette.current.textPrimary,
                            fontSize = 15.sp
                        )
                    }
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(
                        Icons.Default.Lock,
                        contentDescription = "E2EE",
                        tint = LocalSadaPalette.current.textSecondary.copy(alpha = 0.3f),
                        modifier = Modifier.size(10.dp)
                    )
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = formatTimestamp(message.timestamp.time),
                        color = LocalSadaPalette.current.textSecondary.copy(alpha = 0.7f),
                        fontSize = 11.sp
                    )
                    if (isFromMe) {
                        Spacer(modifier = Modifier.width(4.dp))
                        Icon(
                            imageVector = when (message.status) {
                                "read" -> Icons.Default.DoneAll
                                "delivered" -> Icons.Default.Done
                                else -> Icons.Default.Schedule
                            },
                            contentDescription = null,
                            modifier = Modifier.size(14.dp),
                            tint = when (message.status) {
                                "read" -> LocalSadaPalette.current.successGreen
                                else -> LocalSadaPalette.current.textSecondary.copy(alpha = 0.5f)
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ReplyBarGlass(
    senderName: String,
    messagePreview: String,
    onCancel: () -> Unit
) {
    val backgroundColor = if (senderName == "أنت" || senderName == "You") {
        LocalSadaPalette.current.surface.copy(alpha = 0.15f)
    } else {
        LocalSadaPalette.current.surfaceVariant.copy(alpha = 0.3f)
    }
    
    val indicatorColor = if (senderName == "أنت" || senderName == "You") {
        LocalSadaPalette.current.successGreen
    } else {
        LocalSadaPalette.current.textSecondary
    }
    
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(backgroundColor)
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .width(4.dp)
                .height(36.dp)
                .background(indicatorColor, RoundedCornerShape(2.dp))
        )
        
        Spacer(modifier = Modifier.width(12.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = senderName,
                style = MaterialTheme.typography.labelMedium,
                color = indicatorColor,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = messagePreview.take(60) + if (messagePreview.length > 60) "..." else "",
                style = MaterialTheme.typography.bodySmall,
                color = LocalSadaPalette.current.textPrimary.copy(alpha = 0.7f),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
        
        IconButton(onClick = onCancel) {
            Icon(
                imageVector = Icons.Default.Close,
                contentDescription = "Cancel reply",
                tint = LocalSadaPalette.current.textSecondary
            )
        }
    }
}

@Composable
fun ReplyBubbleGlass(
    senderName: String,
    content: String,
    isCurrentUser: Boolean
) {
    val indicatorColor = if (senderName == "أنت" || senderName == "You") {
        NeonTeal
    } else {
        LocalSadaPalette.current.textSecondary
    }
    
    val backgroundColor = if (isCurrentUser) {
        NeonTeal.copy(alpha = 0.1f)
    } else {
        LocalSadaPalette.current.surfaceVariant.copy(alpha = 0.3f)
    }
    
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(backgroundColor, RoundedCornerShape(8.dp))
            .padding(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .width(3.dp)
                .height(32.dp)
                .background(indicatorColor, RoundedCornerShape(2.dp))
        )
        
        Spacer(modifier = Modifier.width(8.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = senderName,
                style = MaterialTheme.typography.labelSmall,
                color = indicatorColor,
                fontWeight = FontWeight.Bold,
                maxLines = 1
            )
            Text(
                text = content.take(50) + if (content.length > 50) "..." else "",
                style = MaterialTheme.typography.bodySmall,
                color = LocalSadaPalette.current.textPrimary.copy(alpha = 0.8f),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@Composable
fun ChatInputGlass(
    text: String,
    onTextChange: (String) -> Unit,
    onSend: () -> Unit,
    onAttach: () -> Unit,
    isVoiceRecording: Boolean,
    recordingDuration: Int,
    amplitude: Float,
    onVoiceRecordToggle: () -> Unit
) {
    GlassSurface(
        modifier = Modifier.fillMaxWidth(),
        cornerRadius = 24.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            IconButton(onClick = onAttach) {
                Icon(
                    imageVector = Icons.Default.AttachFile,
                    contentDescription = "Attach",
                    tint = LocalSadaPalette.current.textSecondary
                )
            }
            
            GlassInputField(
                value = text,
                onValueChange = onTextChange,
                placeholder = tr("اكتب رسالة...", "Type a message..."),
                modifier = Modifier.weight(1f)
            )
            
            if (text.isBlank()) {
                IconButton(onClick = onVoiceRecordToggle) {
                    Icon(
                        imageVector = if (isVoiceRecording) Icons.Default.Stop else Icons.Default.Mic,
                        contentDescription = if (isVoiceRecording) "Stop recording" else "Record voice",
                        tint = if (isVoiceRecording) ErrorRed else SadaPrimary
                    )
                }
            } else {
                IconButton(onClick = onSend) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.Send,
                        contentDescription = "Send",
                        tint = NeonTeal
                    )
                }
            }
        }
    }
}

@Composable
fun AttachmentBottomSheetGlass(
    onDismiss: () -> Unit,
    onImageSelect: () -> Unit,
    onFileSelect: () -> Unit,
    onReportClick: () -> Unit
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = LocalSadaPalette.current.surface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                tr("إرفاق", "Attachments"),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = LocalSadaPalette.current.textPrimary
            )
            Spacer(modifier = Modifier.height(24.dp))
            
            Text(
                text = tr("لا يوجد خيارات إرفاق", "No attachment options"),
                color = LocalSadaPalette.current.textSecondary,
                style = MaterialTheme.typography.bodyMedium
            )
        }
    }
}

@Composable
fun VoiceMessageBubbleContent(message: MessageEntity) {
    val duration = message.voiceDurationMs?.let { it / 1000 } ?: 0
    Row(verticalAlignment = Alignment.CenterVertically) {
        IconButton(onClick = { /* Play logic */ }, modifier = Modifier.size(32.dp)) {
            Icon(Icons.Default.PlayArrow, contentDescription = "Play", tint = NeonTeal)
        }
        Spacer(modifier = Modifier.width(8.dp))
        VoiceWaveform(
            modifier = Modifier.width(120.dp).height(24.dp),
            isAnimating = false
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = String.format("%02d:%02d", duration / 60, duration % 60),
            color = LocalSadaPalette.current.textSecondary,
            fontSize = 11.sp
        )
    }
}

@Composable
fun VoiceWaveform(modifier: Modifier, isAnimating: Boolean) {
    Canvas(modifier = modifier) {
        val count = 20
        val gap = 4.dp.toPx()
        val barWidth = (size.width - (count - 1) * gap) / count
        
        for (i in 0 until count) {
            val h = if (isAnimating) {
                (0.2f + Random.nextFloat() * 0.8f) * size.height
            } else {
                // Static wave simulation
                val sinVal = kotlin.math.sin(i.toFloat() * 0.5f).coerceIn(0f, 1f)
                (0.3f + 0.7f * sinVal) * size.height
            }
            
            drawRoundRect(
                color = NeonTeal.copy(alpha = if (isAnimating) 1f else 0.5f),
                topLeft = Offset(i * (barWidth + gap), (size.height - h) / 2),
                size = androidx.compose.ui.geometry.Size(barWidth, h),
                cornerRadius = androidx.compose.ui.geometry.CornerRadius(barWidth / 2)
            )
        }
    }
}

private fun formatTimestamp(timestamp: Long): String {
    val date = java.util.Date(timestamp)
    val format = java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault())
    return format.format(date)
}
