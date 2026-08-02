package org.sada.messenger.core.services

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.sada.messenger.SocketManager
import org.sada.messenger.SadaApplication
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.managers.UdpBroadcastManager

import org.sada.messenger.network.direct.BleMeshManager
import org.sada.messenger.network.direct.WifiDirectManager
import org.sada.messenger.security.KeyManager
import org.sada.messenger.runtime.MeshRuntime
import org.sada.messenger.runtime.LifecycleJobSet
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap

class MeshForegroundService : Service() {
    companion object {
        private const val TAG = "MeshForegroundService"
        private const val CHANNEL_ID = "sada_mesh_service"
        private const val NOTIFICATION_ID = 4242
        private const val DISCOVERY_PREFIX = "SADA_DISCOVERY"
        private const val DISCOVERY_VERSION = "v1"
        private const val DISCOVERY_INTERVAL_MS = 8000L
        private const val CONNECT_RETRY_COOLDOWN_MS = 10000L
        private const val SERVER_PREFERRED_FALLBACK_CONNECT_MS = 20000L
        private const val DISCOVERY_STALE_MS = 35000L
        private const val D2D_NEARBY_GRACE_MS = 15000L
        private const val BURST_DURATION_MS = 60000L
        private const val BASE_DISCOVERY_INTERVAL_MS = 8000L
        private const val BURST_DISCOVERY_INTERVAL_MS = 2500L
        private const val BACKOFF_DISCOVERY_INTERVAL_MS = 20000L
        private const val TCP_PORT = 8888

        private const val ACTION_START = "org.sada.messenger.action.START_MESH_SERVICE"
        private const val ACTION_PAUSE = "org.sada.messenger.action.PAUSE_MESH_SERVICE"
        private const val ACTION_RESUME = "org.sada.messenger.action.RESUME_MESH_SERVICE"
        private const val ACTION_STOP = "org.sada.messenger.action.STOP_MESH_SERVICE"

        @Volatile
        private var running = false
        @Volatile
        private var diagnosticsSnapshot: Map<String, Any> = emptyMap()
        private val shutdownScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

        fun isRunning(): Boolean = running
        fun getDiagnosticsSnapshot(): Map<String, Any> = diagnosticsSnapshot

        fun start(context: Context) {
            val intent = Intent(context, MeshForegroundService::class.java).apply {
                action = ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, MeshForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }

    private val serviceJob = SupervisorJob()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)
    private val lifecycleMutex = Mutex()
    private val connectionJobs = LifecycleJobSet()
    private lateinit var runtime: MeshRuntime
    private lateinit var socketManager: SocketManager
    private lateinit var udpBroadcastManager: UdpBroadcastManager

    private lateinit var bleMeshManager: BleMeshManager
    private lateinit var wifiDirectManager: WifiDirectManager
    private lateinit var keyManager: KeyManager
    private lateinit var database: AppDatabase

    private var discoveryJob: Job? = null
    private var statusMonitorJob: Job? = null
    private val lastConnectAttemptAt = ConcurrentHashMap<String, Long>()
    private val firstSeenAt = ConcurrentHashMap<String, Long>()
    private val lastSeenAt = ConcurrentHashMap<String, Long>()
    private val knownPeerIps = ConcurrentHashMap<String, String>() // peerId -> ip
    private val lanDeferredReasons = ConcurrentHashMap<String, String>()
    private var myPeerId: String = ""
    @Volatile
    private var paused = false
    private var connectedPeersCount = 0
    private var relayQueueActiveCount = 0
    private var burstUntilMs = 0L
    private var backoffUntilMs = 0L

    private enum class DiscoveryMode {
        IDLE,           // Base interval 8s - normal operation
        BURST,          // Fast interval 2.5s - urgent messages
        BACKOFF,        // Slow interval 20s - after failures
        POWER_SAVE,     // Very slow 60s - low battery
        EMERGENCY_ONLY  // Minimal activity - critical battery < 15%
    }
    private var discoveryMode = DiscoveryMode.IDLE
    
    // Adaptive power management
    private var lastBatteryCheckMs = 0L
    private var currentBatteryPercent = 100
    private var consecutiveEmptyCycles = 0
    private var lastDiscoveryActivityMs = System.currentTimeMillis()

    override fun onCreate() {
        super.onCreate()
        runtime = (application as SadaApplication).meshRuntime
        socketManager = runtime.socketManager
        udpBroadcastManager = runtime.udpBroadcastManager
        keyManager = runtime.keyManager
        database = runtime.database
        bleMeshManager = runtime.bleMeshManager
        wifiDirectManager = runtime.wifiDirectManager
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        when (action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_PAUSE -> {
                paused = true
                requestMeshStop()
                updateForegroundNotification()
                return START_STICKY
            }
            ACTION_RESUME -> {
                paused = false
                requestMeshStart()
                updateForegroundNotification()
                return START_STICKY
            }
        }

        startForeground(NOTIFICATION_ID, buildForegroundNotification())
        if (!running) {
            running = true
            requestMeshStart()
            startStatusMonitor()
        } else {
            updateForegroundNotification()
        }
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        val restartIntent = Intent(applicationContext, MeshForegroundService::class.java).apply {
            action = ACTION_START
        }
        val pending = PendingIntent.getService(
            applicationContext,
            995,
            restartIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setExact(
            AlarmManager.RTC_WAKEUP,
            System.currentTimeMillis() + 1000L,
            pending
        )
    }

    override fun onDestroy() {
        running = false
        val ownedServiceJob = serviceJob
        val ownedRuntime = runtime
        ownedServiceJob.cancel()
        statusMonitorJob = null
        discoveryJob = null
        shutdownScope.launch {
            runCatching { ownedRuntime.stop() }
                .onFailure { Log.e(TAG, "Runtime shutdown failed", it) }
            ownedServiceJob.join()
        }
        super.onDestroy()
    }

    private fun requestMeshStart() {
        serviceScope.launch {
            lifecycleMutex.withLock { startMeshCore() }
        }
    }

    private fun requestMeshStop() {
        serviceScope.launch {
            lifecycleMutex.withLock { stopMeshCore() }
        }
    }

    private suspend fun startMeshCore() {
        if (paused) {
            Log.d(TAG, "startMeshCore: paused, skipping")
            return
        }
        val prefs = getSharedPreferences("sada_app_state", Context.MODE_PRIVATE)
        val nickname = prefs.getString("user_nickname", null)
        if (nickname.isNullOrBlank()) {
            Log.w(TAG, "Mesh core initialization aborted: 'user_nickname' is missing from SharedPreferences. User might not be registered.")
            paused = true
            updateForegroundNotification()
            return
        }

        Log.i(TAG, "Starting Mesh Core for user: $nickname")
        myPeerId = keyManager.getPublicKeyBase64()
        Log.d(TAG, "Local Peer ID (Public Key): $myPeerId")

        try {
            runtime.start(::handleUdpDiscoveryPacket)
        } catch (error: Throwable) {
            Log.e(TAG, "Mesh runtime failed to start", error)
            return
        }

        discoveryJob?.cancelAndJoin()
        discoveryJob = serviceScope.launch {
            while (isActive) {
                updateDiscoveryMode()
                val packet = "$DISCOVERY_PREFIX|$DISCOVERY_VERSION|$myPeerId|$TCP_PORT"
                udpBroadcastManager.sendBroadcast(packet)
                updateDiagnosticsSnapshot()
                delay(currentDiscoveryIntervalMs())
            }
        }
        Log.i(TAG, "Mesh background core is active")
        updateDiagnosticsSnapshot()
        updateForegroundNotification()
    }

    private suspend fun stopMeshCore() {
        discoveryJob?.cancelAndJoin()
        discoveryJob = null
        connectionJobs.cancelAndJoinAll()
        runtime.stop()
        connectedPeersCount = 0
        updateDiagnosticsSnapshot()
    }

    private fun startStatusMonitor() {
        statusMonitorJob?.cancel()
        statusMonitorJob = serviceScope.launch {
            var lastConnected = -1
            var lastPaused = paused
            while (isActive) {
                if (!paused) {
                    if (runtime.isStarted) maybeReconnectKnownPeers()
                }
                val currentConnected = if (socketManager.isSocketConnected()) 1 else 0
                if (currentConnected != lastConnected || lastPaused != paused) {
                    connectedPeersCount = currentConnected
                    lastConnected = currentConnected
                    lastPaused = paused
                    updateForegroundNotification()
                }
                updateDiagnosticsSnapshot()
                delay(1000L)
            }
        }
    }

    private fun handleUdpDiscoveryPacket(payload: String, senderIp: String) {
        // D2D-first: if Wi-Fi Direct already has active links, skip LAN socket churn.
        if (wifiDirectManager.isConnected.value) return

        val parts = payload.split("|")
        if (parts.size < 4) return
        if (parts[0] != DISCOVERY_PREFIX) return

        val peerId = parts[2].trim()
        if (peerId.isBlank() || peerId == myPeerId) return

        val now = System.currentTimeMillis()
        firstSeenAt.putIfAbsent(peerId, now)
        lastSeenAt[peerId] = now
        knownPeerIps[peerId] = senderIp
        if (relayQueueActiveCount > 0) {
            boostDiscoveryBurst("relay_queue_pending")
        }
        val seenForMs = now - (firstSeenAt[peerId] ?: now)

        // Strict D2D-first gate:
        // If Wi-Fi Direct is forming a group, give it a grace window
        // before falling back to LAN TCP.
        if (wifiDirectManager.isConnected.value || bleMeshManager.getDiagnostics()["discoveredPeersCount"] as? Int ?: 0 > 0) {
            if (seenForMs < D2D_NEARBY_GRACE_MS) {
                lanDeferredReasons[peerId] = "d2d_grace_wait_${D2D_NEARBY_GRACE_MS}ms"
                return
            }
        }

        // Deterministic role rule + fallback override after grace period.
        val iAmServerPreferred = myPeerId < peerId
        val shouldTryAsServerPreferred =
            iAmServerPreferred && seenForMs >= SERVER_PREFERRED_FALLBACK_CONNECT_MS
        if (iAmServerPreferred && !shouldTryAsServerPreferred) return

        attemptConnect(
            peerId = peerId,
            senderIp = senderIp,
            reason = if (shouldTryAsServerPreferred) "fallback_role_override" else "discovery"
        )
    }

    private fun attemptConnect(peerId: String, senderIp: String, reason: String) {
        if (!isLanFallbackEnabled()) {
            lanDeferredReasons[peerId] = "lan_fallback_disabled_waiting_d2d"
            return
        }
        val attemptKey = "$peerId@$senderIp"
        val now = System.currentTimeMillis()
        val last = lastConnectAttemptAt[attemptKey] ?: 0L
        if (now - last < CONNECT_RETRY_COOLDOWN_MS) return
        lastConnectAttemptAt[attemptKey] = now
        if (socketManager.isSocketConnected()) return

        val connectionJob = serviceScope.launch {
            try {
                socketManager.setCurrentPeerId(peerId)
                val connected = socketManager.connectToHostAndWait(senderIp, peerId)
                currentCoroutineContext().ensureActive()
                Log.d(
                    TAG,
                    "UDP connect attempt[$reason]: peer=${peerId.take(12)} ip=$senderIp connected=$connected"
                )
                lanDeferredReasons.remove(peerId)
                connectedPeersCount = if (socketManager.isSocketConnected()) 1 else 0
                if (!connected) {
                    backoffUntilMs = System.currentTimeMillis() + 15000L
                    discoveryMode = DiscoveryMode.BACKOFF
                }
                updateForegroundNotification()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, "Failed connecting discovered peer $peerId@$senderIp [$reason]", e)
                backoffUntilMs = System.currentTimeMillis() + 15000L
                discoveryMode = DiscoveryMode.BACKOFF
            }
        }
        connectionJobs.track(connectionJob)
    }

    private fun maybeReconnectKnownPeers() {
        // D2D-first: do not force LAN reconnect while Wi-Fi Direct transport is active.
        if (wifiDirectManager.isConnected.value) return
        if (socketManager.isSocketConnected()) return
        val now = System.currentTimeMillis()
        val stalePeers = mutableListOf<String>()

        knownPeerIps.forEach { (peerId, ip) ->
            val lastSeen = lastSeenAt[peerId] ?: 0L
            if (now - lastSeen > DISCOVERY_STALE_MS) {
                stalePeers.add(peerId)
            } else {
                attemptConnect(peerId, ip, "status_monitor")
            }
        }

        stalePeers.forEach { peerId ->
            knownPeerIps.remove(peerId)
            firstSeenAt.remove(peerId)
            lastSeenAt.remove(peerId)
            lanDeferredReasons.remove(peerId)
        }
    }

    private fun currentDiscoveryIntervalMs(): Long {
        return when (discoveryMode) {
            DiscoveryMode.BURST -> BURST_DISCOVERY_INTERVAL_MS
            DiscoveryMode.BACKOFF -> BACKOFF_DISCOVERY_INTERVAL_MS
            DiscoveryMode.IDLE -> BASE_DISCOVERY_INTERVAL_MS
            DiscoveryMode.POWER_SAVE -> 60000L  // 60 seconds
            DiscoveryMode.EMERGENCY_ONLY -> 300000L // 5 minutes
        }
    }
    
    private fun checkBatteryLevel() {
        val now = System.currentTimeMillis()
        if (now - lastBatteryCheckMs < 60000L) return // Check once per minute
        
        lastBatteryCheckMs = now
        
        val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        
        if (level > 0 && scale > 0) {
            currentBatteryPercent = (level * 100 / scale)
            Log.d(TAG, "Battery level: $currentBatteryPercent%")
        }
    }

    private fun boostDiscoveryBurst(reason: String) {
        burstUntilMs = System.currentTimeMillis() + BURST_DURATION_MS
        if (discoveryMode != DiscoveryMode.BURST) {
            Log.d(TAG, "Discovery mode -> BURST ($reason)")
        }
        discoveryMode = DiscoveryMode.BURST
    }

    private fun updateDiscoveryMode() {
        refreshRelayQueueCount()
        checkBatteryLevel()
        
        val now = System.currentTimeMillis()
        
        // Priority 1: Critical battery - emergency only
        if (currentBatteryPercent < 15) {
            if (discoveryMode != DiscoveryMode.EMERGENCY_ONLY) {
                Log.w(TAG, "Discovery mode -> EMERGENCY_ONLY (battery $currentBatteryPercent%)")
                discoveryMode = DiscoveryMode.EMERGENCY_ONLY
            }
            return
        }
        
        // Priority 2: Low battery - power save
        if (currentBatteryPercent < 30) {
            if (discoveryMode != DiscoveryMode.POWER_SAVE) {
                Log.i(TAG, "Discovery mode -> POWER_SAVE (battery $currentBatteryPercent%)")
                discoveryMode = DiscoveryMode.POWER_SAVE
            }
            return
        }
        
        // Priority 3: Urgent messages - burst mode
        if (relayQueueActiveCount > 0) {
            boostDiscoveryBurst("relay_queue_pending:$relayQueueActiveCount")
            consecutiveEmptyCycles = 0
            return
        }
        
        // Priority 4: Time-based modes
        if (now < burstUntilMs) {
            discoveryMode = DiscoveryMode.BURST
            return
        }
        if (now < backoffUntilMs) {
            discoveryMode = DiscoveryMode.BACKOFF
            return
        }
        
        // Priority 5: Idle with adaptive deepening
        // If no activity for a while, gradually increase interval
        val timeSinceLastActivity = now - lastDiscoveryActivityMs
        if (timeSinceLastActivity > 300000L) { // 5 minutes
            consecutiveEmptyCycles++
            if (consecutiveEmptyCycles > 10) {
                // Enter power save after 10 empty cycles (10 * 8s = 80s)
                discoveryMode = DiscoveryMode.POWER_SAVE
                return
            }
        }
        
        discoveryMode = DiscoveryMode.IDLE
    }
    
    private fun recordDiscoveryActivity() {
        lastDiscoveryActivityMs = System.currentTimeMillis()
        consecutiveEmptyCycles = 0
    }

    private fun refreshRelayQueueCount() {
        relayQueueActiveCount = runBlocking {
            runCatching {
                database.relayQueueDao().getActiveRelays(java.util.Date()).size
            }.getOrDefault(relayQueueActiveCount)
        }
    }

    private fun isLanFallbackEnabled(): Boolean {
        return getSharedPreferences("sada_app_state", Context.MODE_PRIVATE)
            .getBoolean("lan_fallback_enabled", true)
    }

    private fun updateDiagnosticsSnapshot() {
        val merged = mutableMapOf<String, Any>(
            "discoveryMode" to discoveryMode.name,
            "discoveryIntervalMs" to currentDiscoveryIntervalMs(),
            "burstUntilMs" to burstUntilMs,
            "backoffUntilMs" to backoffUntilMs,
            "relayQueueActiveCount" to relayQueueActiveCount,
            "batteryPercent" to currentBatteryPercent,
            "consecutiveEmptyCycles" to consecutiveEmptyCycles,
            "knownPeerCount" to knownPeerIps.size,
            "peerKnownIps" to knownPeerIps.toMap(),
            "peerLanDeferredReasons" to lanDeferredReasons.toMap(),
            "lanFallbackEnabled" to isLanFallbackEnabled(),
            "socketConnected" to socketManager.isSocketConnected()
        )
        if (this::bleMeshManager.isInitialized) {
            merged.putAll(bleMeshManager.getDiagnostics().mapKeys { "ble_${it.key}" })
        }
        if (this::wifiDirectManager.isInitialized) {
            merged.putAll(wifiDirectManager.getDiagnostics().mapKeys { "wifidirect_${it.key}" })
        }
        diagnosticsSnapshot = merged
    }

    private fun buildForegroundNotification(): Notification {
        ensureChannel()
        val launchIntent = Intent(this, org.sada.messenger.MainActivity::class.java)
        val contentIntent = PendingIntent.getActivity(
            this,
            4242,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val pauseIntent = Intent(this, MeshForegroundService::class.java).apply { action = ACTION_PAUSE }
        val resumeIntent = Intent(this, MeshForegroundService::class.java).apply { action = ACTION_RESUME }
        val stopIntent = Intent(this, MeshForegroundService::class.java).apply { action = ACTION_STOP }

        val pausePending = PendingIntent.getService(this, 4243, pauseIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val resumePending = PendingIntent.getService(this, 4244, resumeIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val stopPending = PendingIntent.getService(this, 4245, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val isArabic = Locale.getDefault().language.startsWith("ar")
        val statusText = if (paused) {
            if (isArabic) "متوقف مؤقتاً" else "Paused"
        } else {
            if (isArabic) "نشط بالخلفية" else "Running in background"
        }
        val peersText = if (isArabic) {
            "الأقران المتصلون: $connectedPeersCount"
        } else {
            "Connected peers: $connectedPeersCount"
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_upload_done)
            .setContentTitle(if (isArabic) "شبكة صدى" else "Sada Mesh")
            .setContentText("$statusText • $peersText")
            .setStyle(NotificationCompat.BigTextStyle().bigText("$statusText\n$peersText"))
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(contentIntent)

        if (paused) {
            builder.addAction(
                android.R.drawable.ic_media_play,
                if (isArabic) "استئناف" else "Resume",
                resumePending
            )
        } else {
            builder.addAction(
                android.R.drawable.ic_media_pause,
                if (isArabic) "إيقاف مؤقت" else "Pause",
                pausePending
            )
        }
        builder.addAction(
            android.R.drawable.ic_menu_close_clear_cancel,
            if (isArabic) "إيقاف" else "Stop",
            stopPending
        )

        return builder.build()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Sada Mesh Service",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Keeps Sada mesh network active in background"
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun updateForegroundNotification() {
        if (!running) return
        NotificationManagerCompat.from(this).notify(NOTIFICATION_ID, buildForegroundNotification())
    }
}
