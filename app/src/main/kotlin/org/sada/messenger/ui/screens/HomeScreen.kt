package org.sada.messenger.ui.screens

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
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
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.res.stringResource
import kotlinx.coroutines.delay
import org.sada.messenger.ui.utils.tr
import org.sada.messenger.R
import org.sada.messenger.data.entities.ChatEntity
import org.sada.messenger.ui.viewmodels.HomeViewModel
import org.sada.messenger.ui.theme.*
import org.sada.messenger.ui.components.*
import org.sada.messenger.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    viewModel: HomeViewModel,
    onChatClick: (String) -> Unit,
    onDeleteChat: (String) -> Unit,
    onSettingsClick: () -> Unit,
    onCreateGroupClick: () -> Unit,
    onDiagnosticsClick: () -> Unit,
    onRequestPermissions: () -> Unit
) {
    val context = LocalContext.current
    val chats by viewModel.chats.collectAsState()
    val relayCount by viewModel.relayQueueCount.collectAsState()
    val outgoingUndeliveredCount by viewModel.outgoingUndeliveredCount.collectAsState()
    val connectedPeersCount by viewModel.connectedPeersCount.collectAsState()
    val networkConnected by viewModel.networkConnected.collectAsState()
    var pendingDeleteChat by remember { mutableStateOf<ChatEntity?>(null) }
    var showSosConfirm by remember { mutableStateOf(false) }
    var showBatteryDialog by remember { mutableStateOf(false) }
    var showHelpSheet by remember { mutableStateOf(false) }
    var batterySnapshot by remember { mutableStateOf(readBatterySnapshot(context)) }
    
    val requiredPermissions = remember {
        mutableListOf<String>().apply {
            add(android.Manifest.permission.ACCESS_FINE_LOCATION)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                add(android.Manifest.permission.NEARBY_WIFI_DEVICES)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                add(android.Manifest.permission.BLUETOOTH_SCAN)
            }
        }
    }
    
    var missingPermissions by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        while (true) {
            missingPermissions = requiredPermissions.any { perm ->
                androidx.core.content.ContextCompat.checkSelfPermission(context, perm) != 
                    android.content.pm.PackageManager.PERMISSION_GRANTED
            }
            batterySnapshot = readBatterySnapshot(context)
            delay(15_000L)
        }
    }

    val visibleChats = remember(chats) { chats.filter { !it.isGroup } }

    Box(modifier = Modifier.fillMaxSize()) {
        HomeBackground()

        Scaffold(
            topBar = {
                TopAppBar(
                    title = { 
                        Column {
                            Text(
                                tr("صدى", "Sada"),
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Text(
                                if (networkConnected)
                                    stringResource(R.string.mesh_status_active)
                                else
                                    tr("الشبكة غير متصلة", "Mesh offline"),
                                style = MaterialTheme.typography.labelSmall,
                                color = if (networkConnected) {
                                    NeonTeal.copy(alpha = 0.7f)
                                } else {
                                    Color.Gray.copy(alpha = 0.8f)
                                }
                            )
                        }
                    },
                    actions = {
                        BadgedBox(
                            badge = {
                                Badge(containerColor = LocalSadaPalette.current.surface) {
                                    Text(
                                        connectedPeersCount.toString(),
                                        color = LocalSadaPalette.current.textPrimary,
                                        style = MaterialTheme.typography.labelSmall
                                    )
                                }
                            }
                        ) {
                            IconButton(onClick = onDiagnosticsClick) {
                                Icon(
                                    imageVector = if (networkConnected) Icons.Default.CellTower else Icons.Default.SignalCellularOff,
                                    contentDescription = tr("حالة الشبكة", "Network status"),
                                    tint = if (networkConnected) NeonTeal else Color.Gray
                                )
                            }
                        }
                        TextButton(
                            onClick = {
                                batterySnapshot = readBatterySnapshot(context)
                                showBatteryDialog = true
                            },
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 0.dp)
                        ) {
                            Icon(
                                Icons.Default.Battery6Bar,
                                contentDescription = tr("حالة البطارية", "Battery status"),
                                tint = NeonTeal,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "${batterySnapshot.levelPercent}%",
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.9f),
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        IconButton(onClick = { showHelpSheet = true }) {
                            Icon(Icons.Default.HelpOutline, contentDescription = "Help", tint = LocalSadaPalette.current.textSecondary)
                        }
                        IconButton(onClick = { showSosConfirm = true }) {
                            Surface(
                                shape = CircleShape,
                                color = Color.Red.copy(alpha = 0.15f),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color.Red.copy(alpha = 0.4f)),
                                modifier = Modifier.size(36.dp)
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Icon(
                                        Icons.Default.Warning, 
                                        contentDescription = "SOS", 
                                        tint = Color.Red,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = LocalSadaPalette.current.background.copy(alpha = 0.9f),
                        titleContentColor = LocalSadaPalette.current.textPrimary,
                        navigationIconContentColor = LocalSadaPalette.current.textPrimary,
                        actionIconContentColor = LocalSadaPalette.current.textPrimary,
                        scrolledContainerColor = LocalSadaPalette.current.surface.copy(alpha = 0.8f)
                    ),
                    modifier = Modifier.blur(if (showSosConfirm) 10.dp else 0.dp)
                )
            },
            containerColor = Color.Transparent
        ) { padding ->
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item {
                    if (missingPermissions) {
                        PermissionsBanner(onGrant = onRequestPermissions)
                    }
                }
                item {
                    MeshSnapshotCard(
                        networkConnected = networkConnected,
                        connectedPeersCount = connectedPeersCount,
                        relayCount = relayCount,
                        outgoingUndeliveredCount = outgoingUndeliveredCount
                    )
                }
                item {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(
                            text = tr("الدردشات", "Chats"),
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.92f),
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }

                if (visibleChats.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 32.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = tr("لا توجد محادثات حالياً", "No chats yet"),
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f),
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                } else {
                    items(visibleChats) { chat ->
                        GlassChatTile(
                            chat = chat,
                            onClick = { onChatClick(chat.id) },
                            onDelete = { pendingDeleteChat = chat }
                        )
                    }
                }
            }
        }

        pendingDeleteChat?.let { chatToDelete ->
            val isDirectChat = !chatToDelete.isGroup
            AlertDialog(
                onDismissRequest = { pendingDeleteChat = null },
                title = {
                    Text(
                        tr("تأكيد الحذف", "Confirm deletion"),
                        fontWeight = FontWeight.Bold
                    )
                },
                text = {
                    Text(
                        if (isDirectChat) {
                            tr(
                                "حذف هذه الدردشة سيحذف جهة الاتصال أيضًا، ولن تتمكن من التواصل حتى تعيد إضافتها من جديد.",
                                "Deleting this chat will also delete this contact. You will not be able to communicate until you add each other again."
                            )
                        } else {
                            tr(
                                "هل تريد حذف هذه المحادثة نهائيًا؟",
                                "Do you want to permanently delete this conversation?"
                            )
                        }
                    )
                },
                confirmButton = {
                    Button(
                        onClick = {
                            onDeleteChat(chatToDelete.id)
                            pendingDeleteChat = null
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = Color.Red)
                    ) {
                        Text(tr("حذف", "Delete"))
                    }
                },
                dismissButton = {
                    TextButton(onClick = { pendingDeleteChat = null }) {
                        Text(tr("إلغاء", "Cancel"))
                    }
                },
                containerColor = LocalSadaPalette.current.surface,
                shape = RoundedCornerShape(18.dp)
            )
        }

        if (showHelpSheet) {
            QuickHelpBottomSheet(onDismiss = { showHelpSheet = false })
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
                title = { Text(tr("بث طوارئ", "Emergency SOS")) },
                text = { Text(tr("هل أنت متأكد من رغبتك في إرسال نداء استغاثة لجميع الأجهزة القريبة؟ سيتم تضمين موقعك الحالي.", "Are you sure you want to broadcast SOS to nearby devices? Your location will be included.")) },
                confirmButton = {
                    Button(
                        onClick = {
                            viewModel.triggerSos()
                            showSosConfirm = false
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = ErrorRed),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text(tr("إرسال نداء الاستغاثة", "Send SOS"), fontWeight = FontWeight.Bold)
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showSosConfirm = false }) {
                        Text(tr("إلغاء", "Cancel"), color = LocalSadaPalette.current.textPrimary.copy(alpha = 0.75f))
                    }
                },
                containerColor = LocalSadaPalette.current.surface,
                shape = RoundedCornerShape(24.dp)
            )
        }

        if (showBatteryDialog) {
            AlertDialog(
                onDismissRequest = { showBatteryDialog = false },
                title = { Text(tr("قياس البطارية", "Battery Monitor")) },
                text = {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("${tr("البطارية الحالية", "Current battery")}: ${batterySnapshot.levelPercent}%")
                        Text("${tr("حالة الشحن", "Charging status")}: ${batterySnapshot.chargingText}")
                        Text("${tr("وضع توفير الطاقة", "Power saver")}: ${batterySnapshot.powerSaverText}")
                        Text(
                            tr(
                                "للاستهلاك الدقيق للتطبيق، افتح صفحة بطارية التطبيق من النظام.",
                                "For precise app consumption, open the system app battery page."
                            ),
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f),
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                },
                confirmButton = {
                    TextButton(onClick = { openAppBatterySettings(context) }) {
                        Text(tr("فتح بطارية التطبيق", "Open app battery settings"))
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showBatteryDialog = false }) {
                        Text(tr("إغلاق", "Close"))
                    }
                },
                containerColor = LocalSadaPalette.current.surface,
                shape = RoundedCornerShape(18.dp)
            )
        }
    }
}


