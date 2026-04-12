package org.sada.messenger.ui.screens

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import org.sada.messenger.R
import org.sada.messenger.core.constants.LegalContent
import androidx.biometric.BiometricManager
import org.sada.messenger.security.AppSecuritySettings
import org.sada.messenger.ui.theme.*
import org.sada.messenger.ui.components.*
import org.sada.messenger.ui.utils.tr

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreenGlass(
    onBack: () -> Unit,
    onDiagnosticsClick: () -> Unit,
    onGrowthClick: () -> Unit,
    onBlockedContactsClick: () -> Unit,
    onShareApkClick: () -> Unit,
    onAboutClick: () -> Unit,
    onPrivacyClick: () -> Unit,
    onTermsClick: () -> Unit,
    onIpClick: () -> Unit,
    displayName: String,
    initialThemeMode: String,
    initialLanguage: String,
    initialPowerMode: String,
    initialStatusText: String,
    initialStatusExpiresAtMs: Long,
    onPublishStatus: (String, Long) -> Unit,
    onClearStatus: () -> Unit,
    onThemeChanged: (String) -> Unit,
    onLanguageChanged: (String) -> Unit,
    onPowerModeChanged: (String) -> Unit
) {
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val securitySettings = remember { AppSecuritySettings(context) }
    val biometricAvailable = remember {
        BiometricManager.from(context).canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_WEAK or
            BiometricManager.Authenticators.BIOMETRIC_STRONG
        ) == BiometricManager.BIOMETRIC_SUCCESS
    }
    var themeMode by remember { mutableStateOf(initialThemeMode.lowercase()) }
    var language by remember { mutableStateOf(initialLanguage.lowercase()) }
    var powerMode by remember { mutableStateOf(initialPowerMode.lowercase()) }
    var appLockEnabled by remember { mutableStateOf(securitySettings.isAppLockEnabled()) }
    var currentStatusText by remember { mutableStateOf(initialStatusText) }
    var currentStatusExpiresAtMs by remember { mutableStateOf(initialStatusExpiresAtMs) }

    var showPinDialog by remember { mutableStateOf(false) }
    var pinInput by remember { mutableStateOf("") }
    var autoEnableLockAfterPin by remember { mutableStateOf(false) }

    Box(modifier = Modifier.fillMaxSize()) {
    MeshBackground()
    Box(modifier = Modifier.fillMaxSize()) {
        SettingsBackground()

        Scaffold(
            snackbarHost = { SnackbarHost(hostState = snackbarHostState) },
            topBar = {
                TopAppBar(
                    title = { 
                        Text(
                            tr("الإعدادات", "Settings"), 
                            fontWeight = FontWeight.ExtraBold,
                            color = LocalSadaPalette.current.textPrimary
                        ) 
                    },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(
                                Icons.AutoMirrored.Filled.ArrowBack, 
                                contentDescription = null,
                                tint = LocalSadaPalette.current.textPrimary
                            )
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = LocalSadaPalette.current.background.copy(alpha = 0.8f)
                    )
                )
            },
            containerColor = Color.Transparent
            ) { padding ->
                LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Profile Section
                item {
                    ProfileSection(
                        displayName = displayName,
                        initialStatusText = currentStatusText,
                        initialStatusExpiresAtMs = currentStatusExpiresAtMs,
                        onPublishStatus = { text, expiresAtMs ->
                            currentStatusText = text
                            currentStatusExpiresAtMs = expiresAtMs
                            onPublishStatus(text, expiresAtMs)
                        },
                        onClearStatus = {
                            currentStatusText = ""
                            currentStatusExpiresAtMs = 0L
                            onClearStatus()
                        }
                    )
                }

                // Appearance Group
                item {
                    SettingsGroup(title = tr("المظهر", "Appearance")) {
                        CompactChoiceRow(
                            icon = Icons.Default.Palette,
                            title = tr("المظهر", "Theme"),
                            iconColor = Color.Magenta,
                            options = listOf(
                                "dark" to tr("داكن", "Dark"),
                                "light" to tr("فاتح", "Light"),
                                "system" to tr("تلقائي", "System")
                            ),
                            selected = themeMode
                        ) { themeMode = it; onThemeChanged(it) }
                        HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = LocalSadaPalette.current.textSecondary.copy(alpha = 0.08f))
                        CompactChoiceRow(
                            icon = Icons.Default.Language,
                            title = tr("اللغة", "Language"),
                            iconColor = LocalSadaPalette.current.successGreen,
                            options = listOf(
                                "ar" to tr("ع", "AR"),
                                "en" to tr("EN", "EN")
                            ),
                            selected = language
                        ) { language = it; onLanguageChanged(it) }
                    }
                }

                // Security Group
                item {
                    SettingsGroup(title = tr("الأمان والقفل", "Security")) {
                        SettingsTile(
                            icon = Icons.Default.Fingerprint,
                            title = tr("قفل التطبيق", "App Lock"),
                            subtitle = when {
                                !biometricAvailable -> tr("البصمة غير مدعومة", "Biometrics not available")
                                appLockEnabled -> tr("مفعّل · بالبصمة", "Enabled · Biometrics")
                                else -> tr("معطل", "Disabled")
                            },
                            iconColor = if (biometricAvailable) CyberBlue else LocalSadaPalette.current.textSecondary,
                            enabled = biometricAvailable,
                            onClick = {
                                if (!biometricAvailable) {
                                    scope.launch {
                                        snackbarHostState.showSnackbar(
                                            tr("البصمة غير متاحة على هذا الجهاز", "Biometrics not available on this device")
                                        )
                                    }
                                } else {
                                    appLockEnabled = !appLockEnabled
                                    securitySettings.setAppLockEnabled(appLockEnabled)
                                    scope.launch {
                                        snackbarHostState.showSnackbar(
                                            if (appLockEnabled)
                                                tr("✅ تم تفعيل قفل التطبيق بالبصمة", "✅ App lock enabled with biometrics")
                                            else
                                                tr("تم تعطيل قفل التطبيق", "App lock disabled")
                                        )
                                    }
                                }
                            }
                        )
                        HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = LocalSadaPalette.current.textSecondary.copy(alpha = 0.12f))
                        SettingsTile(
                            icon = Icons.Default.VpnKey,
                            title = tr("تغيير الرمز", "Master PIN"),
                            subtitle = if (securitySettings.hasMasterPin()) tr("تم التعيين", "Set") else tr("غير معيّن", "Not set"),
                            iconColor = Color(0xFFFFC107),
                            enabled = true,
                            onClick = {
                                autoEnableLockAfterPin = false
                                showPinDialog = true
                            }
                        )
                        HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = LocalSadaPalette.current.textSecondary.copy(alpha = 0.12f))
                        SettingsTile(
                            icon = Icons.Default.Block,
                            title = tr("المحظورون", "Blocked Contacts"),
                            subtitle = tr("إدارة الجهات المحظورة", "Manage blocked users"),
                            iconColor = ErrorRed,
                            enabled = true,
                            onClick = onBlockedContactsClick
                        )
                    }
                }

                // Performance & Network
                item {
                    SettingsGroup(title = tr("الشبكة والطاقة", "Mesh & Power")) {
                        CompactChoiceRow(
                            icon = Icons.Default.BatteryChargingFull,
                            title = tr("استهلاك الطاقة", "Power Mode"),
                            iconColor = Color.Cyan,
                            options = listOf(
                                "high_performance" to tr("عالٍ", "High"),
                                "balanced" to tr("متوازن", "Bal"),
                                "low_power" to tr("توفير", "Low")
                            ),
                            selected = powerMode
                        ) { selected ->
                            powerMode = selected
                            onPowerModeChanged(selected)
                            scope.launch {
                                snackbarHostState.showSnackbar(tr("تم حفظ وضع الطاقة", "Power mode saved"))
                            }
                        }
                        HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = LocalSadaPalette.current.textSecondary.copy(alpha = 0.12f))
                        SettingsTile(
                            icon = Icons.Default.BatterySaver,
                            title = tr("إعدادات البطارية", "Battery Optimization"),
                            subtitle = tr("فتح إعدادات تحسين البطارية", "Open battery optimization settings"),
                            iconColor = Color(0xFF22D3EE),
                            enabled = true,
                            onClick = { openBatteryOptimizationSettings(context) }
                        )
                        HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = LocalSadaPalette.current.textSecondary.copy(alpha = 0.12f))
                        SettingsTile(
                            icon = Icons.Default.MonitorHeart,
                            title = tr("تشخيص الشبكة", "Diagnostics"),
                            subtitle = tr("مشغّل", "Active"),
                            iconColor = NeonTeal,
                            enabled = true,
                            onClick = onDiagnosticsClick
                        )
                    }
                }

                // Services & Public Channel - HIDDEN in v1.0, see docs/ROADMAP_ServiceProfile_v2.0.md
                // item {
                //     SettingsGroup(title = tr("الخدمات والقناة العامة", "Services & Public Channel")) {
                //         SettingsTile(
                //             icon = Icons.Default.Storefront,
                //             title = tr("إدارة الخدمة العامة", "Public Service Setup"),
                //             subtitle = tr("إنشاء/تعديل القناة العامة وقوالب الخدمة", "Create/edit public channel and service templates"),
                //             iconColor = Color(0xFF22D3EE),
                //             enabled = true,
                //             onClick = onGrowthClick
                //         )
                //         HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = LocalSadaPalette.current.textSecondary.copy(alpha = 0.12f))
                //         SettingsTile(
                //             icon = Icons.Default.Analytics,
                //             title = tr("لوحة نمو القناة", "Growth Studio"),
                //             subtitle = tr("إحصائيات محلية وأداء القناة", "Local analytics and channel performance"),
                //             iconColor = Color(0xFF10B981),
                //             enabled = true,
                //             onClick = onGrowthClick
                //         )
                //     }
                // }

                // About — compact card
                item {
                    SettingsGroup(title = tr("حول", "About")) {
                        // About Sada row
                        SettingsTile(
                            icon = Icons.Default.Info,
                            title = tr("حول صدى", "About Sada"),
                            subtitle = tr("المطور · التقنيات · كيف يعمل", "Developer · Tech · How it works"),
                            iconColor = CyberBlue,
                            enabled = true,
                            onClick = onAboutClick
                        )
                        HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = LocalSadaPalette.current.textSecondary.copy(alpha = 0.08f))
                        // Quick links row: Privacy | Terms | Share
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 12.dp, vertical = 10.dp),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            AboutQuickChip(
                                icon = Icons.Default.PrivacyTip,
                                label = tr("الخصوصية", "Privacy"),
                                color = Color(0xFF22D3EE),
                                modifier = Modifier.weight(1f),
                                onClick = onPrivacyClick
                            )
                            AboutQuickChip(
                                icon = Icons.Default.Gavel,
                                label = tr("الشروط", "Terms"),
                                color = Color(0xFFFFB74D),
                                modifier = Modifier.weight(1f),
                                onClick = onTermsClick
                            )
                            AboutQuickChip(
                                icon = Icons.Default.Copyright,
                                label = tr("الملكية", "IP Rights"),
                                color = Color(0xFFA78BFA),
                                modifier = Modifier.weight(1f),
                                onClick = onIpClick
                            )
                            AboutQuickChip(
                                icon = Icons.Default.Share,
                                label = tr("مشاركة", "Share"),
                                color = NeonTeal,
                                modifier = Modifier.weight(1f),
                                onClick = onShareApkClick
                            )
                        }
                        HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = LocalSadaPalette.current.textSecondary.copy(alpha = 0.08f))
                        // Version pill
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                tr("الإصدار", "Version"),
                                color = LocalSadaPalette.current.textSecondary,
                                style = MaterialTheme.typography.bodySmall
                            )
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(20.dp))
                                    .background(NeonTeal.copy(0.08f))
                                    .border(1.dp, NeonTeal.copy(0.2f), RoundedCornerShape(20.dp))
                                    .padding(horizontal = 10.dp, vertical = 3.dp)
                            ) {
                                Text(
                                    "v1.0.0 · Android",
                                    color = NeonTeal,
                                    style = MaterialTheme.typography.labelSmall,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        }
                    }
                }
                
                item { Spacer(modifier = Modifier.height(32.dp)) }
            }
        }

        if (showPinDialog) {
            AlertDialog(
                onDismissRequest = {
                    showPinDialog = false
                    pinInput = ""
                    autoEnableLockAfterPin = false
                },
                title = { Text(tr("ضبط الرمز السري", "Set Master PIN")) },
                text = {
                    OutlinedTextField(
                        value = pinInput,
                        onValueChange = { value ->
                            pinInput = value.filter { it.isDigit() }.take(6)
                        },
                        singleLine = true,
                        label = { Text(tr("6 أرقام", "6 digits")) },
                        visualTransformation = PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword)
                    )
                },
                confirmButton = {
                    TextButton(onClick = {
                        if (!securitySettings.isValidPin(pinInput)) {
                            scope.launch { snackbarHostState.showSnackbar(tr("الرمز يجب أن يكون 6 أرقام", "PIN must be 6 digits")) }
                            return@TextButton
                        }
                        val saved = securitySettings.setMasterPin(pinInput)
                        if (saved) {
                            if (autoEnableLockAfterPin) {
                                appLockEnabled = true
                                securitySettings.setAppLockEnabled(true)
                            }
                            showPinDialog = false
                            pinInput = ""
                            autoEnableLockAfterPin = false
                            scope.launch { snackbarHostState.showSnackbar(tr("تم حفظ الرمز السري", "Master PIN saved")) }
                        } else {
                            scope.launch { snackbarHostState.showSnackbar(tr("فشل حفظ الرمز السري", "Failed to save Master PIN")) }
                        }
                    }) {
                        Text(tr("حفظ", "Save"))
                    }
                },
                dismissButton = {
                    TextButton(onClick = {
                        showPinDialog = false
                        pinInput = ""
                        autoEnableLockAfterPin = false
                    }) { Text(tr("إلغاء", "Cancel")) }
                }
            )
        }

    }
    }
}

