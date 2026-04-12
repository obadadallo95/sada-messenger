package org.sada.messenger.ui.screens

import android.app.Activity
import android.content.pm.PackageManager
import android.widget.Toast
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color as AndroidColor
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.google.zxing.BarcodeFormat
import com.google.zxing.WriterException
import com.google.zxing.qrcode.QRCodeWriter
import com.journeyapps.barcodescanner.BarcodeCallback
import com.journeyapps.barcodescanner.BarcodeResult
import com.journeyapps.barcodescanner.DecoratedBarcodeView
import kotlinx.coroutines.launch
import org.json.JSONObject
import org.sada.messenger.data.entities.ContactEntity
import org.sada.messenger.ui.theme.*
import org.sada.messenger.ui.utils.tr
import androidx.compose.material.ripple.rememberRipple
import org.sada.messenger.growth.LocalAnalytics
import org.sada.messenger.ui.viewmodels.ContactsViewModel
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import java.io.File
import java.io.FileOutputStream

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun ContactsScreen(
    viewModel: ContactsViewModel,
    onContactClick: (String) -> Unit,
    onBack: () -> Unit,
    currentUserName: String,
    currentUserId: String
) {
    var selectedMode by remember { mutableStateOf(AddFriendMode.SCAN) }
    var showQrDialog by remember { mutableStateOf(false) }
    var qrDialogMode by remember { mutableStateOf(AddFriendMode.PRIVATE_CODE) }
    var showScanner by remember { mutableStateOf(false) }
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val context = androidx.compose.ui.platform.LocalContext.current
    val localAnalytics = remember { LocalAnalytics(context) }

    val privateQrPayload = remember(currentUserName, currentUserId) {
        JSONObject()
            .put("id", currentUserId)
            .put("name", currentUserName)
            .put("publicKey", currentUserId)
            .put("channelType", "private")
            .put("authMode", "connection_request")
            .toString()
    }


    val handleScannedPayload: (String) -> Unit = scan@{ raw ->
        if (raw.isBlank()) return@scan
        scope.launch {
            val parsed = parseFriendQr(raw)
            if (parsed == null) {
                snackbarHostState.showSnackbar(tr("QR غير صالح", "Invalid QR"))
                return@launch
            }
            if (parsed.publicKey == currentUserId) {
                snackbarHostState.showSnackbar(tr("لا يمكنك إضافة نفسك", "You cannot add yourself"))
                return@launch
            }
            val addedId = viewModel.addContactFromQr(
                name = parsed.name,
                publicKey = parsed.publicKey,
                chatId = parsed.id,
                channelType = parsed.channelType
            )
            if (addedId == null) {
                snackbarHostState.showSnackbar(tr("فشل إضافة الصديق", "Failed to add friend"))
                return@launch
            }
            snackbarHostState.showSnackbar(tr("✅ تم التحقق وإضافة جهة الاتصال", "✅ Contact verified and added"))
            localAnalytics.trackQrScanSuccess()
            localAnalytics.trackContactAddedViaQr()
            onContactClick(addedId)
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        tr("إضافة صديق", "Add Friend"), 
                        fontWeight = FontWeight.Bold,
                        color = LocalSadaPalette.current.textPrimary
                    ) 
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack, 
                            contentDescription = "Back",
                            tint = LocalSadaPalette.current.textPrimary
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = LocalSadaPalette.current.background.copy(alpha = 0.9f),
                    titleContentColor = LocalSadaPalette.current.textPrimary,
                    navigationIconContentColor = LocalSadaPalette.current.textPrimary,
                    actionIconContentColor = LocalSadaPalette.current.textPrimary
                )
            )
        },
        containerColor = LocalSadaPalette.current.background
    ) { padding ->
        MeshBackground {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            AddFriendModeSelector(
                selectedMode = selectedMode,
                onSelect = { selectedMode = it }
            )

            AnimatedContent(
                targetState = selectedMode,
                transitionSpec = {
                    fadeIn() + slideInHorizontally { it / 4 } togetherWith
                        fadeOut() + slideOutHorizontally { -it / 4 }
                },
                label = "add_friend_mode"
            ) {
                when (it) {
                    AddFriendMode.SCAN -> AddFriendActionCard(
                        icon = Icons.Default.CenterFocusStrong,
                        title = tr("امسح كود صديقك", "Scan Friend QR"),
                        subtitle = tr(
                            "افتح الكاميرا وامسح QR لإضافة صديق موثّق مباشرة.",
                            "Open camera and scan QR to add a verified friend instantly."
                        ),
                        buttonText = tr("بدء المسح", "Start Scan"),
                        onAction = {
                            localAnalytics.trackQrScanOpened()
                            showScanner = true
                        }
                    )
                    AddFriendMode.PRIVATE_CODE -> AddFriendActionCard(
                        icon = Icons.Default.QrCode2,
                        title = tr("كودي الشخصي", "My Personal Code"),
                        subtitle = tr(
                            "اعرض كودك لصديقك ليقوم بمسحه وإضافتك بأمان.",
                            "Show your QR so your friend can scan and add you securely."
                        ),
                        buttonText = tr("عرض الكود", "Show Code"),
                        onAction = {
                            qrDialogMode = AddFriendMode.PRIVATE_CODE
                            showQrDialog = true
                        }
                    )
                    // PUBLIC CODE - DISABLED (was for shops/services)
                    // AddFriendMode.PUBLIC_CODE -> AddFriendActionCard(...)
                }
            }

            Spacer(modifier = Modifier.height(6.dp))
            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = LocalSadaPalette.current.surfaceVariant,
                shape = RoundedCornerShape(14.dp),
                tonalElevation = 0.dp
            ) {
                Text(
                    text = tr(
                        "يتم إضافة الأصدقاء فقط عبر QR لمنع أي إضافة عشوائية.",
                        "Friends are added only via QR to prevent random connections."
                    ),
                    color = LocalSadaPalette.current.textSecondary,
                    fontSize = 13.sp,
                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp)
                )
            }
        }
        }
    }

    if (showQrDialog) {
        // PUBLIC CODE disabled - only private code available now
        val payload = privateQrPayload
        val title = tr("الكود الخاص", "Private Code")
        val subtitle = tr("شاركه فقط مع الأشخاص الموثوقين", "Share only with trusted contacts")
        val shownName = currentUserName
        val shownId = currentUserId
        QrCodeDialog(
            payload = payload,
            userName = shownName,
            userId = shownId,
            codeTitle = title,
            codeSubtitle = subtitle,
            onDismiss = { showQrDialog = false },
            onShare = { shareQrPayload(context, payload, localAnalytics) }
        )
    }

    if (showScanner) {
        ModernQrScannerSheet(
            onClose = { showScanner = false },
            onScanned = { raw ->
                showScanner = false
                handleScannedPayload(raw)
            }
        )
    }
}