private data class BatterySnapshot(
    val levelPercent: Int,
    val chargingText: String,
    val powerSaverText: String
)

private fun readBatterySnapshot(context: Context): BatterySnapshot {
    val isArabic = java.util.Locale.getDefault().language.startsWith("ar")
    val batteryIntent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))

    val level = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
    val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
    val percent = if (level >= 0 && scale > 0) ((level * 100f) / scale).toInt() else 0

    val status = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
    val charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
        status == BatteryManager.BATTERY_STATUS_FULL

    val chargingText = if (charging) {
        if (isArabic) "يشحن" else "Charging"
    } else {
        if (isArabic) "غير موصول بالشاحن" else "Not charging"
    }

    val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
    val saver = powerManager.isPowerSaveMode
    val saverText = if (saver) {
        if (isArabic) "مفعل" else "Enabled"
    } else {
        if (isArabic) "معطل" else "Disabled"
    }

    return BatterySnapshot(percent, chargingText, saverText)
}

private fun openAppBatterySettings(context: Context) {
    val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        Intent("android.settings.APP_BATTERY_SETTINGS").apply {
            data = Uri.parse("package:${context.packageName}")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    } else {
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:${context.packageName}")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }
    context.startActivity(intent)
}

@Composable
fun HomeStatsRow(
    chatsCount: Int,
    groupsCount: Int,
    relayCount: Int,
    outgoingUndeliveredCount: Int
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        HomeStatCard(tr("الدردشات", "Chats"), chatsCount.toString(), Icons.Default.ChatBubbleOutline, Modifier.weight(1f))
        HomeStatCard(tr("المجموعات", "Groups"), groupsCount.toString(), Icons.Default.Groups, Modifier.weight(1f))
        HomeStatCard(tr("الترحيل", "Relays"), relayCount.toString(), Icons.Default.LocalShipping, Modifier.weight(1f))
        HomeStatCard(tr("غير مسلّمة", "Undelivered"), outgoingUndeliveredCount.toString(), Icons.Default.Schedule, Modifier.weight(1f))
    }
}

