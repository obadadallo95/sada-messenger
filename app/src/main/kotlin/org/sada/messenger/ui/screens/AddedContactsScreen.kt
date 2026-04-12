package org.sada.messenger.ui.screens

import android.content.Context
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Storefront
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.LocalShipping
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.sada.messenger.data.entities.ContactEntity
import org.sada.messenger.ui.theme.*
import org.sada.messenger.ui.viewmodels.ContactsViewModel
import org.sada.messenger.ui.utils.tr

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddedContactsScreen(
    viewModel: ContactsViewModel,
    onContactClick: (String) -> Unit
) {
    val context = LocalContext.current
    val prefs = remember {
        context.getSharedPreferences("sada_contact_categories", Context.MODE_PRIVATE)
    }
    val contacts by viewModel.contacts.collectAsState()
    val baseContacts = contacts.filter {
        !it.name.startsWith("Discovery:", ignoreCase = true) && !it.isBlocked
    }
    var selectedCategory by remember { mutableStateOf(ContactCategory.ALL) }
    var editingContact by remember { mutableStateOf<ContactEntity?>(null) }
    var blockCandidate by remember { mutableStateOf<ContactEntity?>(null) }
    var editedName by remember { mutableStateOf("") }
    var editedCategory by remember { mutableStateOf(ContactCategory.FRIENDS) }
    var serviceProfileContact by remember { mutableStateOf<ContactEntity?>(null) }

    var categoriesVersion by remember { mutableStateOf(0) }
    val categorizedContacts = remember(baseContacts, selectedCategory, categoriesVersion) {
        baseContacts.filter { contact ->
            when (selectedCategory) {
                ContactCategory.ALL -> true
                else -> getCategoryForContact(prefs, contact) == selectedCategory
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        MeshBackground()

        Scaffold(
            topBar = {
                LargeTopAppBar(
                    title = { Text(tr("قائمة الأصدقاء", "Friends List"), fontWeight = FontWeight.ExtraBold) },
                    colors = TopAppBarDefaults.largeTopAppBarColors(
                        containerColor = Color.Transparent,
                        scrolledContainerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.85f)
                    )
                )
            },
            containerColor = Color.Transparent
        ) { padding ->
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                item {
                    CategoryFilterRow(
                        selected = selectedCategory,
                        onSelect = { selectedCategory = it }
                    )
                }
                if (categorizedContacts.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 24.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = tr("لا توجد جهات ضمن هذا التصنيف", "No friends in this category"),
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.72f)
                            )
                        }
                    }
                } else {
                    items(categorizedContacts, key = { it.id }) { contact ->
                        val category = getCategoryForContact(prefs, contact)
                        AddedContactTile(
                            contact = contact,
                            category = category,
                            onClick = {
                                if (contact.isServiceProfile) {
                                    serviceProfileContact = contact
                                } else {
                                    onContactClick(contact.id)
                                }
                            },
                            onBlockClick = { blockCandidate = contact },
                            onEditClick = {
                                editingContact = contact
                                editedName = contact.name
                                editedCategory = getCategoryForContact(prefs, contact)
                            }
                        )
                    }
                }
            }
        }

        if (editingContact != null) {
            AlertDialog(
                onDismissRequest = { editingContact = null },
                title = { Text(tr("تعديل الاسم", "Rename Contact")) },
                text = {
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        OutlinedTextField(
                            value = editedName,
                            onValueChange = { editedName = it },
                            singleLine = true,
                            label = { Text(tr("اسم جهة الاتصال", "Contact Name")) }
                        )
                        Text(
                            text = tr("التصنيف", "Category"),
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.9f),
                            fontWeight = FontWeight.SemiBold
                        )
                        CategoryFilterRow(
                            selected = editedCategory,
                            onSelect = { editedCategory = it },
                            includeAll = false
                        )
                    }
                },
                confirmButton = {
                    TextButton(
                        onClick = {
                            val contact = editingContact
                            if (contact != null && editedName.trim().isNotBlank()) {
                                viewModel.renameContact(contact.id, editedName)
                                setCategoryForContact(prefs, contact.id, editedCategory)
                                categoriesVersion++
                            }
                            editingContact = null
                        }
                    ) { Text(tr("حفظ", "Save")) }
                },
                dismissButton = {
                    TextButton(onClick = { editingContact = null }) { Text(tr("إلغاء", "Cancel")) }
                }
            )
        }

        serviceProfileContact?.let { contact ->
            AlertDialog(
                onDismissRequest = { serviceProfileContact = null },
                title = {
                    Text(
                        "${tr("بروفايل الخدمة", "Service Profile")} - ${contact.name}",
                        fontWeight = FontWeight.Bold
                    )
                },
                text = {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        ProfileLine(
                            icon = Icons.Default.Storefront,
                            label = tr("التصنيف", "Category"),
                            value = contact.serviceCategory?.replace('_', ' ')?.ifBlank { tr("خدمة عامة", "Public service") }
                                ?: tr("خدمة عامة", "Public service")
                        )
                        if (!contact.serviceAddress.isNullOrBlank()) {
                            ProfileLine(Icons.Default.LocationOn, tr("العنوان", "Address"), contact.serviceAddress)
                        }
                        if (!contact.serviceWorkingHours.isNullOrBlank()) {
                            ProfileLine(Icons.Default.Schedule, tr("أوقات العمل", "Working Hours"), contact.serviceWorkingHours)
                        }
                        if (!contact.serviceContactInfo.isNullOrBlank()) {
                            ProfileLine(Icons.Default.Phone, tr("التواصل", "Contact"), contact.serviceContactInfo)
                        }
                        val deliveryText = if (contact.serviceDeliveryAvailable) {
                            tr(
                                "متاح (حتى ${contact.serviceDeliveryRadiusKm ?: "5"} كم)",
                                "Available (up to ${contact.serviceDeliveryRadiusKm ?: "5"} km)"
                            )
                        } else {
                            tr("غير متاح", "Not available")
                        }
                        ProfileLine(Icons.Default.LocalShipping, tr("التوصيل", "Delivery"), deliveryText)
                        if (!contact.serviceQuickReply.isNullOrBlank()) {
                            Text(
                                text = "${tr("رد سريع", "Quick reply")}: ${contact.serviceQuickReply}",
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.85f)
                            )
                        }
                    }
                },
                confirmButton = {
                    TextButton(onClick = {
                        serviceProfileContact = null
                        onContactClick(contact.id)
                    }) {
                        Text(tr("فتح المحادثة", "Open Chat"))
                    }
                },
                dismissButton = {
                    TextButton(onClick = { serviceProfileContact = null }) {
                        Text(tr("إغلاق", "Close"))
                    }
                }
            )
        }

        blockCandidate?.let { contact ->
            AlertDialog(
                onDismissRequest = { blockCandidate = null },
                title = { Text(tr("حظر جهة الاتصال", "Block Contact")) },
                text = {
                    Text(
                        tr(
                            "سيتم حظر ${contact.name} ونقله من قائمة الأصدقاء. يمكنك فك الحظر من صفحة الإعدادات.",
                            "${contact.name} will be blocked and removed from friends. You can unblock from Settings."
                        )
                    )
                },
                confirmButton = {
                    TextButton(
                        onClick = {
                            viewModel.blockContact(contact.id)
                            blockCandidate = null
                        }
                    ) {
                        Text(tr("حظر", "Block"))
                    }
                },
                dismissButton = {
                    TextButton(onClick = { blockCandidate = null }) {
                        Text(tr("إلغاء", "Cancel"))
                    }
                }
            )
        }
    }
}

