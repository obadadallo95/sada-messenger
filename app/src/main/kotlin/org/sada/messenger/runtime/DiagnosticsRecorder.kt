package org.sada.messenger.runtime

import android.content.Context
import android.os.Build
import androidx.core.content.pm.PackageInfoCompat
import org.json.JSONArray
import org.json.JSONObject
import org.sada.messenger.BuildConfig
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID

data class DiagnosticEvent(
    val sequence: Long,
    val timestamp: String,
    val component: String,
    val eventType: String,
    val outcome: String,
    val reason: String? = null,
    val peerToken: String? = null,
    val messageToken: String? = null,
    val transport: String? = null
)

class DiagnosticsRecorder(private val capacity: Int = 100) {
    private val events = ArrayDeque<DiagnosticEvent>(capacity)
    private var nextSequence = 1L

    @Synchronized
    fun record(
        component: String,
        eventType: String,
        outcome: String,
        reason: String? = null,
        peerId: String? = null,
        messageId: String? = null,
        transport: String? = null
    ): DiagnosticEvent {
        val event = DiagnosticEvent(
            sequence = nextSequence++,
            timestamp = DiagnosticsRedactor.isoTimestamp(),
            component = component,
            eventType = eventType,
            outcome = outcome,
            reason = DiagnosticsRedactor.safeReason(reason),
            peerToken = peerId?.takeIf { it.isNotBlank() }?.let(DiagnosticsRedactor::peerToken),
            messageToken = messageId?.takeIf { it.isNotBlank() }?.let(DiagnosticsRedactor::messageToken),
            transport = transport?.takeIf { it.isNotBlank() }
        )
        if (events.size == capacity) events.removeFirst()
        events.addLast(event)
        return event
    }

    @Synchronized
    fun snapshot(): List<DiagnosticEvent> = events.toList()

    @Synchronized
    fun clear() = events.clear()
}

object DiagnosticsRedactor {
    private const val TOKEN_SALT = "sada-diagnostics-correlation-v1"

    fun peerToken(value: String): String = token("peer", value)
    fun messageToken(value: String): String = token("message", value)

    private fun token(kind: String, value: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
            .digest("$TOKEN_SALT:$kind:$value".toByteArray(Charsets.UTF_8))
        return digest.take(8).joinToString("") { "%02x".format(it) }
    }

    fun ip(value: String?): String? {
        if (value.isNullOrBlank() || value == "none") return null
        if (value.contains(':')) {
            val prefix = value.substringBefore(':').take(4)
            return if (prefix.isBlank()) "ipv6" else "$prefix:…"
        }
        val parts = value.split('.')
        return if (parts.size == 4 && parts.all { it.toIntOrNull() in 0..255 }) {
            "${parts[0]}.${parts[1]}.x.x"
        } else null
    }

    fun safeReason(value: String?): String? {
        if (value.isNullOrBlank() || value.equals("none", true)) return null
        if (value.matches(Regex("[a-z][a-z0-9_]{0,63}"))) return value
        return value
            .replace(Regex("(?:[A-Za-z0-9+/=_-]{20,})"), "[redacted]")
            .replace(Regex("(?:\\d{1,3}\\.){3}\\d{1,3}"), "[redacted-ip]")
            .take(96)
    }

    fun isoTimestamp(date: Date = Date()): String = SimpleDateFormat(
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US
    ).apply { timeZone = TimeZone.getTimeZone("UTC") }.format(date)
}

data class DiagnosticsReport(
    val schemaVersion: Int = 1,
    val generatedAt: String,
    val reportId: String,
    val device: Map<String, Any?>,
    val app: Map<String, Any?>,
    val runtime: Map<String, Any?>,
    val transport: Map<String, Any?>,
    val ble: Map<String, Any?>,
    val wifiDirect: Map<String, Any?>,
    val udp: Map<String, Any?>,
    val handshake: Map<String, Any?>,
    val relayQueue: Map<String, Any?>,
    val counters: Map<String, Any?>,
    val health: List<String>,
    val events: List<DiagnosticEvent>
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("schemaVersion", schemaVersion)
        put("generatedAt", generatedAt)
        put("reportId", reportId)
        put("device", JSONObject(device))
        put("app", JSONObject(app))
        put("runtime", JSONObject(runtime))
        put("transport", JSONObject(transport))
        put("ble", JSONObject(ble))
        put("wifiDirect", JSONObject(wifiDirect))
        put("udp", JSONObject(udp))
        put("handshake", JSONObject(handshake))
        put("relayQueue", JSONObject(relayQueue))
        put("counters", JSONObject(counters))
        put("health", JSONArray(health))
        put("events", JSONArray(events.map { event ->
            JSONObject().apply {
                put("sequence", event.sequence)
                put("timestamp", event.timestamp)
                put("component", event.component)
                put("eventType", event.eventType)
                put("outcome", event.outcome)
                event.reason?.let { put("reason", it) }
                event.peerToken?.let { put("peerToken", it) }
                event.messageToken?.let { put("messageToken", it) }
                event.transport?.let { put("transport", it) }
            }
        }))
    }

    fun encode(): String = toJson().toString(2)
}