@Composable
fun HomeStatCard(
    title: String,
    value: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(14.dp),
        color = Color.White.copy(alpha = 0.05f),
        border = androidx.compose.foundation.BorderStroke(1.dp, Color.White.copy(alpha = 0.10f))
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(icon, contentDescription = null, tint = NeonTeal, modifier = Modifier.size(16.dp))
            Spacer(modifier = Modifier.width(6.dp))
            Column {
                Text(value, color = Color.White, fontWeight = FontWeight.Bold)
                Text(title, color = Color.White.copy(alpha = 0.65f), fontSize = 11.sp)
            }
        }
    }
}

@Composable
fun HomeQuickActions(
    onDiagnosticsClick: () -> Unit,
    onCreateGroupClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        AssistChip(
            onClick = onDiagnosticsClick,
            label = { Text(tr("التشخيص", "Diagnostics")) },
            leadingIcon = { Icon(Icons.Default.CellTower, contentDescription = null) }
        )
        AssistChip(
            onClick = onCreateGroupClick,
            label = { Text(tr("مجموعة جديدة", "New Group")) },
            leadingIcon = { Icon(Icons.Default.GroupAdd, contentDescription = null) }
        )
    }
}

@Composable
fun HomeBackground() {
    val background = LocalSadaPalette.current.background
    val glowA = NeonTeal.copy(alpha = 0.15f)
    val glowB = CyberBlue.copy(alpha = 0.12f)
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(
                        background,
                        background.copy(alpha = 0.96f),
                        background
                    )
                )
            )
    ) {
        Box(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .offset(x = 80.dp, y = (-30).dp)
                .size(220.dp)
                .background(
                    Brush.radialGradient(
                        listOf(glowA, Color.Transparent)
                    ),
                    CircleShape
                )
                .blur(24.dp)
        )
        Box(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .offset(x = (-40).dp, y = 30.dp)
                .size(260.dp)
                .background(
                    Brush.radialGradient(
                        listOf(glowB, Color.Transparent)
                    ),
                    CircleShape
                )
                .blur(28.dp)
        )
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
                color = LocalSadaPalette.current.textPrimary,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun MeshSnapshotCard(
    networkConnected: Boolean,
    connectedPeersCount: Int,
    relayCount: Int,
    outgoingUndeliveredCount: Int
) {
    val onSurface = MaterialTheme.colorScheme.onSurface
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        color = LocalSadaPalette.current.surface,
        border = androidx.compose.foundation.BorderStroke(1.dp, SadaPrimary.copy(alpha = 0.15f))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            MiniMetric(
                icon = if (networkConnected) Icons.Default.CellTower else Icons.Default.SignalCellularOff,
                label = tr("الأقران", "Peers"),
                value = connectedPeersCount.toString(),
                tint = if (networkConnected) LocalSadaPalette.current.successGreen else LocalSadaPalette.current.textSecondary
            )
            MiniMetric(
                icon = Icons.Default.LocalShipping,
                label = tr("الترحيل", "Relay"),
                value = relayCount.toString(),
                tint = SadaPrimary
            )
            MiniMetric(
                icon = Icons.Default.Schedule,
                label = tr("غير مُسلّمة", "Undelivered"),
                value = outgoingUndeliveredCount.toString(),
                tint = if (outgoingUndeliveredCount > 0) WarningAmber else LocalSadaPalette.current.textSecondary
            )
        }
    }
}