private enum class AddFriendMode { SCAN, PRIVATE_CODE /*, PUBLIC_CODE - DISABLED */ }

@Composable
private fun AddFriendModeSelector(
    selectedMode: AddFriendMode,
    onSelect: (AddFriendMode) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        listOf(AddFriendMode.SCAN, AddFriendMode.PRIVATE_CODE).forEach { mode ->
            val selected = mode == selectedMode
            Surface(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(14.dp))
                    .clickable { onSelect(mode) },
                color = if (selected) SadaPrimary.copy(alpha = 0.18f) else LocalSadaPalette.current.surfaceVariant,
                border = androidx.compose.foundation.BorderStroke(
                    width = if (selected) 1.4.dp else 1.dp,
                    color = if (selected) SadaPrimary else Color.White.copy(alpha = 0.08f)
                ),
                shape = RoundedCornerShape(14.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = when (mode) {
                            AddFriendMode.SCAN -> Icons.Default.CenterFocusStrong
                            AddFriendMode.PRIVATE_CODE -> Icons.Default.QrCode2
                            // PUBLIC_CODE disabled
                        },
                        contentDescription = null,
                        tint = if (selected) SadaPrimary else LocalSadaPalette.current.textSecondary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = when (mode) {
                            AddFriendMode.SCAN -> tr("مسح", "Scan")
                            AddFriendMode.PRIVATE_CODE -> tr("خاص", "Private")
                            // PUBLIC_CODE disabled
                        },
                        color = if (selected) LocalSadaPalette.current.textPrimary else LocalSadaPalette.current.textSecondary,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }
    }
}

