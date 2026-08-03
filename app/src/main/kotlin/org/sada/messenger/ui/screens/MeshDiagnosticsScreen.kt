package org.sada.messenger.ui.screens

import android.content.Context
import android.content.Intent
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import org.sada.messenger.network.MeshEngine
import org.sada.messenger.runtime.MeshRuntimeController
import org.sada.messenger.runtime.DiagnosticsExporter
import org.sada.messenger.runtime.DiagnosticsReportFactory
import org.sada.messenger.runtime.DiagnosticEvent
import org.sada.messenger.ui.theme.*
import org.sada.messenger.ui.utils.tr
import androidx.activity.compose.BackHandler

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MeshDiagnosticsScreen(
    meshRuntime: MeshRuntimeController,
    udpDiagnostics: () -> Map<String, Any>,
    onBack: () -> Unit
) {
    val diagnostics = remember { mutableStateOf(meshRuntime.diagnostics()) }
    val udpDiag = remember { mutableStateOf(udpDiagnostics()) }
    val events = remember { mutableStateOf(meshRuntime.diagnosticEvents()) }
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
            diagnostics.value = meshRuntime.diagnostics()
            udpDiag.value = udpDiagnostics()
            events.value = meshRuntime.diagnosticEvents()
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
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(onClick = {
                        val report = DiagnosticsReportFactory.create(context, diagnostics.value, udpDiag.value, events.value)
                        val exported = DiagnosticsExporter.export(context, report)
                        context.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
                            type = "application/json"
                            putExtra(Intent.EXTRA_STREAM, exported.uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }, tr("مشاركة تقرير التشخيص", "Share diagnostics report")))
                        scope.launch { snackbarHostState.showSnackbar("File created • ${events.value.size} events • ${report.reportId}") }
                    }) { Text(tr("تصدير تقرير JSON", "Export JSON Report")) }
                    OutlinedButton(onClick = {
                        meshRuntime.clearDiagnosticEvents()
                        events.value = emptyList()
                        scope.launch { snackbarHostState.showSnackbar(tr("تم مسح الأحداث", "Events cleared")) }
                    }) { Text(tr("مسح الأحداث", "Clear Events")) }
                }
            }
            item {
                Button(
                    onClick = {
                        scope.launch {
                            val result = meshRuntime.forceDirectConnection()
                            diagnostics.value = meshRuntime.diagnostics()
                            events.value = meshRuntime.diagnosticEvents()
                            snackbarHostState.showSnackbar(
                                when (result) {
                                    "group_creation_started" -> tr("بدأ إنشاء مجموعة الاتصال المباشر", "Direct group creation started")
                                    "peer_discovery_started" -> tr("بدأ اكتشاف الاتصال المباشر", "Direct peer discovery started")
                                    "already_connected" -> tr("الاتصال المباشر قائم بالفعل", "Direct connection already active")
                                    "no_ble_peer" -> tr("لم يُكتشف جهاز قريب عبر البلوتوث", "No nearby BLE peer detected")
                                    "framework_not_idle" -> tr("نظام Wi‑Fi Direct ما زال مشغولاً", "Wi-Fi Direct framework is still busy")
                                    else -> tr("تعذرت محاولة الاتصال المباشر", "Direct connection attempt unavailable")
                                }
                            )
                        }
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(Icons.Default.RestartAlt, contentDescription = null)
                    Spacer(Modifier.width(8.dp))
                    Text(tr("إعادة ضبط ومحاولة اتصال مباشر", "Reset and Try Direct Connection"))
                }
            }
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = {
                            scope.launch {
                                val result = meshRuntime.forceDirectConnectionAsOwner(true)
                                snackbarHostState.showSnackbar(
                                    if (result == "group_creation_started")
                                        tr("بدأ الاختبار كمالك المجموعة", "Owner-role test started")
                                    else tr("تعذر بدء اختبار المالك: $result", "Owner test unavailable: $result")
                                )
                            }
                        },
                        modifier = Modifier.weight(1f)
                    ) { Text(tr("اختبار كمالك", "Test as Owner")) }

                    OutlinedButton(
                        onClick = {
                            scope.launch {
                                val result = meshRuntime.forceDirectConnectionAsOwner(false)
                                snackbarHostState.showSnackbar(
                                    if (result == "peer_discovery_started")
                                        tr("بدأ الاختبار كعميل", "Client-role test started")
                                    else tr("تعذر بدء اختبار العميل: $result", "Client test unavailable: $result")
                                )
                            }
                        },
                        modifier = Modifier.weight(1f)
                    ) { Text(tr("اختبار كعميل", "Test as Client")) }
                }
            }
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
                DiagSectionHeader(tr("رادار الجيران", "Neighbor Radar"))
                SignalRadarView(diagnostics.value)
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

            item { DiagSectionHeader(tr("الأحداث الأخيرة", "Recent Events")) }
            if (events.value.isEmpty()) {
                item { Text(tr("لا توجد أحداث مسجلة", "No recorded events"), color = Color.Gray) }
            } else {
                items(events.value.asReversed(), key = { it.sequence }) { event -> DiagnosticEventRow(event) }
            }
        }
    }
}

@Composable
private fun DiagnosticEventRow(event: DiagnosticEvent) {
    DiagnosticCard {
        Column {
            Text("#${event.sequence} ${event.component} • ${event.eventType}", color = Color.White, fontWeight = FontWeight.Bold)
            Text("${event.timestamp} • ${event.outcome}${event.transport?.let { " • $it" } ?: ""}", color = Color.Gray, fontSize = 11.sp)
            event.reason?.let { Text(it, color = Color.White.copy(alpha = .7f), fontSize = 12.sp) }
        }
    }
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
            MetricRow(tr("المصافحات المقبولة", "Accepted Handshakes"), diag["handshakeAccepted"].toString(), Icons.Default.DoneAll, Color.Green)
            MetricRow(tr("المهلة", "Timeouts"), diag["handshakeTimeouts"].toString(), Icons.Default.TimerOff, Color.Red)
            MetricRow(tr("آخر خطأ", "Last Error"), diag["lastHandshakeError"].toString(), Icons.Default.ErrorOutline, Color.Red)
        }
    }
}