@Composable
private fun MiniMetric(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String,
    tint: Color
) {
    val onSurface = MaterialTheme.colorScheme.onSurface
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(16.dp))
        Spacer(modifier = Modifier.width(6.dp))
        Column {
            Text(value, color = onSurface, fontWeight = FontWeight.Bold, fontSize = 13.sp)
            Text(label, color = onSurface.copy(alpha = 0.72f), fontSize = 11.sp)
        }
    }
}

@Composable
fun DeliveryStatusBanner(outgoingUndeliveredCount: Int) {
    val onSurface = MaterialTheme.colorScheme.onSurface
    val text = if (outgoingUndeliveredCount > 0) {
        tr("لديك $outgoingUndeliveredCount رسالة لم تصل بعد", "You have $outgoingUndeliveredCount undelivered messages")
    } else {
        tr("كل رسائلك المرسلة وصلت أو قيد الاستلام", "All outgoing messages are delivered or in progress")
    }

    val tint = if (outgoingUndeliveredCount > 0) Color(0xFFFFB74D) else NeonTeal

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        shape = RoundedCornerShape(14.dp),
        color = tint.copy(alpha = 0.08f),
        border = androidx.compose.foundation.BorderStroke(1.dp, tint.copy(alpha = 0.25f))
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                if (outgoingUndeliveredCount > 0) Icons.Default.PendingActions else Icons.Default.DoneAll,
                contentDescription = null,
                tint = tint,
                modifier = Modifier.size(18.dp)
            )
            Spacer(modifier = Modifier.width(10.dp))
            Text(text = text, color = onSurface.copy(alpha = 0.9f), style = MaterialTheme.typography.bodySmall)
        }
    }
}