@Composable
private fun SettingsBackground() {
    val background = LocalSadaPalette.current.background
    val primaryGlow = NeonTeal.copy(alpha = 0.15f)
    val secondaryGlow = CyberBlue.copy(alpha = 0.10f)
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(
                        background,
                        background.copy(alpha = 0.96f),
                        background
                    )
                )
            )
    ) {
        Box(
            modifier = Modifier
                .align(Alignment.TopStart)
                .offset(x = (-70).dp, y = (-20).dp)
                .size(220.dp)
                .background(
                    Brush.radialGradient(
                        listOf(primaryGlow, Color.Transparent)
                    ),
                    CircleShape
                )
        )
        Box(
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .offset(x = 70.dp, y = 50.dp)
                .size(240.dp)
                .background(
                    Brush.radialGradient(
                        listOf(secondaryGlow, Color.Transparent)
                    ),
                    CircleShape
                )
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileSection(
    displayName: String,
    initialStatusText: String,
    initialStatusExpiresAtMs: Long,
    onPublishStatus: (String, Long) -> Unit,
    onClearStatus: () -> Unit,
) {
    var selectedStatus by remember { mutableStateOf(initialStatusText) }
    var selectedExpiresAtMs by remember { mutableStateOf(initialStatusExpiresAtMs) }
    var customStatusDraft by remember { mutableStateOf(initialStatusText.take(120)) }
    var showStatusEditor by remember { mutableStateOf(false) }
    val now = System.currentTimeMillis()
    val isActive = selectedStatus.isNotBlank() && selectedExpiresAtMs > now
    val presets = listOf(
        tr("متاح", "Available"),
        tr("مشغول في العمل", "Busy at work"),
        tr("عم أدرس", "Studying"),
        tr("في الطريق", "On the way"),
        tr("غير متاح الآن", "Not available now")
    )

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(
                Brush.linearGradient(
                    listOf(
                        LocalSadaPalette.current.surfaceVariant,
                        Color(0xFF0E1520)
                    )
                )
            )
            .border(
                width = 1.dp,
                brush = Brush.linearGradient(listOf(NeonTeal.copy(0.3f), CyberBlue.copy(0.15f))),
                shape = RoundedCornerShape(20.dp)
            )
    ) {
        // Background glow blob
        Box(
            modifier = Modifier
                .size(140.dp)
                .align(Alignment.TopEnd)
                .offset(x = 40.dp, y = (-30).dp)
                .background(
                    Brush.radialGradient(listOf(CyberBlue.copy(0.12f), Color.Transparent)),
                    CircleShape
                )
        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 18.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                // Avatar with gradient ring
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.size(68.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .clip(CircleShape)
                            .background(
                                Brush.sweepGradient(listOf(NeonTeal, CyberBlue, NeonTeal))
                            )
                    )
                    Box(
                        modifier = Modifier
                            .size(62.dp)
                            .clip(CircleShape)
                            .background(LocalSadaPalette.current.surfaceVariant),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Default.Person,
                            contentDescription = null,
                            tint = LocalSadaPalette.current.textPrimary.copy(alpha = 0.9f),
                            modifier = Modifier.size(30.dp)
                        )
                    }
                }
                Spacer(Modifier.width(14.dp))
                Column {
                    Text(
                        text = displayName,
                        style = MaterialTheme.typography.titleLarge,
                        color = LocalSadaPalette.current.textPrimary,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(Modifier.height(4.dp))
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(7.dp)
                                .clip(CircleShape)
                                .background(if (isActive) LocalSadaPalette.current.successGreen else LocalSadaPalette.current.textSecondary)
                        )
                        Text(
                            text = if (isActive) tr("نشط", "Active") else tr("غير نشط", "Away"),
                            style = MaterialTheme.typography.labelMedium,
                            color = if (isActive) LocalSadaPalette.current.successGreen else LocalSadaPalette.current.textSecondary
                        )
                    }
                }
            }

            // Status row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(LocalSadaPalette.current.background.copy(alpha = 0.5f))
                    .border(1.dp, LocalSadaPalette.current.textSecondary.copy(0.12f), RoundedCornerShape(12.dp))
                    .padding(horizontal = 14.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.AutoAwesome,
                    contentDescription = null,
                    tint = if (isActive) NeonTeal else LocalSadaPalette.current.textSecondary,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(Modifier.width(10.dp))
                Text(
                    text = if (isActive) selectedStatus else tr("اضبط حالتك...", "Set your status..."),
                    color = if (isActive) LocalSadaPalette.current.textPrimary else LocalSadaPalette.current.textSecondary,
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.weight(1f),
                    maxLines = 1
                )
                TextButton(
                    onClick = { showStatusEditor = true },
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = tr("تعديل", "Edit"),
                        color = NeonTeal,
                        style = MaterialTheme.typography.labelMedium
                    )
                }
            }

            if (isActive) {
                TextButton(
                    onClick = {
                        selectedStatus = ""
                        selectedExpiresAtMs = 0L
                        customStatusDraft = ""
                        onClearStatus()
                    },
                    contentPadding = PaddingValues(0.dp)
                ) {
                    Text(
                        tr("مسح الحالة", "Clear status"),
                        color = LocalSadaPalette.current.errorRed.copy(alpha = 0.8f),
                        style = MaterialTheme.typography.labelMedium
                    )
                }
            }
        }
    }

    if (showStatusEditor) {
        ModalBottomSheet(
            onDismissRequest = { showStatusEditor = false }
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
            ) {
                Text(
                    text = tr("تعديل الحالة", "Edit status"),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(10.dp))
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(presets) { preset ->
                        FilterChip(
                            selected = selectedStatus == preset && isActive,
                            onClick = {
                                customStatusDraft = preset
                            },
                            label = { Text(preset) }
                        )
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = customStatusDraft,
                    onValueChange = { customStatusDraft = it.take(120) },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text(tr("حالة مخصصة", "Custom status")) },
                    placeholder = { Text(tr("اكتب حالتك...", "Write your status...")) },
                    minLines = 1,
                    maxLines = 2,
                    singleLine = false
                )
                Text(
                    text = "${customStatusDraft.length}/120",
                    color = LocalSadaPalette.current.textSecondary,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 4.dp),
                    textAlign = androidx.compose.ui.text.style.TextAlign.End
                )
                Spacer(modifier = Modifier.height(12.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = { showStatusEditor = false },
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(tr("إلغاء", "Cancel"))
                    }
                    Button(
                        onClick = {
                            val text = customStatusDraft.trim()
                            if (text.isBlank()) return@Button
                            val expiresAt = System.currentTimeMillis() + 24L * 60L * 60L * 1000L
                            selectedStatus = text
                            selectedExpiresAtMs = expiresAt
                            onPublishStatus(text, expiresAt)
                            showStatusEditor = false
                        },
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(tr("حفظ", "Save"))
                    }
                }
                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }
}

