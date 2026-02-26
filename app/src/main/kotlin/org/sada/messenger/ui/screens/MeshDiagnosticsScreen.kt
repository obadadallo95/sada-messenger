package org.sada.messenger.ui.screens

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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.sada.messenger.network.MeshEngine
import org.sada.messenger.ui.theme.NeonTeal
import org.sada.messenger.ui.theme.CyberBlue

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MeshDiagnosticsScreen(
    meshEngine: MeshEngine,
    onBack: () -> Unit
) {
    val diagnostics = remember { mutableStateOf(meshEngine.getDiagnostics()) }
    
    // Refresh diagnostics periodically
    LaunchedEffect(Unit) {
        while(true) {
            diagnostics.value = meshEngine.getDiagnostics()
            kotlinx.coroutines.delay(2000)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Mesh Diagnostics / التشخيص", color = Color.White) },
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
                DiagSectionHeader("Transport Layer / طبقة النقل")
                TransportStatusCard(diagnostics.value)
            }

            item {
                DiagSectionHeader("Handshake Stats / المصافحة")
                HandshakeStatsCard(diagnostics.value)
            }

            item {
                DiagSectionHeader("Mesh Routing / توجيه الرسائل")
                MeshRoutingCard(diagnostics.value)
            }

            item {
                DiagSectionHeader("Connected Peers / الأقران")
            }

            val peers = diagnostics.value["connectedPeers"] as? List<String> ?: emptyList()
            if (peers.isEmpty()) {
                item {
                    Text("No connected peers / لا يوجد أقران", color = Color.Gray, fontSize = 14.sp)
                }
            } else {
                items(peers) { peerId ->
                    PeerCard(peerId)
                }
            }
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
    val isConnected = diag["isSocketConnected"] as? Boolean ?: false
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
                    if (isConnected) "Socket Connected / متصل" else "Socket Disconnected / مفصول",
                    color = Color.White,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    "Last Error: ${diag["lastError"]}",
                    color = Color.White.copy(alpha = 0.5f),
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
            MetricRow("Attempts / المحاولات", diag["handshakeAttempts"].toString(), Icons.Default.Sync)
            MetricRow("Success / النجاح", diag["handshakeAcks"].toString(), Icons.Default.DoneAll, Color.Green)
            MetricRow("Timeouts / المهلة", diag["handshakeTimeouts"].toString(), Icons.Default.TimerOff, Color.Red)
        }
    }
}

@Composable
fun MeshRoutingCard(diag: Map<String, Any>) {
    DiagnosticCard {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            MetricRow("Processed / المعالجة", diag["processedMessagesCount"].toString(), Icons.Default.FactCheck)
            MetricRow("Filters / الفلاتر", diag["knownBloomFilters"].toString(), Icons.Default.FilterAlt, CyberBlue)
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
