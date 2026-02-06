package org.sada.messenger

import android.util.Log
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import java.io.*
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException

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

    /**
     * بدء الخادم وانتظار الاتصالات الواردة
     */
    fun startServer() {
        if (isConnected) {
            Log.w(TAG, "Already connected, cannot start server")
            return
        }

        serverJob = socketScope.launch {
            try {
                Log.d(TAG, "Starting server on port $PORT")
                
                // إغلاق أي socket موجود مسبقاً
                closeConnections()
                
                serverSocket = ServerSocket(PORT)
                isServer = true
                
                Log.d(TAG, "Server socket created, waiting for client...")
                notifyConnectionStatus("server_listening", "Server listening on port $PORT")
                
                // انتظار الاتصال (blocking)
                val socket = serverSocket?.accept()
                
                if (socket != null) {
                    Log.d(TAG, "Client connected: ${socket.remoteSocketAddress}")
                    setupSocket(socket)
                    notifyConnectionStatus("connected", "Client connected")
                }
            } catch (e: IOException) {
                Log.e(TAG, "Server error", e)
                notifyConnectionStatus("error", "Server error: ${e.message}")
                closeConnections()
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected server error", e)
                notifyConnectionStatus("error", "Unexpected error: ${e.message}")
                closeConnections()
            }
        }
    }

    /**
     * الاتصال بخادم على العنوان المحدد
     */
    fun connectToHost(hostAddress: String) {
        if (isConnected) {
            Log.w(TAG, "Already connected, cannot connect to host")
            return
        }

        socketScope.launch {
            try {
                Log.d(TAG, "Attempting to connect to host: $hostAddress:$PORT")
                
                // إغلاق أي socket موجود مسبقاً
                closeConnections()
                
                isServer = false
                var attempt = 0
                var connected = false
                
                while (attempt < MAX_RETRY_ATTEMPTS && !connected) {
                    attempt++
                    Log.d(TAG, "Connection attempt $attempt/$MAX_RETRY_ATTEMPTS")
                    
                    try {
                        val socket = Socket()
                        socket.connect(java.net.InetSocketAddress(hostAddress, PORT), 5000) // timeout 5 seconds
                        
                        Log.d(TAG, "Successfully connected to $hostAddress")
                        setupSocket(socket)
                        notifyConnectionStatus("connected", "Connected to $hostAddress")
                        connected = true
                    } catch (e: IOException) {
                        Log.w(TAG, "Connection attempt $attempt failed: ${e.message}")
                        
                        if (attempt < MAX_RETRY_ATTEMPTS) {
                            delay(RETRY_DELAY_MS)
                        } else {
                            Log.e(TAG, "Failed to connect after $MAX_RETRY_ATTEMPTS attempts")
                            notifyConnectionStatus("error", "Failed to connect: ${e.message}")
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected connection error", e)
                notifyConnectionStatus("error", "Unexpected error: ${e.message}")
                closeConnections()
            }
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
            
            Log.d(TAG, "Socket setup complete, starting read loop")
            
            // بدء حلقة القراءة
            startReadLoop()
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up socket", e)
            closeConnections()
        }
    }

    /**
     * بدء حلقة القراءة المستمرة
     */
    private fun startReadLoop() {
        readJob?.cancel()
        
        readJob = socketScope.launch {
            val buffer = ByteArray(4096)
            
            try {
                Log.d(TAG, "Read loop started")
                
                while (isConnected && !isCancelled) {
                    try {
                        val bytesRead = inputStream?.read(buffer) ?: -1
                        
                        if (bytesRead == -1) {
                            // انتهاء الاتصال
                            Log.d(TAG, "Peer disconnected (EOF)")
                            notifyConnectionStatus("disconnected", "Peer disconnected")
                            break
                        }
                        
                        if (bytesRead > 0) {
                            val messageBytes = buffer.copyOf(bytesRead)
                            val message = String(messageBytes, Charsets.UTF_8)
                            
                            Log.d(TAG, "Received message (${bytesRead} bytes): $message")
                            
                            // إرسال الرسالة إلى Flutter
                            messageEventSink?.success(message)
                        }
                    } catch (e: SocketException) {
                        Log.d(TAG, "Socket exception (likely disconnected): ${e.message}")
                        notifyConnectionStatus("disconnected", "Connection lost")
                        break
                    } catch (e: IOException) {
                        Log.e(TAG, "IO error in read loop", e)
                        notifyConnectionStatus("error", "IO error: ${e.message}")
                        break
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected error in read loop", e)
                notifyConnectionStatus("error", "Read error: ${e.message}")
            } finally {
                Log.d(TAG, "Read loop ended")
                closeConnections()
            }
        }
    }

    /**
     * كتابة البيانات إلى Socket
     */
    fun write(data: ByteArray): Boolean {
        return try {
            if (!isConnected || outputStream == null) {
                Log.w(TAG, "Cannot write: not connected")
                return false
            }
            
            outputStream?.write(data)
            outputStream?.flush()
            
            Log.d(TAG, "Wrote ${data.size} bytes")
            true
        } catch (e: IOException) {
            Log.e(TAG, "Error writing data", e)
            notifyConnectionStatus("error", "Write error: ${e.message}")
            closeConnections()
            false
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected write error", e)
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
        Log.d(TAG, "Closing connections")
        
        isConnected = false
        readJob?.cancel()
        serverJob?.cancel()
        
        try {
            inputStream?.close()
        } catch (e: Exception) {
            Log.w(TAG, "Error closing input stream", e)
        }
        
        try {
            outputStream?.close()
        } catch (e: Exception) {
            Log.w(TAG, "Error closing output stream", e)
        }
        
        try {
            clientSocket?.close()
        } catch (e: Exception) {
            Log.w(TAG, "Error closing client socket", e)
        }
        
        try {
            serverSocket?.close()
        } catch (e: Exception) {
            Log.w(TAG, "Error closing server socket", e)
        }
        
        inputStream = null
        outputStream = null
        clientSocket = null
        serverSocket = null
        
        Log.d(TAG, "Connections closed")
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
            }
            connectionStatusSink?.success(statusJson.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Error notifying connection status", e)
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
        Log.d(TAG, "Destroying SocketManager")
        closeConnections()
        socketScope.cancel()
    }
}