@Composable
fun SettingsGroup(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Column {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(start = 4.dp, bottom = 10.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(width = 3.dp, height = 14.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(
                        Brush.verticalGradient(listOf(NeonTeal, CyberBlue))
                    )
            )
            Spacer(Modifier.width(8.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.labelLarge,
                color = LocalSadaPalette.current.textSecondary,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 0.8.sp
            )
        }
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(18.dp),
            color = LocalSadaPalette.current.surface.copy(alpha = 0.95f),
            border = androidx.compose.foundation.BorderStroke(
                1.dp, LocalSadaPalette.current.textSecondary.copy(alpha = 0.1f)
            )
        ) {
            Column(content = content)
        }
    }
}

@Composable
fun SettingsTile(
    icon: ImageVector,
    title: String,
    subtitle: String? = null,
    iconColor: Color = NeonTeal,
    enabled: Boolean = true,
    onClick: () -> Unit = {}
) {
    val contentAlpha = if (enabled) 1f else 0.4f
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(42.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(iconColor.copy(alpha = 0.13f * contentAlpha)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = iconColor.copy(alpha = contentAlpha),
                modifier = Modifier.size(20.dp)
            )
        }
        Spacer(Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                title,
                color = LocalSadaPalette.current.textPrimary.copy(alpha = contentAlpha),
                fontWeight = FontWeight.SemiBold,
                style = MaterialTheme.typography.bodyMedium,
            )
            if (subtitle != null) {
                Spacer(Modifier.height(2.dp))
                Text(
                    subtitle,
                    color = LocalSadaPalette.current.textSecondary.copy(alpha = if (enabled) 1f else 0.5f),
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
        Icon(
            if (enabled) Icons.AutoMirrored.Filled.KeyboardArrowRight else Icons.Default.Lock,
            contentDescription = null,
            tint = LocalSadaPalette.current.textSecondary.copy(alpha = if (enabled) 0.4f else 0.3f),
            modifier = Modifier.size(18.dp)
        )
    }
}

@Composable
private fun CompactChoiceRow(
    icon: ImageVector,
    title: String,
    iconColor: Color,
    options: List<Pair<String, String>>,
    selected: String,
    onSelect: (String) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(38.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(iconColor.copy(0.13f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, null, tint = iconColor, modifier = Modifier.size(18.dp))
        }
        Spacer(Modifier.width(12.dp))
        Text(
            title,
            color = LocalSadaPalette.current.textPrimary,
            fontWeight = FontWeight.SemiBold,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.weight(1f)
        )
        AnimatedSegmentedControl(options = options, selected = selected, onSelect = onSelect)
    }
}

@Composable
private fun AnimatedSegmentedControl(
    options: List<Pair<String, String>>,
    selected: String,
    onSelect: (String) -> Unit
) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(10.dp))
            .background(LocalSadaPalette.current.background)
            .border(1.dp, LocalSadaPalette.current.textSecondary.copy(0.12f), RoundedCornerShape(10.dp))
            .padding(3.dp),
        horizontalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        options.forEach { (value, label) ->
            val isSelected = value == selected
            val bgColor by animateColorAsState(
                targetValue = if (isSelected) NeonTeal.copy(0.18f) else Color.Transparent,
                animationSpec = spring(stiffness = Spring.StiffnessMediumLow),
                label = "seg_bg"
            )
            val textColor by animateColorAsState(
                targetValue = if (isSelected) NeonTeal else LocalSadaPalette.current.textSecondary,
                animationSpec = spring(stiffness = Spring.StiffnessMediumLow),
                label = "seg_text"
            )
            val borderColor by animateColorAsState(
                targetValue = if (isSelected) NeonTeal.copy(0.4f) else Color.Transparent,
                animationSpec = spring(stiffness = Spring.StiffnessMediumLow),
                label = "seg_border"
            )
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .background(bgColor)
                    .border(1.dp, borderColor, RoundedCornerShape(8.dp))
                    .clickable { onSelect(value) }
                    .padding(horizontal = 10.dp, vertical = 5.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    label,
                    color = textColor,
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                )
            }
        }
    }
}

