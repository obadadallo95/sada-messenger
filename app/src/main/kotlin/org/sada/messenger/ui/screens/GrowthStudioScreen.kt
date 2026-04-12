package org.sada.messenger.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Analytics
import androidx.compose.material.icons.filled.QrCode
import androidx.compose.material.icons.filled.Store
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import org.sada.messenger.growth.LocalAnalytics
import org.sada.messenger.growth.ServiceProfileState
import org.sada.messenger.growth.ServiceProfileStore
import org.sada.messenger.growth.ServiceProfileTemplates
import org.sada.messenger.ui.theme.*
import org.sada.messenger.ui.utils.tr

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GrowthStudioScreen(onBack: () -> Unit) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val store = remember { ServiceProfileStore(context) }
    val analytics = remember { LocalAnalytics(context) }

    var profile by remember { mutableStateOf(store.load()) }
    var snapshot by remember { mutableStateOf(analytics.snapshot()) }

    val selectedTemplate = ServiceProfileTemplates.findById(profile.selectedTemplateId)

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(tr("نمو القناة العامة", "Growth Studio"), fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = SadaSurface)
            )
        },
        containerColor = SadaBackground
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = SadaSurfaceVariant),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Store, contentDescription = null, tint = SadaPrimary)
                            Text(
                                tr("قوالب بروفايل الخدمة", "Service Profile Templates"),
                                modifier = Modifier.padding(start = 8.dp),
                                fontWeight = FontWeight.SemiBold
                            )
                        }

                        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            items(ServiceProfileTemplates.all) { template ->
                                val isSelected = template.id == profile.selectedTemplateId
                                FilterChip(
                                    selected = isSelected,
                                    onClick = {
                                        profile = profile.copy(
                                            selectedTemplateId = template.id,
                                            displayName = if (profile.displayName.isBlank()) {
                                                if (isArabic()) template.titleAr else template.titleEn
                                            } else profile.displayName,
                                            description = if (profile.description.isBlank()) {
                                                if (isArabic()) template.descAr else template.descEn
                                            } else profile.description,
                                            workingHours = if (profile.workingHours.isBlank()) {
                                                if (isArabic()) template.defaultWorkingHoursAr else template.defaultWorkingHoursEn
                                            } else profile.workingHours,
                                            deliveryAvailable = profile.deliveryAvailable || template.supportsDelivery
                                        )
                                    },
                                    label = {
                                        Text("${template.emoji} ${if (isArabic()) template.titleAr else template.titleEn}")
                                    }
                                )
                            }
                        }
                        TextButton(
                            onClick = {
                                profile = profile.copy(
                                    displayName = if (isArabic()) selectedTemplate.titleAr else selectedTemplate.titleEn,
                                    description = if (isArabic()) selectedTemplate.descAr else selectedTemplate.descEn,
                                    workingHours = if (isArabic()) selectedTemplate.defaultWorkingHoursAr else selectedTemplate.defaultWorkingHoursEn,
                                    deliveryAvailable = selectedTemplate.supportsDelivery,
                                    deliveryRadiusKm = if (selectedTemplate.supportsDelivery) "5" else "0",
                                    quickReply = tr("مرحبًا، وصلنا طلبك وسنرد عليك قريبًا.", "Hi, we received your request and will reply shortly.")
                                )
                            }
                        ) {
                            Text(tr("تعبئة تلقائية من القالب", "Auto-fill from template"))
                        }

                        OutlinedTextField(
                            value = profile.displayName,
                            onValueChange = { profile = profile.copy(displayName = it) },
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text(tr("اسم الخدمة", "Service Name")) },
                            singleLine = true
                        )

                        OutlinedTextField(
                            value = profile.description,
                            onValueChange = { profile = profile.copy(description = it) },
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text(tr("وصف الخدمة", "Service Description")) },
                            minLines = 2,
                            maxLines = 4
                        )
                        OutlinedTextField(
                            value = profile.address,
                            onValueChange = { profile = profile.copy(address = it) },
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text(tr("العنوان", "Address")) },
                            singleLine = true
                        )
                        OutlinedTextField(
                            value = profile.workingHours,
                            onValueChange = { profile = profile.copy(workingHours = it) },
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text(tr("أوقات العمل", "Working Hours")) },
                            singleLine = true
                        )
                        OutlinedTextField(
                            value = profile.contactInfo,
                            onValueChange = { profile = profile.copy(contactInfo = it) },
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text(tr("رقم التواصل / واتساب", "Contact / WhatsApp")) },
                            singleLine = true
                        )

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(tr("خدمة التوصيل", "Delivery Service"))
                            Switch(
                                checked = profile.deliveryAvailable,
                                onCheckedChange = { profile = profile.copy(deliveryAvailable = it) }
                            )
                        }
                        if (profile.deliveryAvailable) {
                            OutlinedTextField(
                                value = profile.deliveryRadiusKm,
                                onValueChange = { profile = profile.copy(deliveryRadiusKm = it.filter { ch -> ch.isDigit() }.take(3)) },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text(tr("نطاق التوصيل (كم)", "Delivery Radius (km)")) },
                                singleLine = true,
                                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Number)
                            )
                        }
                        OutlinedTextField(
                            value = profile.quickReply,
                            onValueChange = { profile = profile.copy(quickReply = it.take(120)) },
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text(tr("رد سريع افتراضي", "Default Quick Reply")) },
                            singleLine = false,
                            minLines = 1,
                            maxLines = 2
                        )
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(tr("تفعيل القناة العامة", "Enable Public Channel"))
                            Switch(
                                checked = profile.publicChannelEnabled,
                                onCheckedChange = { profile = profile.copy(publicChannelEnabled = it) }
                            )
                        }

                        Button(
                            onClick = { store.save(profile) },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Text(tr("حفظ البروفايل", "Save Profile"))
                        }
                    }
                }
            }

            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = SadaSurfaceVariant),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Analytics, contentDescription = null, tint = Color(0xFF22D3EE))
                            Text(
                                tr("Analytics محلية", "Local Analytics"),
                                modifier = Modifier.padding(start = 8.dp),
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                        MetricLine(tr("فتح شاشة المسح", "QR Scan Opened"), snapshot.qrScanOpened)
                        MetricLine(tr("نجاح المسح", "QR Scan Success"), snapshot.qrScanSuccess)
                        MetricLine(tr("مشاركة QR", "QR Shares"), snapshot.qrShared)
                        MetricLine(tr("إضافة جهات عبر QR", "Contacts Added via QR"), snapshot.contactsAddedViaQr)

                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            TextButton(onClick = {
                                snapshot = analytics.snapshot()
                            }) {
                                Text(tr("تحديث", "Refresh"))
                            }
                            TextButton(onClick = {
                                analytics.reset()
                                snapshot = analytics.snapshot()
                            }) {
                                Text(tr("تصفير", "Reset"), color = Color.Red)
                            }
                        }
                    }
                }
            }

            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = SadaSurface),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.QrCode, contentDescription = null, tint = SadaPrimary)
                            Text(
                                tr("المعاينة الحالية", "Current Preview"),
                                modifier = Modifier.padding(start = 8.dp),
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                        Text(
                            text = "${selectedTemplate.emoji} ${profile.displayName.ifBlank { if (isArabic()) selectedTemplate.titleAr else selectedTemplate.titleEn }}",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = profile.description.ifBlank { if (isArabic()) selectedTemplate.descAr else selectedTemplate.descEn },
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.75f)
                        )
                        if (profile.address.isNotBlank()) {
                            Text(
                                text = "${tr("العنوان", "Address")}: ${profile.address}",
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.75f)
                            )
                        }
                        if (profile.workingHours.isNotBlank()) {
                            Text(
                                text = "${tr("أوقات العمل", "Working Hours")}: ${profile.workingHours}",
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.75f)
                            )
                        }
                        if (profile.contactInfo.isNotBlank()) {
                            Text(
                                text = "${tr("التواصل", "Contact")}: ${profile.contactInfo}",
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.75f)
                            )
                        }
                        Text(
                            text = if (profile.deliveryAvailable) {
                                tr("التوصيل متاح حتى ${profile.deliveryRadiusKm.ifBlank { "5" }} كم", "Delivery available up to ${profile.deliveryRadiusKm.ifBlank { "5" }} km")
                            } else {
                                tr("التوصيل غير متاح", "Delivery unavailable")
                            },
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.75f)
                        )
                        if (profile.quickReply.isNotBlank()) {
                            Text(
                                text = "${tr("الرد السريع", "Quick reply")}: ${profile.quickReply}",
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.75f)
                            )
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = if (profile.publicChannelEnabled) tr("القناة العامة: مفعلة", "Public channel: enabled") else tr("القناة العامة: متوقفة", "Public channel: paused"),
                            color = if (profile.publicChannelEnabled) Color(0xFF10B981) else Color(0xFFF59E0B),
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MetricLine(label: String, value: Long) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f))
        Text(value.toString(), fontWeight = FontWeight.Bold)
    }
}

private fun isArabic(): Boolean = java.util.Locale.getDefault().language.startsWith("ar")
