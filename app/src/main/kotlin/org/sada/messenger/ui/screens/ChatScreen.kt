package org.sada.messenger.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import coil.compose.AsyncImage
import org.sada.messenger.data.entities.MessageEntity
import org.sada.messenger.ui.viewmodels.ChatViewModel
import org.sada.messenger.managers.MediaManager
import org.sada.messenger.ui.theme.NeonTeal
import org.sada.messenger.ui.theme.CyberBlue
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(
    viewModel: ChatViewModel,
    chatName: String,
    onBackClick: () -> Unit,
    onCrisisReportClick: () -> Unit
) {
    val messages by viewModel.messages.collectAsState()
    var textState by remember { mutableStateOf("") }
    var showAttachmentMenu by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val mediaManager = remember { MediaManager(context) }

    val filePicker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri ->
        uri?.let {
            val file = mediaManager.saveMediaToInternalStorage(it)
            if (file != null) {
                val mimeType = context.contentResolver.getType(it) ?: "application/octet-stream"
                viewModel.sendMediaMessage(file, mimeType)
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        MeshBackground()

        Scaffold(
            topBar = {
                TopAppBar(
                    title = { 
                        Column {
                            Text(chatName, fontWeight = FontWeight.Bold)
                            Text("تشفير طرف لطرف / E2EE", style = MaterialTheme.typography.labelSmall, color = NeonTeal.copy(alpha = 0.5f))
                        }
                    },
                    navigationIcon = {
                        IconButton(onClick = onBackClick) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = Color.Transparent,
                        scrolledContainerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
                    )
                )
            },
            bottomBar = {
                ChatInput(
                    text = textState,
                    onTextChange = { textState = it },
                    onSend = {
                        if (textState.isNotBlank()) {
                            viewModel.sendMessage(textState)
                            textState = ""
                        }
                    },
                    onAttach = { showAttachmentMenu = true }
                )
            },
            containerColor = Color.Transparent
        ) { padding ->
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(horizontal = 16.dp),
                reverseLayout = true,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(messages.reversed(), key = { it.id }) { message ->
                    GlassMessageBubble(message = message)
                }
                item { Spacer(modifier = Modifier.height(16.dp)) }
            }
        }

        if (showAttachmentMenu) {
            ModalBottomSheet(
                onDismissRequest = { showAttachmentMenu = false },
                containerColor = Color(0xFF1A1A1A),
                shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp)
                        .navigationBarsPadding()
                ) {
                    Text(
                        "إرفاق / Attachments", 
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        AttachmentItem(
                            icon = Icons.Default.Image,
                            label = "Photo",
                            color = NeonTeal,
                            onClick = {
                                showAttachmentMenu = false
                                filePicker.launch("image/*")
                            }
                        )
                        AttachmentItem(
                            icon = Icons.Default.AddAlert,
                            label = "Report",
                            color = Color.Red,
                            onClick = {
                                showAttachmentMenu = false
                                onCrisisReportClick()
                            }
                        )
                    }
                    Spacer(modifier = Modifier.height(40.dp))
                }
            }
        }
    }
}

@Composable
fun GlassMessageBubble(message: MessageEntity) {
    val alignment = if (message.isFromMe) Alignment.CenterEnd else Alignment.CenterStart
    val bubbleColor = if (message.isFromMe) 
        NeonTeal.copy(alpha = 0.15f) 
    else 
        Color.White.copy(alpha = 0.05f)
    
    val borderColor = if (message.isFromMe) NeonTeal.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.1f)

    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = alignment) {
        Surface(
            color = bubbleColor,
            shape = RoundedCornerShape(
                topStart = 20.dp,
                topEnd = 20.dp,
                bottomStart = if (message.isFromMe) 20.dp else 4.dp,
                bottomEnd = if (message.isFromMe) 4.dp else 20.dp
            ),
            border = androidx.compose.foundation.BorderStroke(1.dp, borderColor),
            modifier = Modifier.widthIn(max = 300.dp)
        ) {
            Column(modifier = Modifier.padding(12.dp)) {
                if (message.attachmentPath != null && message.attachmentType?.startsWith("image") == true) {
                    AsyncImage(
                        model = message.attachmentPath,
                        contentDescription = null,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .padding(bottom = 8.dp)
                    )
                }
                Text(text = message.content, color = Color.White, fontSize = 16.sp)
                
                Row(
                    modifier = Modifier.align(Alignment.End),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (message.isRelayed) {
                        Icon(
                            Icons.Default.Hub, 
                            contentDescription = null, 
                            modifier = Modifier.size(10.dp),
                            tint = NeonTeal.copy(alpha = 0.5f)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                    }
                    Text(
                        text = java.text.SimpleDateFormat("HH:mm", Locale.getDefault()).format(message.timestamp),
                        style = MaterialTheme.typography.labelSmall,
                        color = Color.White.copy(alpha = 0.4f)
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatInput(
    text: String,
    onTextChange: (String) -> Unit,
    onSend: () -> Unit,
    onAttach: () -> Unit
) {
    Surface(
        color = Color(0xFF1A1A1A).copy(alpha = 0.9f),
        modifier = Modifier
            .fillMaxWidth()
            .blur(20.dp) // Subtle blur for the input area background
    ) {
        Row(
            modifier = Modifier
                .padding(horizontal = 12.dp, vertical = 8.dp)
                .fillMaxWidth()
                .navigationBarsPadding()
                .imePadding(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(
                onClick = onAttach,
                modifier = Modifier
                    .size(44.dp)
                    .background(Color.White.copy(alpha = 0.05f), CircleShape)
            ) {
                Icon(Icons.Default.Add, contentDescription = "Attach", tint = NeonTeal)
            }
            
            Spacer(modifier = Modifier.width(12.dp))

            TextField(
                value = text,
                onValueChange = onTextChange,
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(24.dp)),
                placeholder = { Text("رسالة مشفرة / Secure Msg...", color = Color.White.copy(alpha = 0.3f)) },
                colors = TextFieldDefaults.textFieldColors(
                    containerColor = Color.White.copy(alpha = 0.05f),
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent,
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White
                ),
                maxLines = 4
            )
            
            Spacer(modifier = Modifier.width(12.dp))

            IconButton(
                onClick = onSend,
                enabled = text.isNotBlank(),
                modifier = Modifier
                    .size(44.dp)
                    .background(if (text.isNotBlank()) NeonTeal else Color.White.copy(alpha = 0.05f), CircleShape)
            ) {
                Icon(
                    Icons.AutoMirrored.Filled.Send,
                    contentDescription = "Send",
                    tint = if (text.isNotBlank()) Color.Black else Color.White.copy(alpha = 0.2f),
                    modifier = Modifier.size(24.dp)
                )
            }
        }
    }
}

@Composable
fun AttachmentItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    color: Color,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.clickable(onClick = onClick).padding(8.dp)
    ) {
        Surface(
            shape = CircleShape,
            color = color.copy(alpha = 0.1f),
            border = androidx.compose.foundation.BorderStroke(1.dp, color.copy(alpha = 0.3f)),
            modifier = Modifier.size(64.dp)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = label, tint = color, modifier = Modifier.size(28.dp))
            }
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(label, style = MaterialTheme.typography.labelMedium, color = Color.White)
    }
}
