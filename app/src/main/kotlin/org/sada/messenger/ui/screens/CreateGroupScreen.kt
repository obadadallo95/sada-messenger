package org.sada.messenger.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import org.sada.messenger.data.entities.ContactEntity
import org.sada.messenger.ui.viewmodels.ContactsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateGroupScreen(
    viewModel: ContactsViewModel,
    onCreateGroup: (String, List<String>) -> Unit,
    onBack: () -> Unit
) {
    val contacts by viewModel.contacts.collectAsState()
    var groupName by remember { mutableStateOf("") }
    val selectedMembers = remember { mutableStateListOf<String>() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Create Group") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (groupName.isNotBlank() && selectedMembers.isNotEmpty()) {
                        IconButton(onClick = { onCreateGroup(groupName, selectedMembers.toList()) }) {
                            Icon(Icons.Default.Check, contentDescription = "Create")
                        }
                    }
                }
            )
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { padding ->
        Column(modifier = Modifier.padding(padding).padding(16.dp)) {
            OutlinedTextField(
                value = groupName,
                onValueChange = { groupName = it },
                label = { Text("Group Name") },
                modifier = Modifier.fillMaxWidth()
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            Text("Select Members", style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(8.dp))
            
            LazyColumn {
                items(contacts) { contact ->
                    MemberItem(
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
    }
}

@Composable
fun MemberItem(contact: ContactEntity, isSelected: Boolean, onToggle: () -> Unit) {
    ListItem(
        modifier = Modifier.clickable(onClick = onToggle),
        headlineContent = { Text(contact.name) },
        trailingContent = {
            Checkbox(checked = isSelected, onCheckedChange = { onToggle() })
        }
    )
}
