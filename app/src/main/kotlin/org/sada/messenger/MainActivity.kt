package org.sada.messenger

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pManager
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.compose.*
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.viewmodel.compose.viewModel
import org.sada.messenger.ui.theme.SadaTheme
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.security.KeyManager
import org.sada.messenger.security.EncryptionManager
import org.sada.messenger.network.MeshEngine
import org.sada.messenger.ui.viewmodels.SadaViewModelFactory
import org.sada.messenger.ui.viewmodels.HomeViewModel
import org.sada.messenger.ui.viewmodels.CrisisReportViewModel
import org.sada.messenger.ui.screens.HomeScreen
import org.sada.messenger.ui.screens.ChatScreen
import org.sada.messenger.ui.screens.OnboardingScreen
import org.sada.messenger.ui.screens.RegisterScreen
import org.sada.messenger.ui.screens.CrisisReportScreen
import org.sada.messenger.ui.screens.SettingsScreen
import org.sada.messenger.ui.screens.MyQrScreen
import org.sada.messenger.ui.screens.ContactsScreen
import org.sada.messenger.ui.viewmodels.ContactsViewModel
import org.sada.messenger.ui.screens.CreateGroupScreen
import org.sada.messenger.ui.screens.MeshDiagnosticsScreen
import org.sada.messenger.network.lora.LoraSerialManager
import org.sada.messenger.managers.UdpBroadcastManager
import org.sada.messenger.managers.VideoEngine
import org.sada.messenger.managers.AudioRecorderManager
import org.sada.messenger.ui.screens.GroupsScreen
import org.sada.messenger.ui.navigation.SadaBottomBar
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private val TAG = "SadaMesh"
    private val DISCOVERY_PREFIX = "SADA_DISCOVERY"
    private val DISCOVERY_VERSION = "v1"
    private val DISCOVERY_INTERVAL_MS = 15000L
    private val CONNECT_RETRY_COOLDOWN_MS = 10000L
    private val TCP_PORT = 8888
    
    private lateinit var wifiP2pManager: WifiP2pManager
    private lateinit var channel: WifiP2pManager.Channel
    private val socketManager = SocketManager.getInstance()
    private lateinit var udpBroadcastManager: UdpBroadcastManager
    
    private lateinit var database: AppDatabase
    private lateinit var keyManager: KeyManager
    private lateinit var encryptionManager: EncryptionManager
    private lateinit var meshEngine: MeshEngine
    private lateinit var videoEngine: VideoEngine
    private lateinit var audioRecorderManager: AudioRecorderManager
    private lateinit var viewModelFactory: SadaViewModelFactory

    private val peersList = mutableStateListOf<WifiP2pDevice>()
    private var discoveryJob: Job? = null
    private val lastConnectAttemptAt = mutableMapOf<String, Long>()
    private var myPeerId: String = ""

    private val wifiP2pReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action ?: return
            when (action) {
                WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                    val state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1)
                    Log.d(TAG, "WiFi P2P State: $state")
                }
                WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                    wifiP2pManager.requestPeers(channel) { peers ->
                        peersList.clear()
                        peersList.addAll(peers.deviceList)
                    }
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        database = AppDatabase.getDatabase(this)
        keyManager = KeyManager(this)
        encryptionManager = EncryptionManager(keyManager)
        
        wifiP2pManager = getSystemService(Context.WIFI_P2P_SERVICE) as WifiP2pManager
        channel = wifiP2pManager.initialize(this, mainLooper, null)
        udpBroadcastManager = UdpBroadcastManager.getInstance(this)
        
        val loraManager = LoraSerialManager(this)
        meshEngine = MeshEngine(this, socketManager, database, keyManager, encryptionManager, loraManager)
        videoEngine = VideoEngine(this)
        audioRecorderManager = AudioRecorderManager(this)
        socketManager.startServer()
        loraManager.start()
        
        viewModelFactory = SadaViewModelFactory(
            database, 
            meshEngine, 
            keyManager, 
            encryptionManager,
            videoEngine,
            audioRecorderManager
        )

        // Register Receiver
        val intentFilter = IntentFilter().apply {
            addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
        }
        registerReceiver(wifiP2pReceiver, intentFilter)

        // Local State for Onboarding/Registration
        val prefs = getSharedPreferences("sada_app_state", Context.MODE_PRIVATE)
        val isRegistered = try { keyManager.getKeyPair().publicKey.asBytes.isNotEmpty() && prefs.getString("user_nickname", null) != null } catch(e: Exception) { false }
        myPeerId = keyManager.getPublicKeyBase64()
        if (isRegistered) {
            startUdpDiscovery()
        }

        setContent {
            SadaTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    val navController = rememberNavController()
                    val navBackStackEntry by navController.currentBackStackEntryAsState()
                    val currentRoute = navBackStackEntry?.destination?.route
                    
                    val mainRoutes = listOf("home", "chats", "groups", "contacts", "settings")
                    val showBottomBar = currentRoute in mainRoutes
                    
                    val startDestination = if (isRegistered) "home" else "onboarding"
                    
                    Scaffold(
                        bottomBar = {
                            if (showBottomBar) {
                                SadaBottomBar(
                                    currentRoute = currentRoute,
                                    onNavigate = { route ->
                                        navController.navigate(route) {
                                            popUpTo("home") { saveState = true }
                                            launchSingleTop = true
                                            restoreState = true
                                        }
                                    }
                                )
                            }
                        }
                    ) { innerPadding ->
                        NavHost(
                            navController = navController, 
                            startDestination = startDestination,
                            modifier = Modifier.padding(innerPadding)
                        ) {
                            composable("onboarding") {
                                OnboardingScreen(onComplete = {
                                    navController.navigate("register") {
                                        popUpTo("onboarding") { inclusive = true }
                                    }
                                })
                            }
                            composable("register") {
                                RegisterScreen(keyManager = keyManager, onComplete = { nickname ->
                                    prefs.edit().putString("user_nickname", nickname).apply()
                                    navController.navigate("home") {
                                        popUpTo("register") { inclusive = true }
                                    }
                                })
                            }
                            composable("home") {
                                val homeViewModel: HomeViewModel = viewModel(factory = viewModelFactory)
                                HomeScreen(
                                    viewModel = homeViewModel,
                                    onChatClick = { chatId -> navController.navigate("chat/$chatId") },
                                    onSettingsClick = { navController.navigate("settings") },
                                    onCreateGroupClick = { navController.navigate("create_group") },
                                    onDiagnosticsClick = { navController.navigate("diagnostics") }
                                )
                            }
                            composable("chats") {
                                val homeViewModel: HomeViewModel = viewModel(factory = viewModelFactory)
                                HomeScreen(
                                    viewModel = homeViewModel,
                                    onChatClick = { chatId -> navController.navigate("chat/$chatId") },
                                    onSettingsClick = { navController.navigate("settings") },
                                    onCreateGroupClick = { navController.navigate("create_group") },
                                    onDiagnosticsClick = { navController.navigate("diagnostics") }
                                )
                            }
                            composable("groups") {
                                val homeViewModel: HomeViewModel = viewModel(factory = viewModelFactory)
                                GroupsScreen(
                                    viewModel = homeViewModel,
                                    onGroupClick = { chatId -> navController.navigate("chat/$chatId") },
                                    onCreateGroupClick = { navController.navigate("create_group") }
                                )
                            }
                            composable("settings") {
                                SettingsScreen(
                                    onBack = { navController.popBackStack() },
                                    onMyQrClick = { navController.navigate("my_qr") }
                                )
                            }
                            composable("my_qr") {
                                val userNickname = prefs.getString("user_nickname", "User") ?: "User"
                                val pubKey = keyManager.getKeyPair().publicKey.asHexString
                                MyQrScreen(
                                    nickname = userNickname,
                                    publicKey = pubKey,
                                    onBack = { navController.popBackStack() }
                                )
                            }
                            composable("create_group") {
                                val contactsViewModel: ContactsViewModel = viewModel(factory = viewModelFactory)
                                val homeViewModel: HomeViewModel = viewModel(factory = viewModelFactory)
                                CreateGroupScreen(
                                    viewModel = contactsViewModel,
                                    onCreateGroup = { name, members ->
                                        homeViewModel.createGroup(name, members)
                                        navController.popBackStack()
                                    },
                                    onBack = { navController.popBackStack() }
                                )
                            }
                            composable("contacts") {
                                val contactsViewModel: ContactsViewModel = viewModel(factory = viewModelFactory)
                                ContactsScreen(
                                    viewModel = contactsViewModel,
                                    onContactClick = { chatId ->
                                        navController.navigate("chat/$chatId") {
                                            popUpTo("home")
                                        }
                                    },
                                    onBack = { navController.popBackStack() }
                                )
                            }
                            composable("chat/{chatId}") { backStackEntry ->
                                val chatId = backStackEntry.arguments?.getString("chatId") ?: return@composable
                                val chatViewModel = viewModelFactory.createChatViewModel(chatId)
                                
                                // Handle result from CrisisReportScreen
                                val reportPath = backStackEntry.savedStateHandle.get<String>("report_file")
                                LaunchedEffect(reportPath) {
                                    reportPath?.let {
                                        chatViewModel.sendMediaMessage(java.io.File(it), "video/mp4")
                                        backStackEntry.savedStateHandle.remove<String>("report_file")
                                    }
                                }

                                ChatScreen(
                                    viewModel = chatViewModel,
                                    chatName = "Chat ${chatId.take(6)}",
                                    onBackClick = { navController.popBackStack() },
                                    onCrisisReportClick = { navController.navigate("crisis_report/$chatId") }
                                )
                            }
                            composable("diagnostics") {
                                MeshDiagnosticsScreen(
                                    meshEngine = meshEngine,
                                    onBack = { navController.popBackStack() }
                                )
                            }
                            composable("crisis_report/{chatId}") { backStackEntry ->
                                val chatId = backStackEntry.arguments?.getString("chatId") ?: return@composable
                                val crisisViewModel: CrisisReportViewModel = viewModel(factory = viewModelFactory)
                                CrisisReportScreen(
                                    viewModel = crisisViewModel,
                                    onReportGenerated = { file: java.io.File ->
                                        navController.previousBackStackEntry?.savedStateHandle?.set("report_file", file.absolutePath)
                                        navController.popBackStack()
                                    },
                                    onBack = { navController.popBackStack() }
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        discoveryJob?.cancel()
        try {
            unregisterReceiver(wifiP2pReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver", e)
        }
        socketManager.destroy()
        udpBroadcastManager.destroy()
    }

    private fun startUdpDiscovery() {
        val started = udpBroadcastManager.startListening()
        if (!started) {
            Log.e(TAG, "UDP discovery failed to start")
            return
        }

        udpBroadcastManager.setOnPacketReceived { payload, senderIp ->
            handleUdpDiscoveryPacket(payload, senderIp)
        }

        discoveryJob?.cancel()
        discoveryJob = lifecycleScope.launch(Dispatchers.IO) {
            while (isActive) {
                val packet = "$DISCOVERY_PREFIX|$DISCOVERY_VERSION|$myPeerId|$TCP_PORT"
                udpBroadcastManager.sendBroadcast(packet)
                delay(DISCOVERY_INTERVAL_MS)
            }
        }

        Log.d(TAG, "UDP discovery started for peer: ${myPeerId.take(12)}...")
    }

    private fun handleUdpDiscoveryPacket(payload: String, senderIp: String) {
        val parts = payload.split("|")
        if (parts.size < 4) return
        if (parts[0] != DISCOVERY_PREFIX) return

        val peerId = parts[2].trim()
        if (peerId.isBlank() || peerId == myPeerId) return

        // Deterministic role rule: smaller ID waits inbound as server.
        val iAmServerPreferred = myPeerId < peerId
        if (iAmServerPreferred) {
            return
        }

        val attemptKey = "$peerId@$senderIp"
        val now = System.currentTimeMillis()
        val last = lastConnectAttemptAt[attemptKey] ?: 0L
        if (now - last < CONNECT_RETRY_COOLDOWN_MS) return
        lastConnectAttemptAt[attemptKey] = now

        if (socketManager.isSocketConnected()) return

        lifecycleScope.launch(Dispatchers.IO) {
            try {
                socketManager.setCurrentPeerId(peerId)
                val connected = socketManager.connectToHostAndWait(senderIp, peerId)
                Log.d(
                    TAG,
                    "UDP discovered peer connect result: peer=${peerId.take(12)} ip=$senderIp connected=$connected"
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed connecting discovered peer $peerId@$senderIp", e)
            }
        }
    }
}
