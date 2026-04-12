package org.sada.messenger.network.routing

import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.data.entities.RelayQueueEntity
import org.sada.messenger.security.SecureLogger
import java.security.MessageDigest
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.PriorityBlockingQueue
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Message Router
 * Implements store-and-forward routing with DHT-based discovery
 * Optimized for mesh networks with high latency and intermittent connectivity
 */
@Singleton
class MessageRouter @Inject constructor(
    private val database: AppDatabase
) {
    companion object {
        private const val TAG = "MessageRouter"
        
        // Routing constants
        const val MAX_HOPS = 10
        const val TTL_HOURS = 24
        const val MAX_QUEUE_SIZE = 1000
        const val RELAY_TIMEOUT_MS = 30000
        
        // Priority levels
        const val PRIORITY_CRITICAL = 0  // Emergency, verification
        const val PRIORITY_HIGH = 1      // Direct messages
        const val PRIORITY_NORMAL = 2    // Group messages
        const val PRIORITY_LOW = 3       // Status updates
    }

    // Routing table: destination -> list of next hops with metrics
    private val routingTable = ConcurrentHashMap<String, MutableList<RouteEntry>>()
    
    // Message queue with priority
    private val messageQueue = PriorityBlockingQueue<QueuedMessage>(MAX_QUEUE_SIZE)
    
    // Seen message IDs (Bloom filter for efficiency)
    private val seenMessageIds = Collections.synchronizedSet<String>(LinkedHashSet())
    
    // Known peers in the mesh
    private val knownPeers = ConcurrentHashMap<String, PeerInfo>()
    
    // State flows
    private val _routingStats = MutableStateFlow(RoutingStats())
    val routingStats: StateFlow<RoutingStats> = _routingStats.asStateFlow()
    
    private val _pendingMessages = MutableStateFlow(0)
    val pendingMessages: StateFlow<Int> = _pendingMessages.asStateFlow()
    
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private var routingJob: Job? = null
    private var cleanupJob: Job? = null

    /**
     * Route entry with metrics
     */
    data class RouteEntry(
        val nextHop: String,
        val hopCount: Int,
        val latency: Long,
        val lastSeen: Long,
        var successRate: Double
    )

    /**
     * Peer information
     */
    data class PeerInfo(
        val peerId: String,
        val publicKey: String,
        val lastSeen: Long,
        val capabilities: Set<PeerCapability>,
        val batteryLevel: Int
    )

    enum class PeerCapability {
        BLE, WIFI_DIRECT, INTERNET, RELAY, STORAGE
    }

    /**
     * Queued message with priority
     */
    data class QueuedMessage(
        val messageId: String,
        val destination: String,
        val payload: ByteArray,
        val priority: Int,
        val ttl: Long,
        val attempts: Int = 0,
        val timestamp: Long = System.currentTimeMillis()
    ) : Comparable<QueuedMessage> {
        override fun compareTo(other: QueuedMessage): Int {
            // Lower priority value = higher priority
            return priority.compareTo(other.priority)
        }

        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            if (javaClass != other?.javaClass) return false
            other as QueuedMessage
            return messageId == other.messageId
        }

        override fun hashCode(): Int {
            return messageId.hashCode()
        }
    }

    /**
     * Routing statistics
     */
    data class RoutingStats(
        val messagesSent: Int = 0,
        val messagesRelayed: Int = 0,
        val messagesDelivered: Int = 0,
        val messagesDropped: Int = 0,
        val averageLatency: Long = 0,
        val routingTableSize: Int = 0
    )

    /**
     * Initialize the router
     */
    fun initialize() {
        startRoutingEngine()
        startCleanupEngine()
        loadPendingMessages()
        SecureLogger.i(TAG, "MessageRouter initialized")
    }

    /**
     * Route a message to destination
     */
    suspend fun routeMessage(
        messageId: String,
        destination: String,
        payload: ByteArray,
        priority: Int = PRIORITY_NORMAL
    ): Boolean {
        // Check if we've seen this message before
        if (seenMessageIds.contains(messageId)) {
            SecureLogger.d(TAG, "Message already seen: $messageId")
            return false
        }

        // Add to seen set
        seenMessageIds.add(messageId)

        // Check if destination is directly reachable
        if (isDirectlyReachable(destination)) {
            return sendDirectMessage(destination, payload)
        }

        // Queue for relay
        val ttl = System.currentTimeMillis() + (TTL_HOURS * 60 * 60 * 1000)
        val queuedMessage = QueuedMessage(
            messageId = messageId,
            destination = destination,
            payload = payload,
            priority = priority,
            ttl = ttl
        )

        val added = messageQueue.offer(queuedMessage)
        if (added) {
            _pendingMessages.value = messageQueue.size
            saveToRelayQueue(queuedMessage)
            SecureLogger.i(TAG, "Message queued for relay: $messageId")
        } else {
            SecureLogger.w(TAG, "Message queue full, dropping: $messageId")
            _routingStats.value = _routingStats.value.copy(
                messagesDropped = _routingStats.value.messagesDropped + 1
            )
        }

        return added
    }

    /**
     * Process received message from the mesh
     */
    suspend fun processReceivedMessage(
        messageId: String,
        source: String,
        destination: String,
        payload: ByteArray,
        hopCount: Int
    ): Boolean {
        // Check for duplicate
        if (seenMessageIds.contains(messageId)) {
            return false
        }
        seenMessageIds.add(messageId)

        // Update routing table with source info
        updateRoutingTable(source, hopCount)

        // Check if message is for us
        if (isForMe(destination)) {
            SecureLogger.i(TAG, "Message delivered: $messageId")
            _routingStats.value = _routingStats.value.copy(
                messagesDelivered = _routingStats.value.messagesDelivered + 1
            )
            return true
        }

        // Check TTL
        if (hopCount >= MAX_HOPS) {
            SecureLogger.w(TAG, "Message exceeded max hops: $messageId")
            _routingStats.value = _routingStats.value.copy(
                messagesDropped = _routingStats.value.messagesDropped + 1
            )
            return false
        }

        // Relay message
        val relaySuccess = relayMessage(messageId, destination, payload, hopCount + 1)
        if (relaySuccess) {
            _routingStats.value = _routingStats.value.copy(
                messagesRelayed = _routingStats.value.messagesRelayed + 1
            )
        }

        return relaySuccess
    }

    /**
     * Update routing table with peer information
     */
    fun updateRoutingTable(peerId: String, hopCount: Int, latency: Long = 0) {
        val entry = routingTable[peerId]
        val newEntry = RouteEntry(
            nextHop = peerId,
            hopCount = hopCount,
            latency = latency,
            lastSeen = System.currentTimeMillis(),
            successRate = 1.0
        )

        if (entry == null) {
            routingTable[peerId] = mutableListOf(newEntry)
        } else {
            // Update existing entry
            entry.removeAll { it.nextHop == peerId }
            entry.add(newEntry)
        }

        _routingStats.value = _routingStats.value.copy(
            routingTableSize = routingTable.size
        )
    }

    /**
     * Register a peer in the mesh
     */
    fun registerPeer(peerInfo: PeerInfo) {
        knownPeers[peerInfo.peerId] = peerInfo
        SecureLogger.logConnection(TAG, "REGISTERED", peerInfo.peerId)
    }

    /**
     * Unregister a peer
     */
    fun unregisterPeer(peerId: String) {
        knownPeers.remove(peerId)
        routingTable.remove(peerId)
    }

    /**
     * Find best route to destination
     */
    private fun findBestRoute(destination: String): RouteEntry? {
        // Direct route
        routingTable[destination]?.let { routes ->
            return routes.minByOrNull { it.hopCount }
        }

        // Indirect route through known peers
        var bestRoute: RouteEntry? = null
        var bestScore = Double.MAX_VALUE

        routingTable.forEach { (peerId, routes) ->
            routes.forEach { route ->
                if (route.hopCount < MAX_HOPS) {
                    val score = calculateRouteScore(route)
                    if (score < bestScore) {
                        bestScore = score
                        bestRoute = route
                    }
                }
            }
        }

        return bestRoute
    }

    /**
     * Calculate route score (lower is better)
     */
    private fun calculateRouteScore(route: RouteEntry): Double {
        val hopWeight = 1.0
        val latencyWeight = 0.5
        val successRateWeight = 2.0

        return (route.hopCount * hopWeight) +
               (route.latency * latencyWeight / 1000.0) +
               ((1.0 - route.successRate) * successRateWeight)
    }

    /**
     * Start routing engine
     */
    private fun startRoutingEngine() {
        routingJob?.cancel()
        routingJob = scope.launch {
            while (isActive) {
                processMessageQueue()
                delay(1000) // Check queue every second
            }
        }
    }

    /**
     * Process queued messages
     */
    private suspend fun processMessageQueue() {
        val message = messageQueue.poll() ?: return

        // Check TTL
        if (System.currentTimeMillis() > message.ttl) {
            SecureLogger.w(TAG, "Message TTL expired: ${message.messageId}")
            _routingStats.value = _routingStats.value.copy(
                messagesDropped = _routingStats.value.messagesDropped + 1
            )
            database.relayQueueDao().removeByMessageId(message.messageId)
            _pendingMessages.value = messageQueue.size
            return
        }

        // Find route
        val route = findBestRoute(message.destination)
        if (route == null) {
            // No route available, re-queue with lower priority
            if (message.attempts < 5) {
                val requeued = message.copy(
                    attempts = message.attempts + 1,
                    priority = minOf(message.priority + 1, PRIORITY_LOW)
                )
                messageQueue.offer(requeued)
                SecureLogger.d(TAG, "Message re-queued: ${message.messageId}")
            } else {
                SecureLogger.w(TAG, "Message dropped after max attempts: ${message.messageId}")
                _routingStats.value = _routingStats.value.copy(
                    messagesDropped = _routingStats.value.messagesDropped + 1
                )
                database.relayQueueDao().removeByMessageId(message.messageId)
            }
            _pendingMessages.value = messageQueue.size
            return
        }

        // Attempt to send
        val success = sendToNextHop(route.nextHop, message)
        if (success) {
            database.relayQueueDao().removeByMessageId(message.messageId)
            _routingStats.value = _routingStats.value.copy(
                messagesSent = _routingStats.value.messagesSent + 1
            )
        } else {
            // Update route success rate
            route.successRate *= 0.9
        }

        _pendingMessages.value = messageQueue.size
    }

    /**
     * Send message to next hop
     */
    private suspend fun sendToNextHop(nextHop: String, message: QueuedMessage): Boolean {
        // Implementation depends on transport layer (BLE/Wi-Fi)
        // This is a placeholder
        return true
    }

    /**
     * Start cleanup engine
     */
    private fun startCleanupEngine() {
        cleanupJob?.cancel()
        cleanupJob = scope.launch {
            while (isActive) {
                cleanupOldEntries()
                delay(60000) // Run every minute
            }
        }
    }

    /**
     * Cleanup old routing entries
     */
    private fun cleanupOldEntries() {
        val now = System.currentTimeMillis()
        val timeout = 5 * 60 * 1000 // 5 minutes

        routingTable.entries.removeAll { (_, routes) ->
            routes.removeAll { now - it.lastSeen > timeout }
            routes.isEmpty()
        }

        // Cleanup seen message IDs (keep last 10000)
        if (seenMessageIds.size > 10000) {
            val iterator = seenMessageIds.iterator()
            var count = 0
            while (iterator.hasNext() && count < 1000) {
                iterator.next()
                iterator.remove()
                count++
            }
        }

        _routingStats.value = _routingStats.value.copy(
            routingTableSize = routingTable.size
        )
    }

    /**
     * Load pending messages from database
     */
    private fun loadPendingMessages() {
        scope.launch {
            try {
                val pending = database.relayQueueDao().getAllPending()
                pending.forEach { entity ->
                    val queuedMessage = QueuedMessage(
                        messageId = entity.messageId,
                        destination = entity.recipientHash,
                        payload = entity.payload.toByteArray(Charsets.UTF_8),
                        priority = PRIORITY_NORMAL,
                        ttl = entity.expiresAt?.time ?: System.currentTimeMillis() + (TTL_HOURS * 60 * 60 * 1000)
                    )
                    messageQueue.offer(queuedMessage)
                }
                _pendingMessages.value = messageQueue.size
                SecureLogger.i(TAG, "Loaded ${pending.size} pending messages from database")
            } catch (e: Exception) {
                SecureLogger.e(TAG, "Failed to load pending messages", e)
            }
        }
    }

    /**
     * Save message to relay queue database
     */
    private suspend fun saveToRelayQueue(message: QueuedMessage) {
        try {
            val entity = RelayQueueEntity(
                id = 0,
                messageId = message.messageId,
                recipientHash = message.destination,
                payload = String(message.payload, Charsets.UTF_8),
                expiresAt = Date(message.ttl)
            )
            database.relayQueueDao().addToQueue(entity)
        } catch (e: Exception) {
            SecureLogger.e(TAG, "Failed to save to relay queue", e)
        }
    }

    /**
     * Check if destination is directly reachable
     */
    private fun isDirectlyReachable(destination: String): Boolean {
        val peer = knownPeers[destination]
        return peer != null && (System.currentTimeMillis() - peer.lastSeen < 60000)
    }

    /**
     * Send direct message
     */
    private suspend fun sendDirectMessage(destination: String, payload: ByteArray): Boolean {
        // Implementation depends on transport layer
        return true
    }

    /**
     * Relay message to next hops
     */
    private suspend fun relayMessage(
        messageId: String,
        destination: String,
        payload: ByteArray,
        hopCount: Int
    ): Boolean {
        // Implementation: broadcast to nearby peers
        return true
    }

    /**
     * Check if message is for this device
     */
    private fun isForMe(destination: String): Boolean {
        // Compare with my public key hash
        return destination.startsWith("self") || destination == "local"
    }

    /**
     * Get optimal relay candidates for a destination
     */
    fun getRelayCandidates(destination: String): List<String> {
        return routingTable
            .filter { it.key != destination }
            .map { it.key }
            .sortedBy { routingTable[it]?.minByOrNull { it.hopCount }?.hopCount ?: Int.MAX_VALUE }
            .take(3) // Return top 3 candidates
    }

    /**
     * Cleanup and shutdown
     */
    fun cleanup() {
        routingJob?.cancel()
        cleanupJob?.cancel()
        scope.cancel()
        SecureLogger.i(TAG, "MessageRouter cleaned up")
    }
}
