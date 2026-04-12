package org.sada.messenger.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import org.sada.messenger.network.MeshEngine
import org.sada.messenger.ui.theme.*
import org.sada.messenger.ui.utils.tr
import androidx.activity.compose.BackHandler

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MeshDiagnosticsScreen(
    meshEngine: MeshEngine,
    udpDiagnostics: () -> Map<String, Any>,
    onBack: () -> Unit
) {
    val diagnostics = remember { mutableStateOf(meshEngine.getDiagnostics()) }
    val udpDiag = remember { mutableStateOf(udpDiagnostics()) }
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    // Handle system back button
    BackHandler {
        onBack()
    }

    // Refresh diagnostics periodically
    LaunchedEffect(Unit) {
        while(true) {
            diagnostics.value = meshEngine.getDiagnostics()
            udpDiag.value = udpDiagnostics()
            kotlinx.coroutines.delay(2000)
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { Text(tr("التشخيص", "Mesh Diagnostics"), color = Color.White) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                actions = {
                    IconButton(
                        onClick = {
                            val report = buildDiagnosticsReport(diagnostics.value, udpDiag.value)
                            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                            clipboard.setPrimaryClip(ClipData.newPlainText(tr("تقرير تشخيص صدى", "Sada Mesh Diagnostics"), report))
                            scope.launch {
                                snackbarHostState.showSnackbar(tr("تم نسخ التقرير", "Report copied"))
                            }
                        }
                    ) {
                        Icon(Icons.Default.ContentCopy, contentDescription = "Copy Report", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Black)
            )
        },
        containerColor = Color.Black
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                DiagSectionHeader(tr("طبقة النقل", "Transport Layer"))
                TransportStatusCard(diagnostics.value)
            }

            item {
                DiagSectionHeader(tr("إحصائيات المصافحة", "Handshake Stats"))
                HandshakeStatsCard(diagnostics.value)
            }

            item {
                DiagSectionHeader(tr("توجيه الرسائل", "Mesh Routing"))
                MeshRoutingCard(diagnostics.value)
            }

            item {
                DiagSectionHeader(tr("اكتشاف UDP (Fallback LAN)", "UDP Discovery (LAN Fallback)"))
                UdpDiagnosticsCard(udpDiag.value)
            }

            item {
                DiagSectionHeader(tr("جسر الهواء (True P2P)", "Air-Bridge (True P2P)"))
                AirBridgeDiagnosticsCard(diagnostics.value)
            }

            item {
                DiagSectionHeader(tr("الأقران المتصلون", "Connected Peers"))
            }

            val peers = diagnostics.value["connectedPeers"] as? List<String> ?: emptyList()
            if (peers.isEmpty()) {
                item {
                    Text(tr("لا يوجد أقران متصلون", "No connected peers"), color = Color.Gray, fontSize = 14.sp)
                }
            } else {
                items(peers) { peerId ->
                    PeerCard(peerId)
                }
            }
        }
    }
}

private fun buildDiagnosticsReport(
    diagnostics: Map<String, Any>,
    udpDiag: Map<String, Any>
): String {
    val sb = StringBuilder()
    sb.appendLine("Sada Diagnostic Report - Mesh Debug")
    diagnostics.toSortedMap().forEach { (key, value) ->
        sb.appendLine("$key: $value")
    }
    udpDiag.toSortedMap().forEach { (key, value) ->
        sb.appendLine("udp_$key: $value")
    }
    return sb.toString()
}

@Composable
fun DiagSectionHeader(title: String) {
    Text(
        text = title,
        color = NeonTeal,
        fontWeight = FontWeight.Bold,
        fontSize = 14.sp,
        modifier = Modifier.padding(bottom = 8.dp)
    )
}

