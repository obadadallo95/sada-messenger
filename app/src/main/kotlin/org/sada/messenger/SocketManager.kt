package org.sada.messenger

import org.sada.messenger.security.SecureLogger
import kotlinx.coroutines.*
import java.io.*
import java.nio.ByteBuffer
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException
import java.util.concurrent.atomic.AtomicReference

/**
 * مدير Socket لإدارة الاتصالات TCP في شبكة Mesh
 * يدعم وضعي Server و Client
 */
class SocketManager private constructor() {
    companion object {
        private const val TAG = "Socket"
        private const val PORT = 8888
        private const val MAX_RETRY_ATTEMPTS = 5
        private const val RETRY_DELAY_MS = 1000L
        private const val FRAME_HEADER_SIZE_BYTES = 4
        private const val MAX_MESSAGE_SIZE_BYTES = 1024 * 1024 // 1 MB
        
        @Volatile
        private var INSTANCE: SocketManager? = null
        
        fun getInstance(): SocketManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: SocketManager().also { INSTANCE = it }
            }
        }
    }

    private var serverSocket: ServerSocket? = null
    private var clientSocket: Socket? = null
    private var inputStream: InputStream? = null
    private var outputStream: OutputStream? = null
    
    // TODO: Replace with StateFlow or standard callbacks for Native UI
    private var onMessageReceived: ((ByteArray) -> Unit)? = null
    private var onConnectionStatusChanged: ((String, String) -> Unit)? = null
    
    private val socketScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var readJob: Job? = null
    private var serverJob: Job? = null
    
    private var isConnected = false
    private var isServer = false
    private val currentPeerId = AtomicReference("unknown")

    // Diagnostics tracking
    private var lastRetryAttempts = 0
    private var lastConnectDelayMs = 0L
    private var serverReadyAtMs = 0L

    private fun peerTag(): String = "[peer=${currentPeerId.get()}]"

    fun setOnMessageReceived(callback: (ByteArray) -> Unit) {
        onMessageReceived = callback
    }

    fun setOnConnectionStatusChanged(callback: (String, String) -> Unit) {
        onConnectionStatusChanged = callback
    }

    fun clearCallbacks() {
        onMessageReceived = null
        onConnectionStatusChanged = null
    }

    fun setCurrentPeerId(peerId: String?) {
        if (!peerId.isNullOrBlank()) {
            currentPeerId.set(peerId)
        }
    }

    /**
     * بدء الخادم وانتظار الاتصالات الواردة
     */
    fun startServer() {
        if (serverSocket?.isClosed == false) return

        serverJob = socketScope.launch {
            try {
                SecureLogger.d(TAG, "${peerTag()} Starting server on port $PORT")

                // Keep server listener alive, only close active client connection if needed.
                closeActiveClientConnection()
                serverSocket = ServerSocket(PORT)
                isServer = true
                serverReadyAtMs = System.currentTimeMillis()
                
                SecureLogger.d(TAG, "${peerTag()} Server socket created, waiting for clients...")
                notifyConnectionStatus("server_listening", "Server listening on port $PORT")

                while (isActive && serverSocket?.isClosed == false) {
                    val socket = serverSocket?.accept() ?: break
                    SecureLogger.d(TAG, "${peerTag()} Client connected: ${socket.remoteSocketAddress}")
                    setupSocket(socket)
                    notifyConnectionStatus("connected", "Client connected")
                }
            } catch (e: IOException) {
                SecureLogger.e(TAG, "${peerTag()} Server error", e)
                notifyConnectionStatus("error", "Server error: ${e.message}")
                closeActiveClientConnection()
            } catch (e: Exception) {
                SecureLogger.e(TAG, "${peerTag()} Unexpected server error", e)
                notifyConnectionStatus("error", "Unexpected error: ${e.message}")
                closeActiveClientConnection()
            }
        }
    }

    /**
     * الاتصال بخادم على العنوان المحدد
     */
    fun connectToHost(hostAddress: String) {
        socketScope.launch {
            connectToHostAndWait(hostAddress, currentPeerId.get())
        }
    }

    suspend fun connectToHostAndWait(hostAddress: String, peerId: String?): Boolean {
        if (!peerId.isNullOrBlank()) currentPeerId.set(peerId)

        return try {
            currentCoroutineContext().ensureActive()
            SecureLogger.d(TAG, "${peerTag()} Attempting to connect to host: $hostAddress:$PORT")
            closeActiveClientConnection()

            isServer = false
            var attempt = 0
            lastRetryAttempts = 0
            while (attempt < MAX_RETRY_ATTEMPTS) {
                attempt++
                lastRetryAttempts = attempt
                SecureLogger.d(TAG, "${peerTag()} Connection attempt $attempt/$MAX_RETRY_ATTEMPTS")
                try {
                    val socket = Socket()
                    try {
                        socket.connect(java.net.InetSocketAddress(hostAddress, PORT), 5000)
                        currentCoroutineContext().ensureActive()
                    } catch (e: CancellationException) {
                        runCatching { socket.close() }
                        throw e
                    }
                    SecureLogger.d(TAG, "${peerTag()} Successfully connected to $hostAddress")
                    setupSocket(socket)
                    notifyConnectionStatus("connected", "Connected to $hostAddress")
                    return true
                } catch (e: IOException) {
                    SecureLogger.w(TAG, "${peerTag()} Connection attempt $attempt failed: ${e.message}")
                    if (attempt < MAX_RETRY_ATTEMPTS) {
                        val delayMs = RETRY_DELAY_MS * (1L shl (attempt - 1))
                        lastConnectDelayMs = delayMs
                        SecureLogger.d(TAG, "${peerTag()} Waiting ${delayMs}ms before retry...")
                        delay(delayMs)
                    } else {
                        SecureLogger.e(TAG, "${peerTag()} Failed to connect after $MAX_RETRY_ATTEMPTS attempts")
                        notifyConnectionStatus("error", "Failed to connect: ${e.message}")
                    }
                }
            }
            false
        } catch (e: CancellationException) {
            closeActiveClientConnection()
            throw e
        } catch (e: Exception) {
            SecureLogger.e(TAG, "${peerTag()} Unexpected connection error", e)
            notifyConnectionStatus("error", "Unexpected error: ${e.message}")
            closeActiveClientConnection()
            false
        }
    }

    /**
     * إعداد Socket وبدء حلقة القراءة
     */
    private fun setupSocket(socket: Socket) {
        try {
            clientSocket = socket
            inputStream = socket.getInputStream()
            outputStream = socket.getOutputStream()
            isConnected = true
            
            SecureLogger.d(TAG, "${peerTag()} Socket setup complete, starting read loop")
            
            // بدء حلقة القراءة
            startReadLoop()
        } catch (e: Exception) {
            SecureLogger.e(TAG, "${peerTag()} Error setting up socket", e)
            closeActiveClientConnection()
        }
    }

    /**
     * بدء حلقة القراءة المستمرة
     */
    private fun startReadLoop() {
        readJob?.cancel()
        
        readJob = socketScope.launch {
            val buffer = ByteArray(4096)
            val receiveBuffer = ByteArrayOutputStream()
            
            try {
                SecureLogger.d(TAG, "${peerTag()} Read loop started")
                
                while (isConnected && coroutineContext.isActive) {
                    try {
                        val bytesRead = inputStream?.read(buffer) ?: -1
                        
                        if (bytesRead == -1) {
                            // انتهاء الاتصال
                            SecureLogger.d(TAG, "${peerTag()} Peer disconnected (EOF)")
                            notifyConnectionStatus("disconnected", "Peer disconnected")
                            break
                        }
                        
                        if (bytesRead > 0) {
                            receiveBuffer.write(buffer, 0, bytesRead)
                            val parseOk = processIncomingFrames(receiveBuffer)
                            if (!parseOk) {
                                notifyConnectionStatus("error", "Invalid frame format")
                                break
                            }
                        }
                    } catch (e: SocketException) {
                        SecureLogger.d(TAG, "${peerTag()} Socket exception (likely disconnected): ${e.message}")
                        notifyConnectionStatus("disconnected", "Connection lost")
                        break
                    } catch (e: IOException) {
                        SecureLogger.e(TAG, "${peerTag()} IO error in read loop", e)
                        notifyConnectionStatus("error", "IO error: ${e.message}")
                        break
                    }
                }
            } catch (e: Exception) {
                SecureLogger.e(TAG, "${peerTag()} Unexpected error in read loop", e)
                notifyConnectionStatus("error", "Read error: ${e.message}")
            } finally {
                SecureLogger.d(TAG, "${peerTag()} Read loop ended")
                closeActiveClientConnection()
            }
        }
    }

    /**
     * Parsing loop for length-prefixed frames.
     * Frame format: 4-byte big-endian length + UTF-8 payload.
     */
    private fun processIncomingFrames(receiveBuffer: ByteArrayOutputStream): Boolean {
        val data = receiveBuffer.toByteArray()
        var offset = 0

        while (data.size - offset >= FRAME_HEADER_SIZE_BYTES) {
            val messageSize = ByteBuffer.wrap(
                data,
                offset,
                FRAME_HEADER_SIZE_BYTES
            ).int

            if (messageSize <= 0 || messageSize > MAX_MESSAGE_SIZE_BYTES) {
                SecureLogger.e(TAG, "${peerTag()} Invalid frame size: $messageSize")
                return false
            }

            val frameSize = FRAME_HEADER_SIZE_BYTES + messageSize
            if (data.size - offset < frameSize) {
                // Incomplete frame, wait for more bytes.
                break
            }

            val payloadStart = offset + FRAME_HEADER_SIZE_BYTES
            val payloadEnd = payloadStart + messageSize
            val messageBytes = data.copyOfRange(payloadStart, payloadEnd)

            SecureLogger.d(TAG, "${peerTag()} 📥 [READ] Received frame: $messageSize bytes payload.")
            onMessageReceived?.invoke(messageBytes)

            offset += frameSize
        }

        if (offset > 0) {
            // Keep only unparsed tail bytes.
            val remaining = data.copyOfRange(offset, data.size)
            receiveBuffer.reset()
            if (remaining.isNotEmpty()) {
                receiveBuffer.write(remaining)
            }
        }

        return true
    }

    /**
     * كتابة البيانات إلى Socket
     */
    fun write(data: ByteArray): Boolean {
        return try {
            if (!isConnected || outputStream == null) {
                SecureLogger.w(TAG, "${peerTag()} Cannot write: not connected")
                return false
            }

            if (data.isEmpty()) {
                SecureLogger.w(TAG, "${peerTag()} Cannot write: empty payload")
                return false
            }

            if (data.size > MAX_MESSAGE_SIZE_BYTES) {
                SecureLogger.e(TAG, "${peerTag()} Cannot write: payload too large (${data.size} bytes)")
                return false
            }

            val framed = ByteBuffer.allocate(FRAME_HEADER_SIZE_BYTES + data.size)
                .putInt(data.size)
                .put(data)
                .array()

            synchronized(this) {
                outputStream?.write(framed)
                outputStream?.flush()
            }

            SecureLogger.d(TAG, "${peerTag()} 📤 [WRITE] Sent frame: ${data.size} bytes payload + 4 bytes header. Total: ${framed.size} bytes.")
            true
        } catch (e: IOException) {
            SecureLogger.e(TAG, "${peerTag()} Error writing data", e)
            notifyConnectionStatus("error", "Write error: ${e.message}")
            closeActiveClientConnection()
            false
        } catch (e: Exception) {
            SecureLogger.e(TAG, "${peerTag()} Unexpected write error", e)
            false
        }
    }

    /**
     * كتابة نص (String) إلى Socket
     */
    fun writeText(text: String): Boolean {
        val textBytes = text.toByteArray(Charsets.UTF_8)
        val framed = java.nio.ByteBuffer.allocate(1 + textBytes.size)
            .put(0x00.toByte())
            .put(textBytes)
            .array()
        return write(framed)
    }

    /**
     * إغلاق جميع الاتصالات
     */
    fun closeConnections() {
        SecureLogger.d(TAG, "${peerTag()} Closing all connections")
        
        closeActiveClientConnection()

        serverJob?.cancel()
        try {
            serverSocket?.close()
        } catch (e: Exception) {
            SecureLogger.w(TAG, "${peerTag()} Error closing server socket", e)
        }
        serverSocket = null

        SecureLogger.d(TAG, "${peerTag()} All connections closed")
    }

    private fun closeActiveClientConnection() {
        isConnected = false
        readJob?.cancel()

        try {
            inputStream?.close()
        } catch (e: Exception) {
            SecureLogger.w(TAG, "${peerTag()} Error closing input stream", e)
        }
        try {
            outputStream?.close()
        } catch (e: Exception) {
            SecureLogger.w(TAG, "${peerTag()} Error closing output stream", e)
        }
        try {
            clientSocket?.close()
        } catch (e: Exception) {
            SecureLogger.w(TAG, "${peerTag()} Error closing client socket", e)
        }

        inputStream = null
        outputStream = null
        clientSocket = null
    }

    /**
     * إرسال حالة الاتصال إلى النظام
     */
    private fun notifyConnectionStatus(status: String, message: String) {
        onConnectionStatusChanged?.invoke(status, message)
    }

    /**
     * التحقق من حالة الاتصال
     */
    fun isSocketConnected(): Boolean {
        return isConnected && clientSocket?.isConnected == true
    }

    fun getDiagnosticsInfo(): Map<String, Any> {
        return mapOf(
            "retryAttempts" to lastRetryAttempts,
            "lastConnectDelay" to "${lastConnectDelayMs}ms",
            "serverReadyAt" to serverReadyAtMs
        )
    }

    /**
     * تنظيف الموارد عند التدمير
     */
    fun destroy() {
        SecureLogger.d(TAG, "${peerTag()} Destroying SocketManager")
        closeConnections()
        socketScope.cancel()
    }
}
