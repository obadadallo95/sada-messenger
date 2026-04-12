package org.sada.messenger.core.performance

import android.content.Context
import android.os.Debug
import android.os.SystemClock
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.sada.messenger.security.SecureLogger
import java.util.concurrent.ConcurrentHashMap
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Performance Monitor
 * Tracks app performance metrics: CPU, memory, battery, network
 */
@Singleton
class PerformanceMonitor @Inject constructor(
    private val context: Context
) {
    companion object {
        private const val TAG = "PerformanceMonitor"
        private const val MONITORING_INTERVAL_MS = 5000L
        
        // Memory thresholds
        const val MEMORY_WARNING_MB = 100
        const val MEMORY_CRITICAL_MB = 50
        
        // Battery thresholds
        const val BATTERY_DRAIN_WARNING = 5.0f // % per hour
    }

    private val _metrics = MutableStateFlow(PerformanceMetrics())
    val metrics: StateFlow<PerformanceMetrics> = _metrics.asStateFlow()

    private val operationTimings = ConcurrentHashMap<String, MutableList<Long>>()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private var monitoringJob: Job? = null

    private var lastBatteryLevel = 100
    private var lastBatteryCheckTime = SystemClock.elapsedRealtime()

    /**
     * Start monitoring performance
     */
    fun startMonitoring() {
        monitoringJob?.cancel()
        monitoringJob = scope.launch {
            while (isActive) {
                collectMetrics()
                delay(MONITORING_INTERVAL_MS)
            }
        }
        SecureLogger.i(TAG, "Performance monitoring started")
    }

    /**
     * Stop monitoring
     */
    fun stopMonitoring() {
        monitoringJob?.cancel()
        monitoringJob = null
        SecureLogger.i(TAG, "Performance monitoring stopped")
    }

    /**
     * Collect current metrics
     */
    private fun collectMetrics() {
        val runtime = Runtime.getRuntime()
        
        // Memory metrics
        val maxMemory = runtime.maxMemory() / 1024 / 1024 // MB
        val totalMemory = runtime.totalMemory() / 1024 / 1024 // MB
        val freeMemory = runtime.freeMemory() / 1024 / 1024 // MB
        val usedMemory = totalMemory - freeMemory
        
        // Native heap
        val nativeHeapSize = Debug.getNativeHeapSize() / 1024 / 1024
        val nativeHeapFree = Debug.getNativeHeapFreeSize() / 1024 / 1024
        val nativeHeapUsed = nativeHeapSize - nativeHeapFree

        // Battery
        val batteryIntent = context.registerReceiver(null,
            android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED)
        )
        
        var batteryLevel = 100
        var isCharging = false
        
        batteryIntent?.let { intent ->
            val level = intent.getIntExtra(android.os.BatteryManager.EXTRA_LEVEL, -1)
            val scale = intent.getIntExtra(android.os.BatteryManager.EXTRA_SCALE, -1)
            val status = intent.getIntExtra(android.os.BatteryManager.EXTRA_STATUS, -1)
            
            if (level != -1 && scale != -1) {
                batteryLevel = (level * 100 / scale.toFloat()).toInt()
            }
            
            isCharging = status == android.os.BatteryManager.BATTERY_STATUS_CHARGING ||
                    status == android.os.BatteryManager.BATTERY_STATUS_FULL
        }
        
        // Calculate battery drain rate
        val currentTime = SystemClock.elapsedRealtime()
        val timeDeltaHours = (currentTime - lastBatteryCheckTime) / (1000f * 60f * 60f)
        val batteryDelta = lastBatteryLevel - batteryLevel
        val drainRate = if (timeDeltaHours > 0) batteryDelta / timeDeltaHours else 0f
        
        lastBatteryLevel = batteryLevel
        lastBatteryCheckTime = currentTime

        // Update metrics
        _metrics.value = PerformanceMetrics(
            usedMemoryMb = usedMemory.toInt(),
            availableMemoryMb = (maxMemory - usedMemory).toInt(),
            nativeHeapMb = nativeHeapUsed.toInt(),
            batteryPercentage = batteryLevel,
            isCharging = isCharging,
            batteryDrainRate = drainRate,
            operationTimings = operationTimings.mapValues { entry ->
                val timings = entry.value
                if (timings.isNotEmpty()) {
                    TimingStats(
                        avgMs = timings.average().toLong(),
                        minMs = timings.minOrNull() ?: 0,
                        maxMs = timings.maxOrNull() ?: 0,
                        count = timings.size
                    )
                } else {
                    TimingStats(0, 0, 0, 0)
                }
            }
        )

        // Log warnings
        if (usedMemory > MEMORY_WARNING_MB) {
            SecureLogger.logSecurity("MEMORY_WARNING", "Memory usage: $usedMemory MB")
        }
        
        if (!isCharging && drainRate > BATTERY_DRAIN_WARNING) {
            SecureLogger.logSecurity("BATTERY_DRAIN", "Battery drain: $drainRate% per hour")
        }
    }

    /**
     * Measure operation timing
     */
    inline fun <T> measureOperation(operationName: String, block: () -> T): T {
        val startTime = SystemClock.elapsedRealtime()
        return try {
            block()
        } finally {
            val duration = SystemClock.elapsedRealtime() - startTime
            recordTiming(operationName, duration)
        }
    }

    /**
     * Record timing for an operation
     */
    fun recordTiming(operationName: String, durationMs: Long) {
        val timings = operationTimings.getOrPut(operationName) { mutableListOf() }
        timings.add(durationMs)
        
        // Keep only last 100 measurements
        if (timings.size > 100) {
            timings.removeAt(0)
        }
    }

    /**
     * Get timing stats for an operation
     */
    fun getTimingStats(operationName: String): TimingStats? {
        val timings = operationTimings[operationName]
        return timings?.let {
            if (it.isNotEmpty()) {
                TimingStats(
                    avgMs = it.average().toLong(),
                    minMs = it.minOrNull() ?: 0,
                    maxMs = it.maxOrNull() ?: 0,
                    count = it.size
                )
            } else {
                null
            }
        }
    }

    /**
     * Log memory allocation
     */
    fun logMemoryAllocation(tag: String, bytes: Long) {
        val mb = bytes / 1024 / 1024
        if (mb > 10) { // Only log if > 10MB
            SecureLogger.w(TAG, "Large allocation in $tag: ${mb}MB")
        }
    }

    /**
     * Force garbage collection and log memory freed
     */
    fun forceGarbageCollection() {
        val runtime = Runtime.getRuntime()
        val usedBefore = (runtime.totalMemory() - runtime.freeMemory()) / 1024 / 1024
        
        System.gc()
        System.runFinalization()
        System.gc()
        
        val usedAfter = (runtime.totalMemory() - runtime.freeMemory()) / 1024 / 1024
        val freed = usedBefore - usedAfter
        
        SecureLogger.i(TAG, "GC freed: ${freed}MB")
    }

    /**
     * Performance metrics data class
     */
    data class PerformanceMetrics(
        val usedMemoryMb: Int = 0,
        val availableMemoryMb: Int = 0,
        val nativeHeapMb: Int = 0,
        val batteryPercentage: Int = 100,
        val isCharging: Boolean = true,
        val batteryDrainRate: Float = 0f,
        val operationTimings: Map<String, TimingStats> = emptyMap()
    ) {
        val isMemoryLow: Boolean get() = availableMemoryMb < MEMORY_WARNING_MB
        val isMemoryCritical: Boolean get() = availableMemoryMb < MEMORY_CRITICAL_MB
        val isBatteryDraining: Boolean get() = !isCharging && batteryDrainRate > BATTERY_DRAIN_WARNING
    }

    data class TimingStats(
        val avgMs: Long,
        val minMs: Long,
        val maxMs: Long,
        val count: Int
    )

    /**
     * Cleanup
     */
    fun cleanup() {
        stopMonitoring()
        operationTimings.clear()
        scope.cancel()
    }
}