@Composable
private fun AddedContactTile(
    contact: ContactEntity,
    category: ContactCategory,
    onClick: () -> Unit,
    onBlockClick: () -> Unit,
    onEditClick: () -> Unit
) {
    val onSurface = MaterialTheme.colorScheme.onSurface
    val primary = MaterialTheme.colorScheme.primary
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.94f),
        border = androidx.compose.foundation.BorderStroke(1.dp, onSurface.copy(alpha = 0.14f)),
        shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp)
    ) {
        ListItem(
            headlineContent = {
                Column {
                    val statusActive = contact.statusText?.isNotBlank() == true &&
                        ((contact.statusExpiresAt?.time ?: 0L) > System.currentTimeMillis())
                    if (statusActive) {
                        Surface(
                            color = Color(0xFF10B981).copy(alpha = 0.15f),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text(
                                text = contact.statusText ?: "",
                                color = Color(0xFF10B981),
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 12.sp,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                            )
                        }
                        Spacer(modifier = Modifier.height(6.dp))
                    }
                    Text(
                        text = contact.name,
                        color = onSurface,
                        fontWeight = FontWeight.Bold
                    )
                }
            },
            supportingContent = {
                Column {
                    Text(
                        text = "ID: ${contact.id.take(10)}...",
                        color = onSurface.copy(alpha = 0.72f)
                    )
                    Text(
                        text = categoryTitle(category),
                        color = primary,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            },
            leadingContent = {
                Icon(Icons.Default.Person, contentDescription = null, tint = primary)
            },
            trailingContent = {
                androidx.compose.foundation.layout.Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = onBlockClick) {
                        Icon(Icons.Default.Block, contentDescription = "Block", tint = Color.Red.copy(alpha = 0.9f))
                    }
                    IconButton(onClick = onEditClick) {
                        Icon(Icons.Default.Edit, contentDescription = "Edit", tint = primary)
                    }
                    Icon(
                        Icons.AutoMirrored.Filled.KeyboardArrowRight,
                        contentDescription = null,
                        tint = onSurface.copy(alpha = 0.5f)
                    )
                }
            },
            colors = ListItemDefaults.colors(containerColor = Color.Transparent)
        )
    }
}