@Composable
private fun AddFriendActionCard(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    buttonText: String,
    onAction: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = LocalSadaPalette.current.surfaceVariant,
        shape = RoundedCornerShape(18.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, SadaPrimary.copy(alpha = 0.26f))
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 18.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(74.dp)
                    .clip(CircleShape)
                    .background(SadaPrimary.copy(alpha = 0.16f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(icon, contentDescription = null, tint = SadaPrimary, modifier = Modifier.size(34.dp))
            }
            Spacer(modifier = Modifier.height(12.dp))
            Text(title, color = LocalSadaPalette.current.textPrimary, fontWeight = FontWeight.Bold, fontSize = 18.sp)
            Spacer(modifier = Modifier.height(6.dp))
            Text(subtitle, color = LocalSadaPalette.current.textSecondary, textAlign = TextAlign.Center, fontSize = 13.sp)
            Spacer(modifier = Modifier.height(14.dp))
            Button(
                onClick = onAction,
                colors = ButtonDefaults.buttonColors(containerColor = SadaPrimary),
                shape = RoundedCornerShape(14.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(buttonText, color = GhostWhite, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

// ===================== QR DIALOG =====================
@Composable
private fun LegacyRemoved() {
    // Intentionally empty; removed verified/pending contact lists from Add Friend page.
}

@Composable
private fun ModernQrScannerSheet(
    onClose: () -> Unit,
    onScanned: (String) -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    var hasCameraPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, android.Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        )
    }
    var consumed by remember { mutableStateOf(false) }
    var barcodeViewRef by remember { mutableStateOf<DecoratedBarcodeView?>(null) }
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        hasCameraPermission = granted
        // Force recomposition to recreate AndroidView with camera
        barcodeViewRef = null
    }

    DisposableEffect(lifecycleOwner, barcodeViewRef) {
        val view = barcodeViewRef
        if (view == null) {
            onDispose { }
        } else {
            val observer = LifecycleEventObserver { _, event ->
                when (event) {
                    Lifecycle.Event.ON_RESUME -> view.resume()
                    Lifecycle.Event.ON_PAUSE -> view.pause()
                    Lifecycle.Event.ON_DESTROY -> view.pauseAndWait()
                    else -> Unit
                }
            }
            lifecycleOwner.lifecycle.addObserver(observer)
            onDispose {
                lifecycleOwner.lifecycle.removeObserver(observer)
                view.pauseAndWait()
            }
        }
    }

    LaunchedEffect(Unit) {
        if (!hasCameraPermission) permissionLauncher.launch(android.Manifest.permission.CAMERA)
    }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = LocalSadaPalette.current.background
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            if (hasCameraPermission) {
                AndroidView(
                    modifier = Modifier.fillMaxSize(),
                    factory = { ctx ->
                        DecoratedBarcodeView(ctx).apply {
                            statusView.text = tr("وجّه الكاميرا إلى QR", "Point camera to QR")
                            barcodeView.decoderFactory =
                                com.journeyapps.barcodescanner.DefaultDecoderFactory(listOf(BarcodeFormat.QR_CODE))
                            decodeContinuous(object : BarcodeCallback {
                                override fun barcodeResult(result: BarcodeResult?) {
                                    val value = result?.text ?: return
                                    if (consumed) return
                                    consumed = true
                                    onScanned(value)
                                }
                            })
                            resume()
                            barcodeViewRef = this
                        }
                    }
                )
            } else {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(Icons.Default.CameraAlt, contentDescription = null, tint = Color.White, modifier = Modifier.size(52.dp))
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(
                        text = tr("نحتاج إذن الكاميرا للمسح", "Camera permission is required to scan"),
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.height(14.dp))
                    Button(onClick = { permissionLauncher.launch(android.Manifest.permission.CAMERA) }) {
                        Text(tr("منح الإذن", "Grant Permission"))
                    }
                }
            }

            Box(
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .padding(top = 52.dp)
                    .background(Color.Black.copy(alpha = 0.45f), RoundedCornerShape(12.dp))
                    .padding(horizontal = 14.dp, vertical = 10.dp)
            ) {
                Text(
                    text = tr("امسح QR لإضافة صديق", "Scan QR to add friend"),
                    color = Color.White,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Box(
                modifier = Modifier
                    .align(Alignment.Center)
                    .size(250.dp)
                    .border(2.dp, SadaPrimary, RoundedCornerShape(20.dp))
            )

            IconButton(
                onClick = onClose,
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(16.dp)
                    .background(Color.Black.copy(alpha = 0.45f), CircleShape)
            ) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null, tint = LocalSadaPalette.current.textPrimary)
            }
        }
    }
}
@Composable
private fun QrCodeDialog(
    payload: String,
    userName: String,
    userId: String,
    codeTitle: String,
    codeSubtitle: String,
    onDismiss: () -> Unit,
    onShare: () -> Unit
) {
    val qrBitmap = remember(payload) { generateQrBitmap(payload, 900) }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 6.dp),
            shape = RoundedCornerShape(24.dp),
            color = LocalSadaPalette.current.surface,
            border = androidx.compose.foundation.BorderStroke(1.2.dp, SadaPrimary.copy(alpha = 0.4f))
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                SadaPrimary.copy(alpha = 0.12f),
                                LocalSadaPalette.current.surface,
                                LocalSadaPalette.current.surface
                            )
                        )
                    )
                    .padding(horizontal = 18.dp, vertical = 18.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    codeTitle,
                    fontWeight = FontWeight.ExtraBold,
                    color = LocalSadaPalette.current.textPrimary,
                    fontSize = 20.sp
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    codeSubtitle,
                    color = LocalSadaPalette.current.textSecondary,
                    fontSize = 12.sp
                )

                Spacer(Modifier.height(14.dp))

                Surface(
                    color = Color.White,
                    shape = RoundedCornerShape(18.dp),
                    tonalElevation = 0.dp,
                    border = androidx.compose.foundation.BorderStroke(3.dp, SadaPrimary.copy(alpha = 0.28f))
                ) {
                    if (qrBitmap != null) {
                        Image(
                            bitmap = qrBitmap.asImageBitmap(),
                            contentDescription = "My QR",
                            modifier = Modifier
                                .size(260.dp)
                                .padding(10.dp)
                        )
                    } else {
                        Box(Modifier.size(260.dp), contentAlignment = Alignment.Center) {
                            Text("QR Error")
                        }
                    }
                }

                Spacer(Modifier.height(12.dp))

                Text(userName, fontWeight = FontWeight.Bold, color = LocalSadaPalette.current.textPrimary, fontSize = 18.sp)
                Text(
                    "ID: ${userId.take(16)}...${userId.takeLast(8)}",
                    fontSize = 12.sp,
                    color = LocalSadaPalette.current.textSecondary,
                    textAlign = TextAlign.Center
                )

                Spacer(Modifier.height(14.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(14.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, LocalSadaPalette.current.textSecondary.copy(alpha = 0.35f))
                    ) {
                        Text(tr("إغلاق", "Close"), color = LocalSadaPalette.current.textPrimary)
                    }
                    Button(
                        onClick = onShare,
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = SadaPrimary)
                    ) {
                        Icon(Icons.Default.Share, null, tint = Color.White)
                        Spacer(Modifier.width(6.dp))
                        Text(tr("مشاركة", "Share"), color = Color.White)
                    }
                }
            }
        }
    }
}

