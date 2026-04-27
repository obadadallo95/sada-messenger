@file:OptIn(androidx.compose.foundation.ExperimentalFoundationApi::class)
package org.sada.messenger

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.net.Uri
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatDelegate
import androidx.appcompat.app.AppCompatActivity
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.core.os.LocaleListCompat
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.Alignment
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.navigation.compose.*
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.compose.ui.platform.LocalContext
import androidx.work.*
import org.sada.messenger.core.workers.CleanupWorker
import org.sada.messenger.ui.theme.*
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.security.KeyManager
import org.sada.messenger.security.EncryptionManager
import org.sada.messenger.security.AppSecuritySettings
import org.sada.messenger.network.MeshEngine
import org.sada.messenger.network.direct.WifiDirectManager
import org.sada.messenger.network.TransportManager
import org.sada.messenger.ui.viewmodels.SadaViewModelFactory
import org.sada.messenger.ui.viewmodels.HomeViewModel
// HIDDEN in v1.0 - Crisis Report is future feature, see docs/PROJECT_SUMMARY_v1.0.md
// import org.sada.messenger.ui.viewmodels.CrisisReportViewModel
import org.sada.messenger.ui.screens.HomeScreen
import org.sada.messenger.ui.screens.ChatScreen
import org.sada.messenger.ui.screens.OnboardingScreen
import org.sada.messenger.ui.screens.RegisterScreen
// HIDDEN in v1.0 - Crisis Report is future feature, see docs/PROJECT_SUMMARY_v1.0.md
// import org.sada.messenger.ui.screens.CrisisReportScreen
import org.sada.messenger.ui.screens.SettingsScreenGlass
import org.sada.messenger.ui.screens.BlockedContactsScreen
import org.sada.messenger.ui.screens.GrowthStudioScreen
import org.sada.messenger.ui.screens.AboutSadaPage
import org.sada.messenger.ui.screens.LegalTextPage
import org.sada.messenger.ui.screens.MyQrScreen
import org.sada.messenger.ui.screens.ContactsScreen
import org.sada.messenger.ui.screens.AddedContactsScreen
import org.sada.messenger.ui.viewmodels.ContactsViewModel
import org.sada.messenger.ui.screens.CreateGroupScreen
import org.sada.messenger.ui.screens.MeshDiagnosticsScreen
import org.sada.messenger.network.lora.LoraSerialManager
import org.sada.messenger.managers.UdpBroadcastManager
import org.sada.messenger.managers.VideoEngine
import org.sada.messenger.managers.AudioRecorderManager
import org.sada.messenger.core.services.MeshForegroundService
import org.sada.messenger.ui.screens.GroupsScreen
import org.sada.messenger.ui.navigation.SadaBottomBar
import org.sada.messenger.ui.navigation.MainTabsHost
import org.sada.messenger.ui.navigation.rememberMainPagerState
import org.sada.messenger.core.constants.LegalContent
import org.sada.messenger.growth.UserStatusStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.io.File
import java.util.Locale

class MainActivity : AppCompatActivity() {
    private val TAG = "SadaMesh"
    private val DISCOVERY_PREFIX = "SADA_DISCOVERY"
    private val DISCOVERY_VERSION = "v1"
    private val DISCOVERY_INTERVAL_MS = 15000L
    private val CONNECT_RETRY_COOLDOWN_MS = 10000L
    private val EXIT_CONFIRMATION_WINDOW_MS = 2000L
    private val TCP_PORT = 8888
    
    private lateinit var wifiP2pManager: WifiP2pManager
    private lateinit var channel: WifiP2pManager.Channel
    private val socketManager = SocketManager.getInstance()
    private lateinit var udpBroadcastManager: UdpBroadcastManager
    
    private lateinit var database: AppDatabase
    private lateinit var keyManager: KeyManager
    private lateinit var encryptionManager: EncryptionManager
    private lateinit var appSecuritySettings: AppSecuritySettings
    private lateinit var meshEngine: MeshEngine

