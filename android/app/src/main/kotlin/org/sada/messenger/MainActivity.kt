package org.sada.messenger

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pDeviceList
import android.net.wifi.p2p.WifiP2pInfo
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterFragmentActivity() {
    private val TAG = "SadaMesh"
    private val METHOD_CHANNEL = "org.sada.messenger/mesh"
    private val PEERS_EVENT_CHANNEL = "org.sada.messenger/peersChanges"
    private val CONNECTION_EVENT_CHANNEL = "org.sada.messenger/connectionChanges"
    private val MESSAGE_EVENT_CHANNEL = "org.sada.messenger/messageReceived"
    private val SOCKET_STATUS_CHANNEL = "org.sada.messenger/socketStatus"

    private lateinit var wifiP2pManager: WifiP2pManager
    private lateinit var channel: WifiP2pManager.Channel
    private var peersEventSink: EventChannel.EventSink? = null
    private var connectionEventSink: EventChannel.EventSink? = null
    private var messageEventSink: EventChannel.EventSink? = null
    private var socketStatusSink: EventChannel.EventSink? = null

    private val peersList = mutableListOf<WifiP2pDevice>()
    private val socketManager = SocketManager.getInstance()

    // BroadcastReceiver لاستقبال أحداث WiFi P2P
    private val wifiP2pReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action ?: return

            when (action) {
                WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                    val state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1)
                    when (state) {
                        WifiP2pManager.WIFI_P2P_STATE_ENABLED -> {
                            Log.d(TAG, "WiFi P2P enabled")
                        }
                        else -> {
                            Log.d(TAG, "WiFi P2P disabled")
                        }
                    }
                }

                WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                    Log.d(TAG, "Peers changed")
                    wifiP2pManager.requestPeers(channel, peerListListener)
                }

                WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                    Log.d(TAG, "Connection changed")
                    val networkInfo = intent.getParcelableExtra<android.net.NetworkInfo>(
                        WifiP2pManager.EXTRA_NETWORK_INFO
                    )
                    if (networkInfo?.isConnected == true) {
                        wifiP2pManager.requestConnectionInfo(channel, connectionInfoListener)
                    } else {
                        // إرسال حالة انقطاع الاتصال
                        connectionEventSink?.success(
                            JSONObject().apply {
                                put("isConnected", false)
                            }.toString()
                        )
                    }
                }

                WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION -> {
                    val device = intent.getParcelableExtra<WifiP2pDevice>(
                        WifiP2pManager.EXTRA_WIFI_P2P_DEVICE
                    )
                    device?.let {
                        Log.d(TAG, "This device changed: ${it.deviceName} - ${it.deviceAddress}")
                    }
                }
            }
        }
    }

    // Listener لقائمة الأجهزة
    private val peerListListener = WifiP2pManager.PeerListListener { peers ->
        peersList.clear()
        peersList.addAll(peers.deviceList)
        Log.d(TAG, "Found ${peersList.size} peers")

        // إرسال قائمة الأجهزة إلى Flutter
        val peersJson = JSONArray()
        peersList.forEach { device ->
            peersJson.put(
                JSONObject().apply {
                    put("deviceName", device.deviceName ?: "Unknown")
                    put("deviceAddress", device.deviceAddress)
                    put("status", device.status)
                    put("isServiceDiscoveryCapable", device.isServiceDiscoveryCapable)
                }
            )
        }

        peersEventSink?.success(peersJson.toString())
    }

    // Listener لمعلومات الاتصال
    private val connectionInfoListener = WifiP2pManager.ConnectionInfoListener { info ->
        Log.d(TAG, "Connection info received")
        Log.d(TAG, "Group formed: ${info.groupFormed}")
        Log.d(TAG, "Is group owner: ${info.isGroupOwner}")
        Log.d(TAG, "Group owner address: ${info.groupOwnerAddress?.hostAddress}")
        
        val connectionJson = JSONObject().apply {
            put("isConnected", true)
            put("groupFormed", info.groupFormed)
            put("isGroupOwner", info.isGroupOwner)
            info.groupOwnerAddress?.let {
                put("groupOwnerAddress", it.hostAddress ?: "")
            }
        }
        connectionEventSink?.success(connectionJson.toString())
        
        // بدء Socket Manager بناءً على دور الجهاز
        if (info.groupFormed) {
            if (info.isGroupOwner) {
                // نحن Group Owner -> نبدأ Server
                Log.d(TAG, "Starting Socket Server (Group Owner)")
                socketManager.startServer()
            } else {
                // نحن Client -> نتصل بـ Group Owner
                info.groupOwnerAddress?.hostAddress?.let { hostAddress ->
                    Log.d(TAG, "Connecting to Group Owner: $hostAddress")
                    socketManager.connectToHost(hostAddress)
                } ?: run {
                    Log.e(TAG, "Group owner address is null, cannot connect")
                }
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // تهيئة WiFi P2P Manager
        wifiP2pManager = getSystemService(Context.WIFI_P2P_SERVICE) as WifiP2pManager
        channel = wifiP2pManager.initialize(this, mainLooper, null)

        // تسجيل BroadcastReceiver
        val intentFilter = IntentFilter().apply {
            addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
        }
        registerReceiver(wifiP2pReceiver, intentFilter)

        // MethodChannel للتحكم في Discovery
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startDiscovery" -> {
                        Log.d(TAG, "Starting WiFi P2P discovery")
                        wifiP2pManager.discoverPeers(channel, object : WifiP2pManager.ActionListener {
                            override fun onSuccess() {
                                Log.d(TAG, "Discovery started successfully")
                                result.success(true)
                            }

                            override fun onFailure(reasonCode: Int) {
                                Log.e(TAG, "Discovery failed: $reasonCode")
                                result.error("DISCOVERY_FAILED", "Failed to start discovery: $reasonCode", null)
                            }
                        })
                    }

                    "stopDiscovery" -> {
                        Log.d(TAG, "Stopping WiFi P2P discovery")
                        wifiP2pManager.stopPeerDiscovery(channel, object : WifiP2pManager.ActionListener {
                            override fun onSuccess() {
                                Log.d(TAG, "Discovery stopped successfully")
                                result.success(true)
                            }

                            override fun onFailure(reasonCode: Int) {
                                Log.e(TAG, "Stop discovery failed: $reasonCode")
                                result.error("STOP_FAILED", "Failed to stop discovery: $reasonCode", null)
                            }
                        })
                    }

                    "getPeers" -> {
                        Log.d(TAG, "Getting current peers list")
                        val peersJson = JSONArray()
                        peersList.forEach { device ->
                            peersJson.put(
                                JSONObject().apply {
                                    put("deviceName", device.deviceName ?: "Unknown")
                                    put("deviceAddress", device.deviceAddress)
                                    put("status", device.status)
                                    put("isServiceDiscoveryCapable", device.isServiceDiscoveryCapable)
                                }
                            )
                        }
                        result.success(peersJson.toString())
                    }

                    "sendMessage" -> {
                        val message = call.argument<String>("message")
                        if (message != null) {
                            Log.d(TAG, "Sending message: $message")
                            val success = socketManager.writeText(message)
                            result.success(success)
                        } else {
                            result.error("INVALID_ARGUMENT", "Message is null", null)
                        }
                    }

                    "closeSocket" -> {
                        Log.d(TAG, "Closing socket connection")
                        socketManager.closeConnections()
                        result.success(true)
                    }

                    "getApkPath" -> {
                        try {
                            val apkPath = applicationInfo.sourceDir
                            Log.d(TAG, "APK path: $apkPath")
                            result.success(apkPath)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error getting APK path", e)
                            result.error("APK_PATH_ERROR", "Failed to get APK path: ${e.message}", null)
                        }
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }

        // EventChannel لتحديثات الأجهزة
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PEERS_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "Peers event channel listener attached")
                    peersEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "Peers event channel listener cancelled")
                    peersEventSink = null
                }
            })

        // EventChannel لتحديثات الاتصال
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CONNECTION_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "Connection event channel listener attached")
                    connectionEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "Connection event channel listener cancelled")
                    connectionEventSink = null
                }
            })

        // EventChannel للرسائل المستلمة من Socket
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, MESSAGE_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "Message event channel listener attached")
                    messageEventSink = events
                    socketManager.setMessageEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "Message event channel listener cancelled")
                    messageEventSink = null
                    socketManager.setMessageEventSink(null)
                }
            })

        // EventChannel لحالة Socket
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SOCKET_STATUS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "Socket status event channel listener attached")
                    socketStatusSink = events
                    socketManager.setConnectionStatusSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "Socket status event channel listener cancelled")
                    socketStatusSink = null
                    socketManager.setConnectionStatusSink(null)
                }
            })

        Log.d(TAG, "MainActivity configured successfully")
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(wifiP2pReceiver)
            Log.d(TAG, "BroadcastReceiver unregistered")
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver", e)
        }
        
        // تنظيف SocketManager
        socketManager.destroy()
        Log.d(TAG, "SocketManager destroyed")
    }
}