@Composable
private fun AboutQuickChip(
    icon: ImageVector,
    label: String,
    color: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(color.copy(0.08f))
            .border(1.dp, color.copy(0.2f), RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .padding(vertical = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(icon, null, tint = color, modifier = Modifier.size(18.dp))
        Text(label, color = color, style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
private fun ChoiceDialog(
    title: String,
    choices: List<Pair<String, String>>,
    selected: String,
    onDismiss: () -> Unit,
    onSelect: (String) -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                choices.forEach { (value, label) ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSelect(value) }
                            .padding(vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = selected == value,
                            onClick = { onSelect(value) }
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(label)
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) { Text(tr("إغلاق", "Close")) }
        }
    )
}

private fun openDeviceSecuritySettings(context: android.content.Context) {
    val intent = Intent(Settings.ACTION_SECURITY_SETTINGS).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    context.startActivity(intent)
}

private fun openBatteryOptimizationSettings(context: android.content.Context) {
    val powerManager = context.getSystemService(android.content.Context.POWER_SERVICE) as PowerManager
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
        !powerManager.isIgnoringBatteryOptimizations(context.packageName)
    ) {
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:${context.packageName}")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    } else {
        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }
}

@Composable
@OptIn(ExperimentalMaterial3Api::class)
fun AboutSadaPage(
    onBack: () -> Unit,
    isArabic: Boolean
) {
    val title = if (isArabic) "حول صدى" else "About Sada"

    Box(modifier = Modifier.fillMaxSize()) {
        MeshBackground()
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text(title, fontWeight = FontWeight.ExtraBold, color = LocalSadaPalette.current.textPrimary) },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, null, tint = LocalSadaPalette.current.textPrimary)
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = LocalSadaPalette.current.background.copy(alpha = 0.85f))
                )
            },
            containerColor = Color.Transparent
        ) { padding ->
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                // ── Hero Card ──
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(24.dp))
                            .background(
                                Brush.linearGradient(
                                    listOf(Color(0xFF0B1E33), Color(0xFF0A0A0F), LocalSadaPalette.current.surfaceVariant)
                                )
                            )
                            .border(
                                1.dp,
                                Brush.linearGradient(listOf(NeonTeal.copy(0.4f), CyberBlue.copy(0.2f), Color.Transparent)),
                                RoundedCornerShape(24.dp)
                            )
                    ) {
                        // Glow blobs
                        Box(
                            Modifier.size(200.dp).align(Alignment.TopStart)
                                .offset((-60).dp, (-60).dp)
                                .background(Brush.radialGradient(listOf(NeonTeal.copy(0.1f), Color.Transparent)), CircleShape)
                        )
                        Box(
                            Modifier.size(160.dp).align(Alignment.BottomEnd)
                                .offset(50.dp, 50.dp)
                                .background(Brush.radialGradient(listOf(CyberBlue.copy(0.12f), Color.Transparent)), CircleShape)
                        )
                        Column(
                            modifier = Modifier.fillMaxWidth().padding(24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            // Logo with glow ring
                            Box(contentAlignment = Alignment.Center, modifier = Modifier.size(90.dp)) {
                                Box(
                                    Modifier.fillMaxSize().clip(RoundedCornerShape(22.dp))
                                        .background(Brush.sweepGradient(listOf(NeonTeal, CyberBlue, NeonTeal)))
                                )
                                Box(
                                    Modifier.size(84.dp).clip(RoundedCornerShape(20.dp))
                                        .background(Color(0xFF0B1E33)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Image(
                                        painter = painterResource(id = R.drawable.logo),
                                        contentDescription = null,
                                        modifier = Modifier.size(68.dp)
                                    )
                                }
                            }
                            Text(
                                text = if (isArabic) "صدى" else "Sada",
                                style = MaterialTheme.typography.headlineMedium,
                                fontWeight = FontWeight.ExtraBold,
                                color = LocalSadaPalette.current.textPrimary
                            )
                            // Version badge
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(20.dp))
                                        .background(NeonTeal.copy(alpha = 0.15f))
                                        .border(1.dp, NeonTeal.copy(0.3f), RoundedCornerShape(20.dp))
                                        .padding(horizontal = 12.dp, vertical = 4.dp)
                                ) {
                                    Text("v1.0.0", color = NeonTeal, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold)
                                }
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(20.dp))
                                        .background(CyberBlue.copy(alpha = 0.12f))
                                        .border(1.dp, CyberBlue.copy(0.25f), RoundedCornerShape(20.dp))
                                        .padding(horizontal = 12.dp, vertical = 4.dp)
                                ) {
                                    Text("Android", color = CyberBlue, style = MaterialTheme.typography.labelMedium)
                                }
                            }
                            Text(
                                text = LegalContent.about(isArabic),
                                color = LocalSadaPalette.current.textSecondary,
                                style = MaterialTheme.typography.bodySmall,
                                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                                lineHeight = 20.sp
                            )
                        }
                    }
                }

                // ── How it works ──
                item {
                    AboutSectionCard(
                        title = if (isArabic) "كيف يعمل صدى؟" else "How Sada Works"
                    ) {
                        val steps = if (isArabic) listOf(
                            Triple(Icons.Default.Wifi, "الاكتشاف الراديوي", "يبث جهازك إشارة Wi-Fi Direct وBLE للبحث عن أجهزة أخرى"),
                            Triple(Icons.Default.Link, "الاتصال المباشر P2P", "يتم بناء جسر آمن ومشفر مباشرةً بين جهازين بثوانٍ"),
                            Triple(Icons.Default.Lock, "التمرير المشفر", "الرسائل مشفرة E2E بـ Libsodium — تقفز من جهاز لآخر حتى تصل")
                        ) else listOf(
                            Triple(Icons.Default.Wifi, "Radio Discovery", "Your device broadcasts Wi-Fi Direct & BLE signals to find peers"),
                            Triple(Icons.Default.Link, "Direct P2P Bridge", "A secure encrypted bridge forms between two devices in seconds"),
                            Triple(Icons.Default.Lock, "Encrypted Relay", "Messages are E2E encrypted via Libsodium — hopping device-to-device until delivered")
                        )
                        steps.forEachIndexed { i, (icon, heading, detail) ->
                            Row(
                                modifier = Modifier.padding(vertical = 6.dp),
                                verticalAlignment = Alignment.Top
                            ) {
                                Box(
                                    modifier = Modifier.size(36.dp).clip(RoundedCornerShape(10.dp))
                                        .background(NeonTeal.copy(0.12f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        "${i + 1}",
                                        color = NeonTeal,
                                        fontWeight = FontWeight.ExtraBold,
                                        style = MaterialTheme.typography.labelLarge
                                    )
                                }
                                Spacer(Modifier.width(12.dp))
                                Column {
                                    Text(heading, color = LocalSadaPalette.current.textPrimary, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
                                    Text(detail, color = LocalSadaPalette.current.textSecondary, style = MaterialTheme.typography.bodySmall, lineHeight = 18.sp)
                                }
                            }
                            if (i < steps.lastIndex) HorizontalDivider(
                                modifier = Modifier.padding(start = 48.dp, top = 4.dp, bottom = 4.dp),
                                color = LocalSadaPalette.current.textSecondary.copy(0.08f)
                            )
                        }
                    }
                }

                // ── Tech Stack ──
                item {
                    AboutSectionCard(
                        title = if (isArabic) "التقنيات المستخدمة" else "Tech Stack"
                    ) {
                        val techs = listOf(
                            "Libsodium E2EE" to NeonTeal,
                            "Wi-Fi Direct" to CyberBlue,
                            "BLE Mesh" to Color(0xFF7F5AF0),
                            "Android Keystore" to LocalSadaPalette.current.successGreen,
                            "Room DB" to Color(0xFFF59E0B),
                            "Hilt DI" to Color(0xFFEC4899),
                            "Jetpack Compose" to CyberBlue,
                            "Kotlin Coroutines" to Color(0xFF7F5AF0)
                        )
                        @OptIn(androidx.compose.foundation.layout.ExperimentalLayoutApi::class)
                        androidx.compose.foundation.layout.FlowRow(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            techs.forEach { (label, color) ->
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(20.dp))
                                        .background(color.copy(alpha = 0.1f))
                                        .border(1.dp, color.copy(0.3f), RoundedCornerShape(20.dp))
                                        .padding(horizontal = 12.dp, vertical = 6.dp)
                                ) {
                                    Text(label, color = color, style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.SemiBold)
                                }
                            }
                        }
                    }
                }

                // ── Developer Hero Card ──
                item {
                    DeveloperHeroCard(isArabic = isArabic)
                }

                // ── Zero-Data Guarantee ──
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(18.dp))
                            .background(Brush.linearGradient(listOf(LocalSadaPalette.current.successGreen.copy(0.08f), Color(0xFF0A1A14))))
                            .border(1.dp, LocalSadaPalette.current.successGreen.copy(0.25f), RoundedCornerShape(18.dp))
                            .padding(18.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                            Box(
                                Modifier.size(44.dp).clip(CircleShape).background(LocalSadaPalette.current.successGreen.copy(0.15f)),
                                contentAlignment = Alignment.Center
                            ) {
                                Text("🛡️", style = MaterialTheme.typography.titleLarge)
                            }
                            Column {
                                Text(
                                    if (isArabic) "صفر بيانات · صفر خوادم" else "Zero Data · Zero Servers",
                                    color = LocalSadaPalette.current.successGreen, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.bodyMedium
                                )
                                Text(
                                    if (isArabic) "لا يُجمع أي بيانات شخصية ولا تُرسل لأي خادم خارجي" else "No personal data collected or sent to any external server",
                                    color = LocalSadaPalette.current.textSecondary, style = MaterialTheme.typography.bodySmall, lineHeight = 18.sp
                                )
                            }
                        }
                    }
                }

                item { Spacer(Modifier.height(32.dp)) }
            }
        }
    }
}