@Composable
fun MeshRoutingCard(diag: Map<String, Any>) {
    DiagnosticCard {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            MetricRow(tr("حجم ذاكرة المعالجة (حد 5000)", "Processed Cache Size (max 5000)"), diag["processedMessagesCount"].toString(), Icons.Default.FactCheck)
            MetricRow(tr("الفلاتر", "Filters"), diag["knownBloomFilters"].toString(), Icons.Default.FilterAlt, CyberBlue)
            MetricRow("Relay Queue Active", diag["relayQueueActiveCount"].toString(), Icons.Default.Inventory2, NeonTeal)
            MetricRow("Relay Send Attempts", diag["relaySendAttempts"].toString(), Icons.Default.ForwardToInbox, Color(0xFF90CAF9))
            MetricRow("Relay Sent Successfully", diag["relaySendSucceeded"].toString(), Icons.Default.DoneAll, Color.Green)
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
            MetricRow("BLE Last Error", diag["service_ble_lastError"]?.toString() ?: "none", Icons.Default.ErrorOutline, Color.Red)
            // Wi-Fi Direct
            MetricRow("WFD Discovering", diag["service_wifidirect_isDiscovering"].toString(), Icons.Default.Podcasts, CyberBlue)
            MetricRow("WFD Connected", diag["service_wifidirect_isConnected"].toString(), if (diag["service_wifidirect_isConnected"] == true) Icons.Default.Wifi else Icons.Default.WifiOff, if (diag["service_wifidirect_isConnected"] == true) Color.Green else Color.Gray)
            MetricRow("WFD Group Formed", diag["service_wifidirect_groupFormed"].toString(), Icons.Default.Group, NeonTeal)
            MetricRow("Is Group Owner", diag["service_wifidirect_isGroupOwner"].toString(), Icons.Default.Domain, Color.White)
            MetricRow("GO IP", diag["service_wifidirect_groupOwnerIp"]?.toString() ?: "none", Icons.Default.Router, Color.Green)
            MetricRow("WFD Last Error", diag["service_wifidirect_lastError"]?.toString() ?: "none", Icons.Default.ErrorOutline, Color.Red)
            MetricRow("WFD Operation", diag["service_wifidirect_p2pOperation"]?.toString() ?: "IDLE", Icons.Default.Sync, Color.Yellow)
            // Voice Messages
            MetricRow("Voice Sent", diag["voice_sentCount"]?.toString() ?: "0", Icons.Default.Mic, Color.Green)
            MetricRow("Voice Received", diag["voice_receivedCount"]?.toString() ?: "0", Icons.Default.VolumeUp, NeonTeal)
            // Socket
            MetricRow("Socket Retries", diag["socket_retryAttempts"]?.toString() ?: "0", Icons.Default.Replay, Color.Yellow)
            MetricRow("Socket Delay", diag["socket_lastConnectDelay"]?.toString() ?: "0ms", Icons.Default.Timer, Color.White)
            MetricRow("Server Ready At", diag["socket_serverReadyAt"]?.toString() ?: "0", Icons.Default.Check, Color.Green)
            MetricRow("TCP Last Error", diag["socket_lastError"]?.toString() ?: "none", Icons.Default.ErrorOutline, Color.Red)
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
fun SignalRadarView(diag: Map<String, Any>) {
    val rssiMap = diag["service_ble_discoveredPeersRssi"] as? Map<String, Int> ?: emptyMap()
    
    DiagnosticCard {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                tr("قوة إشارة جيرانك", "Nearby Neighbor Signal Strength"),
                color = Color.White.copy(alpha = 0.7f),
                fontSize = 12.sp,
                modifier = Modifier.padding(bottom = 12.dp)
            )
            
            if (rssiMap.isEmpty()) {
                Text(
                    tr("لا يوجد جيران قريبون للمسح", "No neighbors nearby to scan"),
                    color = Color.Gray,
                    fontSize = 14.sp,
                    modifier = Modifier.padding(vertical = 20.dp)
                )
            } else {
                rssiMap.forEach { (peerId, rssi) ->
                    val signalPercent = ((rssi + 100).coerceIn(0, 60) / 60f)
                    val signalColor = when {
                        rssi > -60 -> Color.Green
                        rssi > -80 -> Color.Yellow
                        else -> Color.Red
                    }
                    
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            peerId.take(8),
                            color = NeonTeal,
                            fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace,
                            fontSize = 12.sp,
                            modifier = Modifier.width(80.dp)
                        )
                        
                        LinearProgressIndicator(
                            progress = { signalPercent },
                            modifier = Modifier.weight(1f).height(8.dp).clip(RoundedCornerShape(4.dp)),
                            color = signalColor,
                            trackColor = Color.White.copy(alpha = 0.1f)
                        )
                        
                        Spacer(modifier = Modifier.width(8.dp))
                        
                        Text(
                            "$rssi dBm",
                            color = Color.White,
                            fontSize = 12.sp,
                            modifier = Modifier.width(60.dp),
                            textAlign = TextAlign.End
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                tr("تحرك ببطء لتحسين قوة الإشارة", "Move slowly to improve signal strength"),
                color = NeonTeal.copy(alpha = 0.6f),
                fontSize = 10.sp,
                textAlign = TextAlign.Center
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