// ===================== UTILITIES =====================
internal data class QrFriendPayload(
    val id: String?,
    val name: String,
    val publicKey: String,
    val channelType: String,
    val serviceCategory: String? = null,
    val serviceAddress: String? = null,
    val serviceWorkingHours: String? = null,
    val serviceContact: String? = null,
    val deliveryAvailable: Boolean = false,
    val deliveryRadiusKm: String? = null,
    val serviceQuickReply: String? = null
)

private fun parseFriendQr(raw: String): QrFriendPayload? {
    return try {
        if (raw.trimStart().startsWith("{")) {
            val json = JSONObject(raw)
            val id = json.optString("id").trim().ifBlank { null }
            val key = json.optString("publicKey").trim()
            val name = json.optString("name", "Friend").ifBlank { "Friend" }
            val channelType = json.optString("channelType", "private").trim().lowercase()
            if (key.isBlank()) null else QrFriendPayload(
                id = id,
                name = name,
                publicKey = key,
                channelType = if (channelType == "public") "public" else "private",
                serviceCategory = json.optString("serviceCategory").trim().ifBlank { null },
                serviceAddress = json.optString("serviceAddress").trim().ifBlank { null },
                serviceWorkingHours = json.optString("serviceWorkingHours").trim().ifBlank { null },
                serviceContact = json.optString("serviceContact").trim().ifBlank { null },
                deliveryAvailable = json.optBoolean("deliveryAvailable", false),
                deliveryRadiusKm = json.optString("deliveryRadiusKm").trim().ifBlank { null },
                serviceQuickReply = json.optString("serviceQuickReply").trim().ifBlank { null }
            )
        } else null
    } catch (_: Exception) { null }
}

