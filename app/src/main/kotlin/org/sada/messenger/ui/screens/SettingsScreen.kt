package org.sada.messenger.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.sada.messenger.R
import org.sada.messenger.ui.theme.NeonTeal
import org.sada.messenger.ui.theme.CyberBlue

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit,
    onMyQrClick: () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        MeshBackground()

        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("الإعدادات / Settings", fontWeight = FontWeight.ExtraBold) },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(Icons.Default.ArrowBack, contentDescription = null)
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent)
                )
            },
            containerColor = Color.Transparent
        ) { padding ->
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Profile Section
                item {
                    ProfileSection(onMyQrClick = onMyQrClick)
                }

                // Appearance Group
                item {
                    SettingsGroup(title = "المظهر / Appearance") {
                        SettingsTile(
                            icon = Icons.Default.Palette,
                            title = "المظهر / Theme",
                            subtitle = "Dark Mode",
                            iconColor = Color.Magenta
                        )
                        HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = Color.White.copy(alpha = 0.05f))
                        SettingsTile(
                            icon = Icons.Default.Language,
                            title = "اللغة / Language",
                            subtitle = "العربية / Arabic",
                            iconColor = Color.Green
                        )
                    }
                }

                // Security Group
                item {
                    SettingsGroup(title = "الأمان والقفل / Security") {
                        SettingsTile(
                            icon = Icons.Default.Fingerprint,
                            title = "قفل التطبيق / App Lock",
                            subtitle = "Enabled",
                            iconColor = CyberBlue
                        )
                        HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = Color.White.copy(alpha = 0.05f))
                        SettingsTile(
                            icon = Icons.Default.VpnKey,
                            title = "تغيير الرمز / Master PIN",
                            iconColor = Color.Yellow
                        )
                    }
                }

                // Performance & Network
                item {
                    SettingsGroup(title = "الشبكة والطاقة / Mesh & Power") {
                        SettingsTile(
                            icon = Icons.Default.BatteryChargingFull,
                            title = "استهلاك الطاقة / Power Mode",
                            subtitle = "Balanced",
                            iconColor = Color.Cyan
                        )
                        HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = Color.White.copy(alpha = 0.05f))
                        SettingsTile(
                            icon = Icons.Default.MonitorHeart,
                            title = "تشخيص الشبكة / Diagnostics",
                            iconColor = NeonTeal
                        )
                    }
                }

                // About
                item {
                    SettingsGroup(title = "حول / About") {
                        SettingsTile(
                            icon = Icons.Default.Info,
                            title = "حول صدى / About Sada",
                            iconColor = Color.White
                        )
                    }
                }
                
                item { Spacer(modifier = Modifier.height(32.dp)) }
            }
        }
    }
}

@Composable
fun ProfileSection(onMyQrClick: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(contentAlignment = Alignment.BottomEnd) {
            Surface(
                shape = CircleShape,
                modifier = Modifier.size(110.dp),
                color = NeonTeal.copy(alpha = 0.1f),
                border = androidx.compose.foundation.BorderStroke(2.dp, NeonTeal)
            ) {
                Icon(
                    Icons.Default.Person,
                    contentDescription = null,
                    modifier = Modifier.padding(20.dp),
                    tint = NeonTeal
                )
            }
            Surface(
                shape = CircleShape,
                color = NeonTeal,
                modifier = Modifier.size(32.dp),
                border = androidx.compose.foundation.BorderStroke(2.dp, Color.Black)
            ) {
                IconButton(onClick = {}) {
                    Icon(Icons.Default.Edit, contentDescription = null, modifier = Modifier.size(16.dp), tint = Color.Black)
                }
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            "Obada Dallo", // This would come from KeyManager/Prefs
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = Color.White
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        OutlinedButton(
            onClick = onMyQrClick,
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.outlinedButtonColors(contentColor = NeonTeal),
            border = androidx.compose.foundation.BorderStroke(1.dp, NeonTeal.copy(alpha = 0.5f))
        ) {
            Icon(Icons.Default.QrCode, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text("كودي الشخصي / My QR Code")
        }
    }
}

@Composable
fun SettingsGroup(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Column {
        Text(
            text = title,
            style = MaterialTheme.typography.labelLarge,
            color = Color.White.copy(alpha = 0.5f),
            modifier = Modifier.padding(start = 8.dp, bottom = 8.dp)
        )
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(24.dp),
            color = Color.White.copy(alpha = 0.05f),
            border = androidx.compose.foundation.BorderStroke(
                1.dp,
                Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.1f), Color.Transparent))
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
    onClick: () -> Unit = {}
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(
            shape = RoundedCornerShape(12.dp),
            color = iconColor.copy(alpha = 0.1f),
            modifier = Modifier.size(40.dp)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = iconColor, modifier = Modifier.size(20.dp))
            }
        }
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(modifier = Modifier.weight(1.0f)) {
            Text(title, color = Color.White, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.bodyLarge)
            if (subtitle != null) {
                Text(subtitle, color = Color.White.copy(alpha = 0.5f), style = MaterialTheme.typography.bodySmall)
            }
        }
        
        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color.White.copy(alpha = 0.2f))
    }
}