@Composable
fun GlassChatTile(
    chat: ChatEntity,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    val onSurface = MaterialTheme.colorScheme.onSurface
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .clickable(onClick = onClick),
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f),
        border = androidx.compose.foundation.BorderStroke(
            1.dp, 
            onSurface.copy(alpha = 0.12f)
        )
    ) {
        ListItem(
            headlineContent = { 
                Text(
                    chat.name, 
                    fontWeight = FontWeight.Bold,
                    color = onSurface
                ) 
            },
            supportingContent = { 
                Column {
                    Text(
                        chat.lastMessage ?: tr("لا توجد رسائل بعد", "No messages yet"),
                        maxLines = 1,
                        color = onSurface.copy(alpha = 0.72f)
                    )
                    if (chat.unreadCount > 0) {
                        Text(
                            tr("رسائل غير مقروءة: ${chat.unreadCount}", "Unread: ${chat.unreadCount}"),
                            maxLines = 1,
                            color = NeonTeal.copy(alpha = 0.95f),
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
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
                            if (chat.isGroup) Icons.Default.Security else Icons.Default.Person,
                            contentDescription = null,
                            tint = if (chat.isGroup) CyberBlue else NeonTeal,
                            modifier = Modifier.size(if (chat.isGroup) 24.dp else 28.dp)
                        )
                        if (chat.isGroup) {
                            Box(
                                modifier = Modifier
                                    .align(Alignment.BottomEnd)
                                    .offset(x = 4.dp, y = 4.dp)
                                    .size(16.dp)
                                    .background(CyberBlue, CircleShape)
                                    .border(1.dp, Color.Black, CircleShape),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Default.Groups, contentDescription = null, tint = Color.White, modifier = Modifier.size(10.dp))
                            }
                        }
                    }
                }
            },
            trailingContent = {
                Column(horizontalAlignment = Alignment.End) {
                    IconButton(
                        onClick = onDelete,
                        modifier = Modifier.size(28.dp)
                    ) {
                        Icon(
                            Icons.Default.Delete,
                            contentDescription = "Delete",
                            tint = Color.Red.copy(alpha = 0.8f),
                            modifier = Modifier.size(16.dp)
                        )
                    }
                    if (chat.unreadCount > 0) {
                        Badge(containerColor = NeonTeal) { 
                            Text(chat.unreadCount.toString(), color = Color.Black, fontWeight = FontWeight.Bold) 
                        }
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Icon(
                        Icons.AutoMirrored.Filled.KeyboardArrowRight,
                        contentDescription = null, 
                        tint = onSurface.copy(alpha = 0.35f),
                        modifier = Modifier.size(16.dp)
                    )
                }
            },
            colors = ListItemDefaults.colors(containerColor = Color.Transparent)
        )
    }
}

@Composable
fun PermissionsBanner(onGrant: () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 8.dp),
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.15f),
        border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.error.copy(alpha = 0.3f))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Default.SecurityUpdateWarning,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.error,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = stringResource(R.string.banner_permissions_missing),
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.error,
                    fontWeight = FontWeight.Bold
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = stringResource(R.string.banner_permissions_desc),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f)
            )
            Spacer(modifier = Modifier.height(12.dp))
            Button(
                onClick = onGrant,
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.error,
                    contentColor = Color.White
                ),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(10.dp),
                contentPadding = PaddingValues(vertical = 8.dp)
            ) {
                Text(
                    stringResource(R.string.banner_permissions_button),
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp
                )
            }
        }
    }
}