private fun generateQrBitmap(payload: String, size: Int): Bitmap? {
    return try {
        val matrix = QRCodeWriter().encode(payload, BarcodeFormat.QR_CODE, size, size)
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.RGB_565)
        for (x in 0 until size) {
            for (y in 0 until size) {
                bitmap.setPixel(x, y, if (matrix[x, y]) AndroidColor.BLACK else AndroidColor.WHITE)
            }
        }
        bitmap
    } catch (_: WriterException) { null }
    catch (_: Exception) { null }
}

private fun shareQrPayload(context: Context, payload: String, analytics: LocalAnalytics? = null) {
    val isArabic = context.resources.configuration.locales[0]?.language?.startsWith("ar") == true
    val title = if (isArabic) "مشاركة" else "Share"
    val description = if (isArabic) {
        "رمز صديق صدى:\n$payload"
    } else {
        "Sada friend code:\n$payload"
    }
    try {
        val bitmap = generateQrBitmap(payload, 1200)
        if (bitmap == null) {
            val textIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, description)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(Intent.createChooser(textIntent, title))
            return
        }

        val dir = File(context.cacheDir, "shared_qr").apply { mkdirs() }
        val file = File(dir, "sada_qr_${System.currentTimeMillis()}.png")
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }

        val uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            file
        )

        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, description)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            clipData = android.content.ClipData.newUri(context.contentResolver, "sada_qr", uri)
        }
        context.startActivity(Intent.createChooser(shareIntent, title))
        analytics?.trackQrShared()
    } catch (e: Exception) {
        Toast.makeText(
            context,
            if (isArabic) "تعذرت المشاركة" else "Share failed",
            Toast.LENGTH_SHORT
        ).show()
    }
}

private fun Context.findActivity(): Activity? {
    var current: Context? = this
    while (current is ContextWrapper) {
        if (current is Activity) return current
        current = current.baseContext
    }
    return null
}