    private lateinit var transportManager: TransportManager
    private lateinit var videoEngine: VideoEngine
    private lateinit var audioRecorderManager: AudioRecorderManager
    private lateinit var viewModelFactory: SadaViewModelFactory

    private val peersList = mutableStateListOf<WifiP2pDevice>()
    private var discoveryJob: Job? = null
    private val lastConnectAttemptAt = mutableMapOf<String, Long>()
    private var myPeerId: String = ""
    private var isAppUnlocked by mutableStateOf(true)
    private var showPermissionRationale by mutableStateOf(false)
    @Volatile
    private var isBiometricPromptShowing = false
    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (!granted) {
            val msg = if (Locale.getDefault().language.startsWith("ar")) {
                "لن تصلك إشعارات الرسائل بدون منح صلاحية الإشعارات"
            } else {
                "Message notifications are disabled until notification permission is granted"
            }
            Toast.makeText(this, msg, Toast.LENGTH_LONG).show()
        }
    }

    private val meshPermissionsLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { results ->
        val denied = results.filterValues { granted -> !granted }.keys
        if (denied.isNotEmpty()) {
            val msg = if (Locale.getDefault().language.startsWith("ar")) {
                "بعض صلاحيات الشبكة مرفوضة، قد يعمل التطبيق بنمط LAN فقط"
            } else {
                "Some mesh permissions are denied, app may fallback to LAN only"
            }
            Toast.makeText(this, msg, Toast.LENGTH_LONG).show()
            Log.w(TAG, "Denied mesh permissions: $denied")
        } else {
            Log.i(TAG, "All mesh runtime permissions granted")
        }
    }
    private val essentialPermissionsLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { results ->
        val denied = results.filterValues { granted -> !granted }.keys
        if (denied.isEmpty()) {
            Log.i(TAG, "All essential runtime permissions granted")
            return@registerForActivityResult
        }
        val blockedPermanently = denied.filter { permission ->
            !shouldShowRequestPermissionRationale(permission)
        }
        val msg = if (Locale.getDefault().language.startsWith("ar")) {
            "بعض صلاحيات التطبيق الأساسية غير مفعلة. قد تتعطل الإضافة، التسجيل الصوتي أو الاتصال."
        } else {
            "Some essential permissions are denied. Add friend, voice, or mesh features may fail."
        }
        Toast.makeText(this, msg, Toast.LENGTH_LONG).show()
        Log.w(TAG, "Denied essential permissions: $denied")
        if (blockedPermanently.isNotEmpty()) {
            openAppPermissionSettings()
        }
    }

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

    override fun attachBaseContext(newBase: Context) {
        val localized = withLocalizedContext(newBase)
        super.attachBaseContext(localized)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        database = AppDatabase.getDatabase(this)
        keyManager = KeyManager(this)
        encryptionManager = EncryptionManager(keyManager)
        appSecuritySettings = AppSecuritySettings(this)
        isAppUnlocked = savedInstanceState?.getBoolean("is_app_unlocked")
            ?: !appSecuritySettings.isAppLockEnabled()
        
        // Initialize Wi-Fi P2P Manager for peer discovery
        wifiP2pManager = getSystemService(Context.WIFI_P2P_SERVICE) as WifiP2pManager
        channel = wifiP2pManager.initialize(this, mainLooper, null)
        
        udpBroadcastManager = UdpBroadcastManager.getInstance(this)
        
        val loraManager = LoraSerialManager(this)
        val wifiDirectMgr = WifiDirectManager(this, socketManager)
        transportManager = TransportManager(this, socketManager, wifiDirectMgr)
        meshEngine = MeshEngine(
            context = this,
            socketManager = socketManager,
            database = database,
            keyManager = keyManager,
            encryptionManager = encryptionManager,
            loraInterface = loraManager,
            transportSend = { bytes -> transportManager.sendFramed(bytes) },
            transportIsConnected = { transportManager.isConnected() },
            activeTransportProvider = { transportManager.activeTransportLabel() }
        )

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

        // Register Wi-Fi P2P receiver for peer discovery
        val intentFilter = IntentFilter().apply {
            addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
        }
        registerReceiver(wifiP2pReceiver, intentFilter)

        // Local State for Onboarding/Registration
        val prefs = getSharedPreferences("sada_app_state", Context.MODE_PRIVATE)
        applySavedLocale(prefs.getString("app_language", null))
        val isRegistered = try { keyManager.getKeyPair().publicKey.asBytes.isNotEmpty() && prefs.getString("user_nickname", null) != null } catch(e: Exception) { false }
        myPeerId = keyManager.getPublicKeyBase64()
        if (isRegistered) {
            MeshForegroundService.start(this)
            checkAndShowRationaleIfNeeded()
        }

        val savedThemeMode = prefs.getString("app_theme_mode", "dark").orEmpty().toThemeMode()

        setContent {
            val isRtlLayout = resources.configuration.layoutDirection == android.util.LayoutDirection.RTL
            SadaTheme(themeMode = savedThemeMode) {
                CompositionLocalProvider(
                    LocalLayoutDirection provides if (isRtlLayout) LayoutDirection.Rtl else LayoutDirection.Ltr
                ) {
                    Surface(
                        modifier = Modifier.fillMaxSize(),
                        color = MaterialTheme.colorScheme.background
                    ) {
                        val navController = rememberNavController()
                        val navBackStackEntry by navController.currentBackStackEntryAsState()
                        val currentRoute = navBackStackEntry?.destination?.route
                        var lastBackPressAt by remember { mutableStateOf(0L) }

                        BackHandler {
                            val popped = navController.popBackStack()
                            if (!popped) {
                                val now = System.currentTimeMillis()
                                if (now - lastBackPressAt < EXIT_CONFIRMATION_WINDOW_MS) {
                                    finish()
                                } else {
                                    lastBackPressAt = now
                                    val exitMessage = if (Locale.getDefault().language.startsWith("ar")) {
                                        "اضغط رجوع مرة أخرى للخروج"
                                    } else {
                                        "Press back again to exit"
                                    }
                                    Toast.makeText(this@MainActivity, exitMessage, Toast.LENGTH_SHORT).show()
                                }
                            }
                        }

                        val startDestination = if (isRegistered) "main" else "onboarding"

                        Scaffold() { innerPadding ->
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
                                    myPeerId = keyManager.getPublicKeyBase64()
                                    MeshForegroundService.start(this@MainActivity)
                                    requestEssentialPermissionsIfNeeded()

                                    navController.navigate("main") {
                                        popUpTo("register") { inclusive = true }
                                    }
                                })
                            }
                            composable("main") {
                                val pagerState = rememberMainPagerState()
                                val scope = rememberCoroutineScope()
                                val homeViewModel: HomeViewModel = viewModel(factory = viewModelFactory)
                                val contactsViewModel: ContactsViewModel = viewModel(factory = viewModelFactory)
                                val userNickname = prefs.getString("user_nickname", "User") ?: "User"
                                val userStatusStore = UserStatusStore(this@MainActivity)
                                val currentStatus = userStatusStore.load()
                                MainTabsHost(pagerState = pagerState) { page ->
                                        when (page) {
                                            0 -> HomeScreen(
                                                viewModel = homeViewModel,
                                                onChatClick = { chatId -> navController.navigate("chat/${Uri.encode(chatId)}") },
                                                onDeleteChat = { chatId -> homeViewModel.removeConversation(chatId) },
                                                onSettingsClick = { scope.launch { pagerState.animateScrollToPage(4) } },
                                                onCreateGroupClick = { navController.navigate("create_group") },
                                                onDiagnosticsClick = { navController.navigate("diagnostics") },
                                                onRequestPermissions = { requestMeshPermissionsIfNeeded() }
                                            )
                                            1 -> AddedContactsScreen(
                                                viewModel = contactsViewModel,
                                                onContactClick = { chatId -> navController.navigate("chat/${Uri.encode(chatId)}") }
                                            )
                                            2 -> GroupsScreen(
                                                viewModel = homeViewModel,
                                                onGroupClick = { chatId -> navController.navigate("chat/${Uri.encode(chatId)}") },
                                                onCreateGroupClick = { navController.navigate("create_group") }
                                            )
                                            3 -> ContactsScreen(
                                                viewModel = contactsViewModel,
                                                onContactClick = { chatId ->
                                                    navController.navigate("chat/${Uri.encode(chatId)}") {
                                                        popUpTo("main")
                                                    }
                                                },
                                                onBack = { scope.launch { pagerState.animateScrollToPage(0) } },
                                                currentUserName = userNickname,
                                                currentUserId = myPeerId
                                            )
                                            4 -> SettingsScreenGlass(
                                                onBack = { scope.launch { pagerState.animateScrollToPage(0) } },
                                                onDiagnosticsClick = { navController.navigate("diagnostics") },
                                                onGrowthClick = { /* HIDDEN in v1.0 - see docs/ROADMAP_ServiceProfile_v2.0.md */ },
                                                onBlockedContactsClick = { navController.navigate("settings/blocked") },
                                                onShareApkClick = { shareCurrentApk() },
                                                onAboutClick = { navController.navigate("settings/about") },
                                                onPrivacyClick = { navController.navigate("settings/privacy") },
                                                onTermsClick = { navController.navigate("settings/terms") },
                                                onIpClick = { navController.navigate("settings/ip") },
                                                displayName = userNickname,
                                                initialThemeMode = prefs.getString("app_theme_mode", "dark") ?: "dark",
                                                initialLanguage = prefs.getString("app_language", "ar") ?: "ar",
                                                initialStatusText = currentStatus.statusText,
                                                initialStatusExpiresAtMs = currentStatus.expiresAtMs,
                                                onPublishStatus = { statusText, expiresAtMs ->
                                                    userStatusStore.save(statusText, expiresAtMs)
                                                    lifecycleScope.launch(Dispatchers.IO) {
                                                        runCatching {
                                                            meshEngine.publishStatusToVerifiedContacts(
                                                                statusText = statusText,
                                                                expiresAt = java.util.Date(expiresAtMs)
                                                            )
                                                        }.onFailure { e -> Log.e(TAG, "Failed to publish status", e) }
                                                    }
                                                },
                                                onClearStatus = { userStatusStore.clear() },
                                                onThemeChanged = { mode ->
                                                    prefs.edit().putString("app_theme_mode", mode).apply()
                                                    recreate()
                                                },
                                                onLanguageChanged = { language ->
                                                    prefs.edit().putString("app_language", language).apply()
                                                    applySavedLocale(language)
                                                    recreate()
                                                }
                                            )
                                        }
                                    }
                            }
                            composable("settings/blocked") {
                                val contactsViewModel: ContactsViewModel = viewModel(factory = viewModelFactory)
                                BlockedContactsScreen(
                                    viewModel = contactsViewModel,
                                    onBack = { navController.popBackStack() }
                                )
                            }
                            // HIDDEN in v1.0 - Service Profile feature, see docs/ROADMAP_ServiceProfile_v2.0.md
                            // composable("settings/growth") {
                            //     GrowthStudioScreen(
                            //         onBack = { navController.popBackStack() }
                            //     )
                            // }
                            composable("settings/about") {
                                val isArabic = !(prefs.getString("app_language", "ar") ?: "ar").equals("en", ignoreCase = true)
                                AboutSadaPage(
                                    onBack = { navController.popBackStack() },
                                    isArabic = isArabic
                                )
                            }
                            composable("settings/privacy") {
                                val isArabic = !(prefs.getString("app_language", "ar") ?: "ar").equals("en", ignoreCase = true)
                                LegalTextPage(
                                    title = if (isArabic) "سياسة الخصوصية" else "Privacy Policy",
                                    content = LegalContent.privacyPolicy(isArabic),
                                    onBack = { navController.popBackStack() }
                                )
                            }
                            composable("settings/terms") {
                                val isArabic = !(prefs.getString("app_language", "ar") ?: "ar").equals("en", ignoreCase = true)
                                LegalTextPage(
                                    title = if (isArabic) "شروط الاستخدام" else "Terms of Use",
                                    content = LegalContent.termsOfUse(isArabic),
                                    onBack = { navController.popBackStack() }
                                )
                            }
                            composable("settings/ip") {
                                val isArabic = !(prefs.getString("app_language", "ar") ?: "ar").equals("en", ignoreCase = true)
                                LegalTextPage(
                                    title = if (isArabic) "حقوق الملكية الفكرية" else "Intellectual Property",
                                    content = LegalContent.intellectualProperty(isArabic),
                                    onBack = { navController.popBackStack() }
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
                                    onCreateGroup = { name, description, isPublic, joinPolicy, members ->
                                        homeViewModel.createGroup(
                                            name = name,
                                            description = description,
                                            isPublic = isPublic,
                                            joinPolicy = joinPolicy,
                                            members = members
                                        )
                                        navController.popBackStack()
                                    },
                                    onBack = { navController.popBackStack() }
                                )
                            }
                            composable("contacts") {
                                val contactsViewModel: ContactsViewModel = viewModel(factory = viewModelFactory)
                                val userNickname = prefs.getString("user_nickname", "User") ?: "User"
                                ContactsScreen(
                                    viewModel = contactsViewModel,
                                    onContactClick = { chatId ->
                                        navController.navigate("chat/${Uri.encode(chatId)}") {
                                            popUpTo("home")
                                        }
                                    },
                                    onBack = { navController.popBackStack() },
                                    currentUserName = userNickname,
                                    currentUserId = myPeerId
                                )
                            }
                            composable("chat/{chatId}") { backStackEntry ->
                                val encodedChatId = backStackEntry.arguments?.getString("chatId") ?: return@composable
                                val chatId = Uri.decode(encodedChatId)
                                val chatViewModel = remember(chatId) {
                                    viewModelFactory.createChatViewModel(chatId)
                                }
                                
                                // HIDDEN in v1.0 - Crisis Report is future feature, see docs/PROJECT_SUMMARY_v1.0.md
                                // Handle result from CrisisReportScreen
                                // val reportPath = backStackEntry.savedStateHandle.get<String>("report_file")
                                // LaunchedEffect(reportPath) {
                                //     reportPath?.let {
                                //         chatViewModel.sendMediaMessage(java.io.File(it), "video/mp4")
                                //         backStackEntry.savedStateHandle.remove<String>("report_file")
                                //     }
                                // }

                                ChatScreen(
                                    viewModel = chatViewModel,
                                    chatName = "Chat ${chatId.take(6)}",
                                    onBackClick = { navController.popBackStack() },
                                    onCrisisReportClick = { /* HIDDEN in v1.0 */ }
                                )
                            }
                            composable("diagnostics") {
                                MeshDiagnosticsScreen(
                                    meshEngine = meshEngine,
                                    udpDiagnostics = {
                                        val merged = mutableMapOf<String, Any>()
                                        merged.putAll(udpBroadcastManager.getDiagnostics())

                                        merged.putAll(transportManager.getDiagnostics().mapKeys { "transport_${it.key}" })
                                        merged.putAll(MeshForegroundService.getDiagnosticsSnapshot().mapKeys { "service_${it.key}" })
                                        merged
                                    },
                                    onBack = { navController.popBackStack() }
                                )
                            }
                            // HIDDEN in v1.0 - Crisis Report is future feature, see docs/PROJECT_SUMMARY_v1.0.md
                            // composable("crisis_report/{chatId}") { backStackEntry ->
                            //     val encodedChatId = backStackEntry.arguments?.getString("chatId") ?: return@composable
                            //     val chatId = Uri.decode(encodedChatId)
                            //     val crisisViewModel: CrisisReportViewModel = viewModel(factory = viewModelFactory)
                            //     CrisisReportScreen(
                            //         viewModel = crisisViewModel,
                            //         onReportGenerated = { file: java.io.File ->
                            //             navController.previousBackStackEntry?.savedStateHandle?.set("report_file", file.absolutePath)
                            //             navController.popBackStack()
                            //         },
                            //         onBack = { navController.popBackStack() }
                            //     )
                            // }
                            }
                        }

                        if (appSecuritySettings.isAppLockEnabled() && !isAppUnlocked) {
                            AppLockOverlay(
                                onUnlockClick = { promptBiometricUnlock() }
                            )
                        }

                        if (showPermissionRationale) {
                            PermissionRationaleDialog(
                                onConfirm = {
                                    showPermissionRationale = false
                                    requestEssentialPermissionsIfNeeded()
                                }
                            )
                        }
                    }
                }
            }
        }

        requestEssentialPermissionsOnFirstInstall()
    }

    private fun applySavedLocale(language: String?) {
        if (language.isNullOrBlank()) {
            AppCompatDelegate.setApplicationLocales(LocaleListCompat.getEmptyLocaleList())
            return
        }
        val localeList = LocaleListCompat.forLanguageTags(language)
        AppCompatDelegate.setApplicationLocales(localeList)
        Locale.setDefault(Locale(language))
        val config = Configuration(resources.configuration)
        config.setLocale(Locale(language))
        config.setLayoutDirection(Locale(language))
        @Suppress("DEPRECATION")
        resources.updateConfiguration(config, resources.displayMetrics)
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val granted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
        if (!granted) {
            notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    private fun requestMeshPermissionsIfNeeded() {
        val required = mutableListOf<String>()
        required += Manifest.permission.ACCESS_FINE_LOCATION
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            required += Manifest.permission.NEARBY_WIFI_DEVICES
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            required += Manifest.permission.BLUETOOTH_SCAN
            required += Manifest.permission.BLUETOOTH_CONNECT
            required += Manifest.permission.BLUETOOTH_ADVERTISE
        }

        val missing = required.filter { permission ->
            ContextCompat.checkSelfPermission(this, permission) !=
                android.content.pm.PackageManager.PERMISSION_GRANTED
        }

        if (missing.isNotEmpty()) {
            meshPermissionsLauncher.launch(missing.toTypedArray())
        }
    }

    private fun checkAndShowRationaleIfNeeded() {
        val required = collectEssentialRuntimePermissions()
        val missing = required.filter { permission ->
            ContextCompat.checkSelfPermission(this, permission) !=
                android.content.pm.PackageManager.PERMISSION_GRANTED
        }
        if (missing.isNotEmpty()) {
            showPermissionRationale = true
        }
    }

    private fun requestEssentialPermissionsOnFirstInstall() {
        val prefs = getSharedPreferences("sada_app_state", Context.MODE_PRIVATE)
        val prompted = prefs.getBoolean("essential_permissions_prompted_v1", false)
        if (prompted) {
            return
        }
        prefs.edit().putBoolean("essential_permissions_prompted_v1", true).apply()
        checkAndShowRationaleIfNeeded()
    }

    private fun requestEssentialPermissionsIfNeeded() {
        val required = collectEssentialRuntimePermissions()
        if (required.isEmpty()) return
        val missing = required.filter { permission ->
            ContextCompat.checkSelfPermission(this, permission) !=
                android.content.pm.PackageManager.PERMISSION_GRANTED
        }
        if (missing.isNotEmpty()) {
            essentialPermissionsLauncher.launch(missing.toTypedArray())
        }
    }

    private fun collectEssentialRuntimePermissions(): List<String> {
        val required = mutableListOf<String>()
        required += Manifest.permission.ACCESS_FINE_LOCATION
        required += Manifest.permission.CAMERA
        required += Manifest.permission.RECORD_AUDIO

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            required += Manifest.permission.NEARBY_WIFI_DEVICES
            required += Manifest.permission.POST_NOTIFICATIONS
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            required += Manifest.permission.BLUETOOTH_SCAN
            required += Manifest.permission.BLUETOOTH_CONNECT
            required += Manifest.permission.BLUETOOTH_ADVERTISE
        }
        return required
    }

    @Composable
    private fun PermissionRationaleDialog(onConfirm: () -> Unit) {
        AlertDialog(
            onDismissRequest = { /* Force user to interact */ },
            title = {
                Text(
                    stringResource(R.string.perm_rationale_title),
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp
                )
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Text(
                        stringResource(R.string.perm_rationale_desc),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f)
                    )
                    
                    HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f))
                    
                    PermissionItem(
                        icon = Icons.Default.CellTower,
                        title = stringResource(R.string.perm_nearby_title),
                        desc = stringResource(R.string.perm_nearby_desc)
                    )
                    PermissionItem(
                        icon = Icons.Default.QrCodeScanner,
                        title = stringResource(R.string.perm_camera_title),
                        desc = stringResource(R.string.perm_camera_desc)
                    )
                    PermissionItem(
                        icon = Icons.Default.Mic,
                        title = stringResource(R.string.perm_mic_title),
                        desc = stringResource(R.string.perm_mic_desc)
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = onConfirm,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text(stringResource(R.string.perm_button_grant), fontWeight = FontWeight.Bold)
                }
            },
            containerColor = LocalSadaPalette.current.surface,
            shape = RoundedCornerShape(24.dp)
        )
    }

    @Composable
    private fun PermissionItem(
        icon: androidx.compose.ui.graphics.vector.ImageVector,
        title: String,
        desc: String
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.Top
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = NeonTeal,
                modifier = Modifier.size(24.dp).padding(top = 2.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(title, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                Text(
                    desc,
                    fontSize = 12.sp,
                    lineHeight = 18.sp,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
        }
    }

    private fun openAppPermissionSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        runCatching { startActivity(intent) }
    }

    private fun enforceAppLockIfNeeded() {
        if (!appSecuritySettings.isAppLockEnabled()) {
            isAppUnlocked = true
            return
        }
        if (isAppUnlocked || isBiometricPromptShowing) return

        if (!isBiometricAvailable()) {
            isAppUnlocked = true
            val message = if (Locale.getDefault().language.startsWith("ar")) {
                "قفل التطبيق مفعّل، لكن البصمة غير متاحة على هذا الجهاز"
            } else {
                "App lock is enabled, but biometric is not available on this device"
            }
            Toast.makeText(this, message, Toast.LENGTH_LONG).show()
            return
        }

        promptBiometricUnlock()
    }

    private fun isBiometricAvailable(): Boolean {
        val biometricManager = BiometricManager.from(this)
        val result = biometricManager.canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_WEAK or
                BiometricManager.Authenticators.BIOMETRIC_STRONG
        )
        return result == BiometricManager.BIOMETRIC_SUCCESS
    }

    private fun promptBiometricUnlock() {
        if (isBiometricPromptShowing) return
        isBiometricPromptShowing = true

        val prompt = BiometricPrompt(
            this,
            ContextCompat.getMainExecutor(this),
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    isBiometricPromptShowing = false
                    isAppUnlocked = true
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    isBiometricPromptShowing = false
                    isAppUnlocked = false
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    isAppUnlocked = false
                }
            }
        )

        val isArabic = Locale.getDefault().language.startsWith("ar")
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(if (isArabic) "قفل التطبيق" else "App Lock")
            .setSubtitle(if (isArabic) "استخدم البصمة لفتح التطبيق" else "Use fingerprint to unlock")
            .setNegativeButtonText(if (isArabic) "إلغاء" else "Cancel")
            .build()

        prompt.authenticate(promptInfo)
    }

    private fun String.toThemeMode(): SadaThemeMode {
        return when (this.lowercase()) {
            "light" -> SadaThemeMode.LIGHT
            "system" -> SadaThemeMode.SYSTEM
            else -> SadaThemeMode.DARK
        }
    }

    private fun withLocalizedContext(base: Context): Context {
        val prefs = base.getSharedPreferences("sada_app_state", Context.MODE_PRIVATE)
        val lang = prefs.getString("app_language", null)
        if (lang.isNullOrBlank()) return base

        val locale = Locale(lang)
        Locale.setDefault(locale)
        val config = Configuration(base.resources.configuration)
        config.setLocale(locale)
        config.setLayoutDirection(locale)
        return base.createConfigurationContext(config)
    }

    override fun onDestroy() {
        super.onDestroy()
        discoveryJob?.cancel()

        // Unregister Wi-Fi P2P receiver
        try {
            unregisterReceiver(wifiP2pReceiver)
        } catch (e: IllegalArgumentException) {
            // Receiver was not registered
        }
        
        if (!MeshForegroundService.isRunning()) {
            socketManager.destroy()
            udpBroadcastManager.destroy()
        }
    }

    override fun onStart() {
        super.onStart()
        enforceAppLockIfNeeded()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean("is_app_unlocked", isAppUnlocked)
    }

    override fun onStop() {
        super.onStop()
        if (isChangingConfigurations) return
        if (appSecuritySettings.isAppLockEnabled()) {
            isAppUnlocked = false
        }
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

    private fun shareCurrentApk() {
        try {
            val sourceApkPath = applicationContext.applicationInfo.sourceDir
            val sourceFile = File(sourceApkPath)
            if (!sourceFile.exists()) {
                Toast.makeText(this, "تعذر العثور على ملف APK", Toast.LENGTH_LONG).show()
                return
            }

            val shareDir = File(cacheDir, "shared_apk").apply { mkdirs() }
            val shareFile = File(shareDir, "sada-debug.apk")
            sourceFile.copyTo(shareFile, overwrite = true)

            val apkUri = FileProvider.getUriForFile(
                this,
                "${packageName}.fileprovider",
                shareFile
            )

            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "application/vnd.android.package-archive"
                putExtra(Intent.EXTRA_STREAM, apkUri)
                putExtra(Intent.EXTRA_SUBJECT, "Sada APK")
                putExtra(Intent.EXTRA_TEXT, "Sada APK")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            startActivity(Intent.createChooser(shareIntent, "مشاركة ملف APK"))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to share APK", e)
            Toast.makeText(this, "فشل مشاركة APK: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    @Composable
    private fun AppLockOverlay(onUnlockClick: () -> Unit) {
        val isArabic = Locale.getDefault().language.startsWith("ar")
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = Color(0xEE000000)
        ) {
            Column(
                modifier = Modifier.fillMaxSize().padding(24.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = if (isArabic) "التطبيق مقفل" else "App Locked",
                    style = MaterialTheme.typography.headlineSmall,
                    color = Color.White
                )
                Spacer(modifier = Modifier.height(10.dp))
                Text(
                    text = if (isArabic) "استخدم البصمة للمتابعة" else "Authenticate with fingerprint to continue",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color.White.copy(alpha = 0.8f)
                )
                Spacer(modifier = Modifier.height(20.dp))
                Button(onClick = onUnlockClick) {
                    Text(if (isArabic) "فتح بالبصمة" else "Unlock with Biometrics")
                }
            }
        }
    }
}
