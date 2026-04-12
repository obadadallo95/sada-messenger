package org.sada.messenger.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import org.sada.messenger.data.entities.ContactEntity
import org.sada.messenger.ui.components.*
import org.sada.messenger.ui.theme.*
import org.sada.messenger.ui.utils.tr
import org.sada.messenger.ui.viewmodels.ContactsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateGroupScreen(
    viewModel: ContactsViewModel,
    onCreateGroup: (String, String, Boolean, String, List<String>) -> Unit,
    onBack: () -> Unit
) {
    val contacts by viewModel.contacts.collectAsState()
    var groupName by remember { mutableStateOf("") }
    var groupDescription by remember { mutableStateOf("") }
    var isPublic by remember { mutableStateOf(true) }
    var joinPolicy by remember { mutableStateOf("open") }
    val selectedMembers = remember { mutableStateListOf<String>() }

    MeshBackground {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { 
                        Text(
                            tr("إنشاء مجموعة", "Create Group"),
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
                    actions = {
                        if (groupName.isNotBlank()) {
                            IconButton(
                                onClick = {
                                    onCreateGroup(
                                        groupName.trim(),
                                        groupDescription.trim(),
                                        isPublic,
                                        joinPolicy,
                                        selectedMembers.toList()
                                    )
                                }
                            ) {
                                Icon(
                                    Icons.Default.Check, 
                                    contentDescription = "Create",
                                    tint = LocalSadaPalette.current.successGreen
                                )
                            }
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = LocalSadaPalette.current.background.copy(alpha = 0.8f)
                    )
                )
            },
            containerColor = LocalSadaPalette.current.background
        ) { padding ->
            Column(
                modifier = Modifier
                    .padding(padding)
                    .padding(16.dp)
                    .fillMaxSize()
            ) {
                // Group Info Card
                GlassCard(modifier = Modifier.fillMaxWidth()) {
                    Column {
                        Text(
                            text = tr("معلومات المجموعة", "Group Information"),
                            style = MaterialTheme.typography.labelMedium,
                            color = LocalSadaPalette.current.textSecondary
                        )
                        
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        // Group Name Input
                        GlassInputField(
                            value = groupName,
                            onValueChange = { groupName = it },
                            placeholder = tr("اسم المجموعة", "Group name"),
                            leadingIcon = {
                                Icon(
                                    imageVector = Icons.Default.Person,
                                    contentDescription = null,
                                    tint = LocalSadaPalette.current.textSecondary
                                )
                            }
                        )
                        
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        // Group Description Input
                        GlassInputField(
                            value = groupDescription,
                            onValueChange = { groupDescription = it },
                            placeholder = tr("وصف المجموعة (اختياري)", "Group description (optional)"),
                            modifier = Modifier.height(80.dp)
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Privacy Settings Card
                GlassCard(modifier = Modifier.fillMaxWidth()) {
                    Column {
                        Text(
                            text = tr("إعدادات الخصوصية", "Privacy Settings"),
                            style = MaterialTheme.typography.labelMedium,
                            color = LocalSadaPalette.current.textSecondary
                        )
                        
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        // Public/Private Toggle
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = tr("مجموعة عامة", "Public Group"),
                                modifier = Modifier.weight(1f),
                                color = LocalSadaPalette.current.textPrimary
                            )
                            Switch(
                                checked = isPublic,
                                onCheckedChange = {
                                    isPublic = it
                                    if (!isPublic && joinPolicy == "open") joinPolicy = "approval"
                                },
                                colors = SwitchDefaults.colors(
                                    checkedThumbColor = LocalSadaPalette.current.successGreen,
                                    checkedTrackColor = LocalSadaPalette.current.successGreen.copy(alpha = 0.5f)
                                )
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Join Policy
                        Text(
                            text = tr("طريقة الانضمام", "Join Policy"),
                            style = MaterialTheme.typography.bodyMedium,
                            color = LocalSadaPalette.current.textPrimary
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        // Policy Options
                        val options = if (isPublic) {
                            listOf(
                                "open" to tr("مفتوحة", "Open"),
                                "approval" to tr("تتطلب موافقة", "Approval"),
                                "invite_only" to tr("بدعوة فقط", "Invite only")
                            )
                        } else {
                            listOf(
                                "approval" to tr("خاصة بموافقة", "Private (approval)"),
                                "invite_only" to tr("خاصة بدعوة", "Private (invite)")
                            )
                        }
                        
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            options.forEach { (value, label) ->
                                val isSelected = joinPolicy == value
                                GlassChip(
                                    text = label,
                                    selected = isSelected,
                                    onClick = { joinPolicy = value }
                                )
                            }
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Members Section
                if (contacts.isNotEmpty()) {
                    Text(
                        text = tr("دعوة أعضاء (اختياري)", "Invite Members (Optional)"),
                        style = MaterialTheme.typography.labelMedium,
                        color = LocalSadaPalette.current.textSecondary,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.weight(1f)
                    ) {
                        items(contacts) { contact ->
                            MemberItemGlass(
                                contact = contact,
                                isSelected = selectedMembers.contains(contact.id),
                                onToggle = {
                                    if (selectedMembers.contains(contact.id)) {
                                        selectedMembers.remove(contact.id)
                                    } else {
                                        selectedMembers.add(contact.id)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Create Button
                Spacer(modifier = Modifier.height(16.dp))
                GlassButton(
                    onClick = {
                        if (groupName.isNotBlank()) {
                            onCreateGroup(
                                groupName.trim(),
                                groupDescription.trim(),
                                isPublic,
                                joinPolicy,
                                selectedMembers.toList()
                            )
                        }
                    },
                    enabled = groupName.isNotBlank(),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = null,
                        modifier = Modifier.padding(end = 8.dp)
                    )
                    Text(tr("إنشاء المجموعة", "Create Group"))
                }
            }
        }
    }
}

@Composable
fun MemberItemGlass(
    contact: ContactEntity,
    isSelected: Boolean,
    onToggle: () -> Unit
) {
    GlassSurface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onToggle),
        cornerRadius = 12.dp
    ) {
        Row(
            modifier = Modifier
                .padding(horizontal = 16.dp, vertical = 12.dp)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Avatar placeholder
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(NeonTeal.copy(alpha = 0.2f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = null,
                    tint = NeonTeal,
                    modifier = Modifier.size(24.dp)
                )
            }
            
            Text(
                text = contact.name,
                modifier = Modifier.weight(1f),
                color = LocalSadaPalette.current.textPrimary,
                style = MaterialTheme.typography.bodyMedium
            )
            
            Checkbox(
                checked = isSelected,
                onCheckedChange = { onToggle() },
                colors = CheckboxDefaults.colors(
                    checkedColor = NeonTeal,
                    uncheckedColor = LocalSadaPalette.current.textSecondary
                )
            )
        }
    }
}
