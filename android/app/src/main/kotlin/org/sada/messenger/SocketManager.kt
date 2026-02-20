package org.sada.messenger

import android.util.Log
import io.flutter.plugin.common.EventChannel
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
        private const val TAG = "SadaSocket"
        private const val PORT = 8888
        private const val MAX_RETRY_ATTEMPTS = 3
        private const val RETRY_DELAY_MS = 500L
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
    
    private var messageEventSink: EventChannel.EventSink? = null
    private var connectionStatusSink: EventChannel.EventSink? = null
    
    private val socketScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var readJob: Job? = null
    private var serverJob: Job? = null
    
    private var isConnected = false
    private var isServer = false
    private val currentPeerId = AtomicReference("unknown")

    private fun peerTag(): String = "[peer=${currentPeerId.get()}]"

    /**
     * تعيين EventSink لإرسال الرسائل المستلمة إلى Flutter
     */
    fun setMessageEventSink(sink: EventChannel.EventSink?) {
        messageEventSink = sink
        Log.d(TAG, "Message event sink set")
    }

    /**
     * تعيين EventSink لإرسال حالة الاتصال إلى Flutter
     */
    fun setConnectionStatusSink(sink: EventChannel.EventSink?) {
        connectionStatusSink = sink
        Log.d(TAG, "Connection status sink set")
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
                Log.d(TAG, "${peerTag()} Starting server on port $PORT")

                // Keep server listener alive, only close active client connection if needed.
                closeActiveClientConnection()
                serverSocket = ServerSocket(PORT)
                isServer = true
                
                Log.d(TAG, "${peerTag()} Server socket created, waiting for clients...")
                notifyConnectionStatus("server_listening", "Server listening on port $PORT")

                while (isActive && serverSocket?.isClosed == false) {
                    val socket = serverSocket?.accept() ?: break
                    Log.d(
                        TAG,
                        "${peerTag()} Client connected: ${socket.remoteSocketAddress}"
                    )
                    setupSocket(socket)
                    notifyConnectionStatus("connected", "Client connected")
                }
            } catch (e: IOException) {
                Log.e(TAG, "${peerTag()} Server error", e)
                notifyConnectionStatus("error", "Server error: ${e.message}")
                closeActiveClientConnection()
            } catch (e: Exception) {
                Log.e(TAG, "${peerTag()} Unexpected server error", e)
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
            Log.d(TAG, "${peerTag()} Attempting to connect to host: $hostAddress:$PORT")
            closeActiveClientConnection()

            isServer = false
            var attempt = 0
            while (attempt < MAX_RETRY_ATTEMPTS) {
                attempt++
                Log.d(TAG, "${peerTag()} Connection attempt $attempt/$MAX_RETRY_ATTEMPTS")
                try {
                    val socket = Socket()
                    socket.connect(java.net.InetSocketAddress(hostAddress, PORT), 5000)
                    Log.d(TAG, "${peerTag()} Successfully connected to $hostAddress")
                    setupSocket(socket)
                    notifyConnectionStatus("connected", "Connected to $hostAddress")
                    return true
                } catch (e: IOException) {
                    Log.w(TAG, "${peerTag()} Connection attempt $attempt failed: ${e.message}")
                    if (attempt < MAX_RETRY_ATTEMPTS) {
                        delay(RETRY_DELAY_MS * (1L shl (attempt - 1)))
                    } else {
                        Log.e(TAG, "${peerTag()} Failed to connect after $MAX_RETRY_ATTEMPTS attempts")
                        notifyConnectionStatus("error", "Failed to connect: ${e.message}")
                    }
                }
            }
            false
        } catch (e: Exception) {
            Log.e(TAG, "${peerTag()} Unexpected connection error", e)
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
            
            Log.d(TAG, "${peerTag()} Socket setup complete, starting read loop")
            
            // بدء حلقة القراءة
            startReadLoop()
        } catch (e: Exception) {
            Log.e(TAG, "${peerTag()} Error setting up socket", e)
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
                Log.d(TAG, "${peerTag()} Read loop started")
                
                while (isConnected && coroutineContext.isActive) {
                    try {
                        val bytesRead = inputStream?.read(buffer) ?: -1
                        
                        if (bytesRead == -1) {
                            // انتهاء الاتصال
                            Log.d(TAG, "${peerTag()} Peer disconnected (EOF)")
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
                        Log.d(TAG, "${peerTag()} Socket exception (likely disconnected): ${e.message}")
                        notifyConnectionStatus("disconnected", "Connection lost")
                        break
                    } catch (e: IOException) {
                        Log.e(TAG, "${peerTag()} IO error in read loop", e)
                        notifyConnectionStatus("error", "IO error: ${e.message}")
                        break
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "${peerTag()} Unexpected error in read loop", e)
                notifyConnectionStatus("error", "Read error: ${e.message}")
            } finally {
                Log.d(TAG, "${peerTag()} Read loop ended")
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
                Log.e(TAG, "${peerTag()} Invalid frame size: $messageSize")
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
            val message = String(messageBytes, Charsets.UTF_8)

            Log.d(TAG, "${peerTag()} 📥 [READ] Received frame: $messageSize bytes payload.")
            Log.v(TAG, "   Payload content: ${message.take(200)}")
            messageEventSink?.success(message)

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
                Log.w(TAG, "${peerTag()} Cannot write: not connected")
                return false
            }

            if (data.isEmpty()) {
                Log.w(TAG, "${peerTag()} Cannot write: empty payload")
                return false
            }

            if (data.size > MAX_MESSAGE_SIZE_BYTES) {
                Log.e(TAG, "${peerTag()} Cannot write: payload too large (${data.size} bytes)")
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

            Log.d(TAG, "${peerTag()} 📤 [WRITE] Sent frame: ${data.size} bytes payload + 4 bytes header. Total: ${framed.size} bytes.")
            Log.v(TAG, "   Payload context: ${String(data, Charsets.UTF_8).take(200)}")
            true
        } catch (e: IOException) {
            Log.e(TAG, "${peerTag()} Error writing data", e)
            notifyConnectionStatus("error", "Write error: ${e.message}")
            closeActiveClientConnection()
            false
        } catch (e: Exception) {
            Log.e(TAG, "${peerTag()} Unexpected write error", e)
            false
        }
    }

    /**
     * كتابة نص (String) إلى Socket
     */
    fun writeText(text: String): Boolean {
        return write(text.toByteArray(Charsets.UTF_8))
    }

    /**
     * إغلاق جميع الاتصالات
     */
    fun closeConnections() {
        Log.d(TAG, "${peerTag()} Closing all connections")
        
        closeActiveClientConnection()

        serverJob?.cancel()
        try {
            serverSocket?.close()
        } catch (e: Exception) {
            Log.w(TAG, "${peerTag()} Error closing server socket", e)
        }
        serverSocket = null

        Log.d(TAG, "${peerTag()} All connections closed")
    }

    private fun closeActiveClientConnection() {
        isConnected = false
        readJob?.cancel()

        try {
            inputStream?.close()
        } catch (e: Exception) {
            Log.w(TAG, "${peerTag()} Error closing input stream", e)
        }
        try {
            outputStream?.close()
        } catch (e: Exception) {
            Log.w(TAG, "${peerTag()} Error closing output stream", e)
        }
        try {
            clientSocket?.close()
        } catch (e: Exception) {
            Log.w(TAG, "${peerTag()} Error closing client socket", e)
        }

        inputStream = null
        outputStream = null
        clientSocket = null
    }

    /**
     * إرسال حالة الاتصال إلى Flutter
     */
    private fun notifyConnectionStatus(status: String, message: String) {
        try {
            val statusJson = org.json.JSONObject().apply {
                put("status", status)
                put("message", message)
                put("isConnected", isConnected)
                put("isServer", isServer)
                put("peerId", currentPeerId.get())
                put("remoteAddress", clientSocket?.remoteSocketAddress?.toString() ?: "")
            }
            connectionStatusSink?.success(statusJson.toString())
        } catch (e: Exception) {
            Log.e(TAG, "${peerTag()} Error notifying connection status", e)
        }
    }

    /**
     * التحقق من حالة الاتصال
     */
    fun isSocketConnected(): Boolean {
        return isConnected && clientSocket?.isConnected == true
    }

    /**
     * تنظيف الموارد عند التدمير
     */
    fun destroy() {
        Log.d(TAG, "${peerTag()} Destroying SocketManager")
        closeConnections()
        socketScope.cancel()
    }
}