object DiagnosticsReportFactory {
    fun create(
        context: Context?,
        diagnostics: Map<String, Any?>,
        supplemental: Map<String, Any?>,
        events: List<DiagnosticEvent>
    ): DiagnosticsReport {
        val accepted = diagnostics["handshakeAccepted"] as? Number ?: 0
        val socketConnected = diagnostics["isSocketConnected"] as? Boolean ?: false
        val relayActive = diagnostics["relayQueueActiveCount"] as? Number ?: 0
        val health = buildList {
            if (socketConnected && accepted.toLong() == 0L) add("socket_connected_without_accepted_handshake")
            if (relayActive.toLong() > 0L && events.none { it.eventType == "packet_relayed" && it.outcome == "success" }) {
                add("relay_queue_has_no_recorded_progress")
            }
        }
        val role = when {
            diagnostics["service_wifidirect_isGroupOwner"] == true -> "group_owner"
            diagnostics["service_wifidirect_groupFormed"] == true -> "client"
            socketConnected -> "lan_peer"
            else -> "none"
        }
        val packageInfo = context?.packageManager?.getPackageInfo(context.packageName, 0)
        return DiagnosticsReport(
            generatedAt = DiagnosticsRedactor.isoTimestamp(),
            reportId = UUID.randomUUID().toString(),
            device = mapOf(
                "manufacturer" to Build.MANUFACTURER,
                "model" to Build.MODEL,
                "androidVersion" to Build.VERSION.RELEASE,
                "sdk" to Build.VERSION.SDK_INT
            ),
            app = mapOf(
                "versionName" to (packageInfo?.versionName ?: "unknown"),
                "versionCode" to (packageInfo?.let(PackageInfoCompat::getLongVersionCode) ?: 0L),
                "buildType" to BuildConfig.BUILD_TYPE
            ),
            runtime = mapOf(
                "started" to (diagnostics["runtimeStarted"] ?: false),
                "startCount" to (diagnostics["runtimeStartCount"] ?: 0),
                "stopCount" to (diagnostics["runtimeStopCount"] ?: 0),
                "owner" to (diagnostics["runtimeOwner"] ?: "MeshForegroundService"),
                "localPeerToken" to diagnostics["myPeerId"]?.toString()?.let(DiagnosticsRedactor::peerToken)
            ),
            transport = mapOf(
                "active" to (diagnostics["activeTransport"] ?: "NONE"),
                "socketConnected" to socketConnected,
                "connectionRole" to role,
                "lastError" to DiagnosticsRedactor.safeReason(diagnostics["lastError"]?.toString()),
                "socketLastError" to DiagnosticsRedactor.safeReason(diagnostics["socket_lastError"]?.toString()),
                "serverReadyAt" to (diagnostics["socket_serverReadyAt"] ?: 0L),
                "clientConnectedAt" to (diagnostics["service_wifidirect_clientConnectedAt"] ?: 0L)
            ),
            ble = mapOf(
                "advertising" to (diagnostics["service_ble_isAdvertising"] ?: false),
                "scanning" to (diagnostics["service_ble_isScanning"] ?: false),
                "discoveredPeers" to (diagnostics["service_ble_discoveredPeersCount"] ?: 0),
                "lastError" to DiagnosticsRedactor.safeReason(diagnostics["service_ble_lastError"]?.toString())
            ),
            wifiDirect = mapOf(
                "discovering" to (diagnostics["service_wifidirect_isDiscovering"] ?: false),
                "connected" to (diagnostics["service_wifidirect_isConnected"] ?: false),
                "groupFormed" to (diagnostics["service_wifidirect_groupFormed"] ?: false),
                "groupOwner" to (diagnostics["service_wifidirect_isGroupOwner"] ?: false),
                "groupOwnerIp" to DiagnosticsRedactor.ip(diagnostics["service_wifidirect_groupOwnerIp"]?.toString()),
                "lastError" to DiagnosticsRedactor.safeReason(diagnostics["service_wifidirect_lastError"]?.toString()),
                "operation" to (diagnostics["service_wifidirect_p2pOperation"] ?: "IDLE"),
                "operationInFlight" to (diagnostics["service_wifidirect_operationInFlight"] ?: false)
            ),
            udp = mapOf(
                "running" to (supplemental["running"] ?: false),
                "sentCount" to (supplemental["sentCount"] ?: 0),
                "receivedCount" to (supplemental["receivedCount"] ?: 0),
                "lastFromIp" to DiagnosticsRedactor.ip(supplemental["lastFromIp"]?.toString()),
                "lastError" to DiagnosticsRedactor.safeReason(supplemental["lastError"]?.toString())
            ),
            handshake = mapOf(
                "attempts" to (diagnostics["handshakeAttempts"] ?: 0),
                "accepted" to (diagnostics["handshakeAccepted"] ?: 0),
                "rejected" to (diagnostics["handshakeRejected"] ?: 0),
                "timeouts" to (diagnostics["handshakeTimeouts"] ?: 0),
                "lastError" to DiagnosticsRedactor.safeReason(diagnostics["lastHandshakeError"]?.toString())
            ),
            relayQueue = mapOf(
                "active" to (diagnostics["relayQueueActiveCount"] ?: 0),
                "sendAttempts" to (diagnostics["relaySendAttempts"] ?: 0),
                "sendSucceeded" to (diagnostics["relaySendSucceeded"] ?: 0)
            ),
            counters = mapOf(
                "processedCacheSize" to (diagnostics["processedMessagesCount"] ?: 0),
                "duplicateIgnored" to (diagnostics["duplicateIgnoredCount"] ?: 0),
                "packetReceived" to (diagnostics["packetReceivedCount"] ?: 0),
                "ackSent" to (diagnostics["ackSentCount"] ?: 0),
                "ackReceived" to (diagnostics["ackReceivedCount"] ?: 0),
                "eventCount" to events.size
            ),
            health = health,
            events = events.sortedBy { it.sequence }
        )
    }
}