@Composable
fun TransportStatusCard(diag: Map<String, Any>) {
    val isConnected = diag["isTransportConnected"] as? Boolean ?: false
    val activeTransport = diag["activeTransport"]?.toString() ?: "NONE"
    val socketConnected = diag["isSocketConnected"] as? Boolean ?: false
    DiagnosticCard {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                if (isConnected) Icons.Default.Link else Icons.Default.LinkOff,
                contentDescription = null,
                tint = if (isConnected) Color.Green else Color.Red
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(
                    if (isConnected) tr("النقل متصل", "Transport Connected") else tr("النقل مفصول", "Transport Disconnected"),
                    color = Color.White,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    "${tr("النقل النشط", "Active transport")}: $activeTransport",
                    color = Color.White.copy(alpha = 0.75f),
                    fontSize = 12.sp
                )
                Text(
                    "${tr("سياسة النقل", "Transport policy")}: D2D_FIRST",
                    color = Color.White.copy(alpha = 0.65f),
                    fontSize = 12.sp
                )
                Text(
                    "Socket: ${if (socketConnected) "up" else "down"} • ${tr("آخر خطأ", "Last Error")}: ${diag["lastError"]}",
                    color = Color.White.copy(alpha = 0.5f),
                    fontSize = 12.sp
                )
                Text(
                    "TX P2P/LAN: ${diag["transportSentNearby"] ?: 0}/${diag["transportSentLan"] ?: 0}",
                    color = Color.White.copy(alpha = 0.55f),
                    fontSize = 12.sp
                )
                Text(
                    "RX P2P/LAN: ${diag["transportReceivedNearby"] ?: 0}/${diag["transportReceivedLan"] ?: 0}",
                    color = Color.White.copy(alpha = 0.55f),
                    fontSize = 12.sp
                )
            }
        }
    }
}

@Composable
fun HandshakeStatsCard(diag: Map<String, Any>) {
    DiagnosticCard {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            MetricRow(tr("المحاولات", "Attempts"), diag["handshakeAttempts"].toString(), Icons.Default.Sync)
            MetricRow(tr("النجاح", "Success"), diag["handshakeAcks"].toString(), Icons.Default.DoneAll, Color.Green)
            MetricRow(tr("المهلة", "Timeouts"), diag["handshakeTimeouts"].toString(), Icons.Default.TimerOff, Color.Red)
        }
    }
}

@Composable
fun MeshRoutingCard(diag: Map<String, Any>) {
    DiagnosticCard {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            MetricRow(tr("المعالجة", "Processed"), diag["processedMessagesCount"].toString(), Icons.Default.FactCheck)
            MetricRow(tr("الفلاتر", "Filters"), diag["knownBloomFilters"].toString(), Icons.Default.FilterAlt, CyberBlue)
            MetricRow("Relay Queue Active", diag["relayQueueActiveCount"].toString(), Icons.Default.Inventory2, NeonTeal)
            MetricRow("Relay Flushed", diag["relayFlushedCount"].toString(), Icons.Default.ForwardToInbox, Color(0xFF90CAF9))
            MetricRow("ACK Cleanup", diag["ackCleanupCount"].toString(), Icons.Default.CleaningServices, Color(0xFFA5D6A7))
            MetricRow("Spam Blocked", diag["spamBlockedRequestsCount"].toString(), Icons.Default.Shield, Color(0xFFFFB74D))
        }
    }
}

@Composable
fun UdpDiagnosticsCard(diag: Map<String, Any>) {
    DiagnosticCard {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            MetricRow(tr("قيد التشغيل", "Running"), diag["running"].toString(), Icons.Default.WifiTethering)
            MetricRow(tr("المرسل", "Sent"), diag["sentCount"].toString(), Icons.Default.NorthEast, CyberBlue)
            MetricRow(tr("المستقبل", "Received"), diag["receivedCount"].toString(), Icons.Default.SouthWest, Color.Green)
            MetricRow(tr("آخر IP", "Last IP"), diag["lastFromIp"].toString(), Icons.Default.Router, NeonTeal)
            MetricRow(tr("واجهة الشبكة", "Interface"), diag["interfaceHint"]?.toString() ?: "", Icons.Default.SettingsEthernet,
                if (diag["interfaceHint"]?.toString()?.contains("p2p") == true) Color.Green else Color.Yellow)
            MetricRow(tr("واجهة P2P", "P2P Interface"),
                if (diag["p2pInterfaceDetected"] == true) "Detected" else "Not Found",
                Icons.Default.Wifi,
                if (diag["p2pInterfaceDetected"] == true) Color.Green else Color.Gray)
            MetricRow(tr("عنوان P2P", "P2P IP"), diag["p2pInterfaceIp"]?.toString() ?: "none", Icons.Default.Router,
                if (diag["p2pInterfaceIp"]?.toString()?.isNotEmpty() == true) Color.Green else Color.Gray)
            MetricRow(tr("آخر خطأ", "Last Error"), diag["lastError"].toString(), Icons.Default.ErrorOutline, Color.Red)
        }
    }
}