@Composable
private fun CategoryFilterRow(
    selected: ContactCategory,
    onSelect: (ContactCategory) -> Unit,
    includeAll: Boolean = true
) {
    val categories = if (includeAll) {
        ContactCategory.entries.toList()
    } else {
        ContactCategory.entries.filter { it != ContactCategory.ALL }
    }
    androidx.compose.foundation.layout.Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        categories.forEach { category ->
            FilterChip(
                selected = selected == category,
                onClick = { onSelect(category) },
                label = {
                    Text(categoryTitle(category))
                }
            )
        }
    }
}

private enum class ContactCategory {
    ALL,
    FAMILY,
    WORK,
    FRIENDS,
    SERVICES
}

private fun categoryTitle(category: ContactCategory): String {
    return when (category) {
        ContactCategory.ALL -> tr("الكل", "All")
        ContactCategory.FAMILY -> tr("العائلة", "Family")
        ContactCategory.WORK -> tr("العمل", "Work")
        ContactCategory.FRIENDS -> tr("الأصدقاء", "Friends")
        ContactCategory.SERVICES -> tr("خدمات", "Services")
    }
}

private fun getCategoryForContact(
    prefs: android.content.SharedPreferences,
    contact: ContactEntity
): ContactCategory {
    val defaultCategory = if (contact.isServiceProfile) ContactCategory.SERVICES else ContactCategory.FRIENDS
    val raw = prefs.getString(contact.id, defaultCategory.name)
    return runCatching { ContactCategory.valueOf(raw ?: ContactCategory.FRIENDS.name) }
        .getOrDefault(defaultCategory)
}

private fun setCategoryForContact(
    prefs: android.content.SharedPreferences,
    contactId: String,
    category: ContactCategory
) {
    prefs.edit().putString(contactId, category.name).apply()
}

@Composable
private fun ProfileLine(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String
) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, contentDescription = null, tint = NeonTeal)
        Text(
            text = "$label: $value",
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.9f)
        )
    }
}