@Composable
private fun AboutSectionCard(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(LocalSadaPalette.current.surface.copy(alpha = 0.95f))
            .border(1.dp, LocalSadaPalette.current.textSecondary.copy(0.1f), RoundedCornerShape(18.dp))
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier.size(width = 3.dp, height = 14.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(Brush.verticalGradient(listOf(NeonTeal, CyberBlue)))
            )
            Spacer(Modifier.width(8.dp))
            Text(title, color = LocalSadaPalette.current.textPrimary, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.bodyLarge)
        }
        content()
    }
}

@Composable
@OptIn(ExperimentalMaterial3Api::class)
fun LegalTextPage(
    title: String,
    content: String,
    onBack: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(title, fontWeight = FontWeight.ExtraBold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent)
            )
        },
        containerColor = Color.Transparent
    ) { padding ->
        SelectionContainer {
            Text(
                text = content,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(horizontal = 16.dp, vertical = 12.dp)
                    .verticalScroll(rememberScrollState()),
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.92f),
                lineHeight = 22.sp
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun DeveloperHeroCard(isArabic: Boolean) {
    val c = LocalSadaPalette.current
    val context = LocalContext.current

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(
                Brush.verticalGradient(
                    listOf(
                        c.surface.copy(alpha = 0.98f),
                        c.surfaceVariant.copy(alpha = 0.9f)
                    )
                )
            )
            .border(1.dp, c.neonTeal.copy(0.2f), RoundedCornerShape(24.dp))
            .padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Animated glowing avatar
        Box(contentAlignment = Alignment.Center, modifier = Modifier.size(110.dp)) {
            // Outer glow ring
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clip(CircleShape)
                    .background(Brush.sweepGradient(listOf(NeonTeal, CyberBlue, Color(0xFF8B5CF6), NeonTeal)))
            )
            // Inner photo container
            Box(
                modifier = Modifier
                    .size(100.dp)
                    .clip(CircleShape)
                    .background(c.background),
                contentAlignment = Alignment.Center
            ) {
                Image(
                    painter = painterResource(id = R.drawable.developer_obada),
                    contentDescription = "Obada Dallo",
                    modifier = Modifier.fillMaxSize()
                )
            }
        }

        Spacer(Modifier.height(16.dp))

        // Name with gradient effect
        Text(
            if (isArabic) "عبادة دللو" else "Obada Dallo",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.ExtraBold,
            color = c.textPrimary
        )

        Spacer(Modifier.height(4.dp))

        // Title
        Text(
            if (isArabic) "المؤسس والمطور الرئيسي" else "Founder & Lead Developer",
            color = c.neonTeal,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.SemiBold
        )

        Spacer(Modifier.height(12.dp))

        // Tagline in italics
        Text(
            "\"Building digital shields for a safer internet.\"",
            color = c.textSecondary,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
            textAlign = TextAlign.Center
        )

        Spacer(Modifier.height(20.dp))

        // Social buttons row
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(10.dp, Alignment.CenterHorizontally),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            // GitHub
            SocialButton(
                label = "GitHub",
                icon = Icons.Default.Code,
                color = Color(0xFF181717),
                onClick = { openUrl(context, "https://github.com/obadadallo95") }
            )
            // LinkedIn
            SocialButton(
                label = "LinkedIn",
                icon = Icons.Default.Business,
                color = Color(0xFF0077B5),
                onClick = { openUrl(context, "https://www.linkedin.com/in/obada-dallo-777a47a9/") }
            )
            // Facebook
            SocialButton(
                label = "Facebook",
                icon = Icons.Default.Share,
                color = Color(0xFF1877F2),
                onClick = { openUrl(context, "https://www.facebook.com/obada.dallo33") }
            )
            // Telegram
            SocialButton(
                label = "Telegram",
                icon = Icons.Default.Send,
                color = Color(0xFF2CA5E0),
                onClick = { openUrl(context, "https://t.me/obada_dallo95") }
            )
            // Email
            SocialButton(
                label = "Email",
                icon = Icons.Default.Email,
                color = Color(0xFFD14836),
                onClick = { openEmail(context, "obada.dallo95@gmail.com") }
            )
        }
    }
}

@Composable
private fun SocialButton(
    label: String,
    icon: ImageVector,
    color: Color,
    onClick: () -> Unit
) {
    val c = LocalSadaPalette.current
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(12.dp),
        color = color.copy(alpha = 0.15f),
        border = androidx.compose.foundation.BorderStroke(1.dp, color.copy(alpha = 0.4f))
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
        ) {
            Icon(icon, null, tint = color, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(6.dp))
            Text(label, color = c.textPrimary, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold)
        }
    }
}

private fun openUrl(context: android.content.Context, url: String) {
    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
    context.startActivity(intent)
}

private fun openEmail(context: android.content.Context, email: String) {
    val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:$email"))
    context.startActivity(intent)
}