@Composable
fun AirBridgeDiagnosticsCard(diag: Map<String, Any>) {
    DiagnosticCard {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            // BLE
            MetricRow("BLE Advertising", diag["service_ble_isAdvertising"].toString(), Icons.Default.BluetoothAudio, CyberBlue)
            MetricRow("BLE Scanning", diag["service_ble_isScanning"].toString(), Icons.Default.BluetoothSearching, NeonTeal)
            MetricRow("BLE Discovered", diag["service_ble_discoveredPeersCount"].toString(), Icons.Default.FindInPage, Color.Green)
            MetricRow("BLE PeerId Length", diag["service_ble_peerIdLength"]?.toString() ?: "?", Icons.Default.DataObject, Color.White)
            MetricRow("BLE Last Discovered", diag["service_ble_lastDiscoveredId"]?.toString()?.take(20) ?: "", Icons.Default.Fingerprint, CyberBlue)
            // Wi-Fi Direct
            MetricRow("WFD Discovering", diag["service_wifidirect_isDiscovering"].toString(), Icons.Default.Podcasts, CyberBlue)
            MetricRow("WFD Connected", diag["service_wifidirect_isConnected"].toString(), if (diag["service_wifidirect_isConnected"] == true) Icons.Default.Wifi else Icons.Default.WifiOff, if (diag["service_wifidirect_isConnected"] == true) Color.Green else Color.Gray)
            MetricRow("WFD Group Formed", diag["service_wifidirect_groupFormed"].toString(), Icons.Default.Group, NeonTeal)
            MetricRow("Is Group Owner", diag["service_wifidirect_isGroupOwner"].toString(), Icons.Default.Domain, Color.White)
            MetricRow("GO IP", diag["service_wifidirect_groupOwnerIp"]?.toString() ?: "none", Icons.Default.Router, Color.Green)
            // Voice Messages
            MetricRow("Voice Sent", diag["voice_sentCount"]?.toString() ?: "0", Icons.Default.Mic, Color.Green)
            MetricRow("Voice Received", diag["voice_receivedCount"]?.toString() ?: "0", Icons.Default.VolumeUp, NeonTeal)
            // Socket
            MetricRow("Socket Retries", diag["socket_retryAttempts"]?.toString() ?: "0", Icons.Default.Replay, Color.Yellow)
            MetricRow("Socket Delay", diag["socket_lastConnectDelay"]?.toString() ?: "0ms", Icons.Default.Timer, Color.White)
            MetricRow("Server Ready At", diag["socket_serverReadyAt"]?.toString() ?: "0", Icons.Default.Check, Color.Green)
        }
    }
}

@Composable
fun MetricRow(label: String, value: String, icon: ImageVector, iconColor: Color = Color.White) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, contentDescription = null, tint = iconColor, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text(label, color = Color.White.copy(alpha = 0.7f), fontSize = 14.sp)
        }
        Text(value, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 16.sp)
    }
}

@Composable
fun PeerCard(peerId: String) {
    DiagnosticCard {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Dns, contentDescription = null, tint = NeonTeal)
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                peerId.take(16) + "...",
                color = Color.White,
                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace,
                fontSize = 12.sp
            )
        }
    }
}

@Composable
fun DiagnosticCard(content: @Composable () -> Unit) {
    Surface(
        color = Color.White.copy(alpha = 0.05f),
        shape = RoundedCornerShape(12.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, Color.White.copy(alpha = 0.1f)),
        modifier = Modifier.fillMaxWidth()
    ) {
        Box(modifier = Modifier.padding(16.dp)) {
            content()
        }
    }
}
