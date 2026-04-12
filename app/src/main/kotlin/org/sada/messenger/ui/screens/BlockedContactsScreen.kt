package org.sada.messenger.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Block
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.sada.messenger.ui.theme.LocalSadaPalette
import org.sada.messenger.ui.theme.SadaPrimary
import org.sada.messenger.ui.utils.tr
import org.sada.messenger.ui.viewmodels.ContactsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BlockedContactsScreen(
    viewModel: ContactsViewModel,
    onBack: () -> Unit
) {
    val blockedContacts by viewModel.blockedContacts.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(tr("المحظورون", "Blocked Contacts")) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = null, tint = LocalSadaPalette.current.errorRed)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = LocalSadaPalette.current.surfaceVariant)
            )
        },
        containerColor = LocalSadaPalette.current.background
    ) { padding ->
        if (blockedContacts.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Default.Block, contentDescription = null, tint = LocalSadaPalette.current.textSecondary)
                    Text(
                        text = tr("لا توجد جهات محظورة", "No blocked contacts"),
                        color = LocalSadaPalette.current.textPrimary,
                        modifier = Modifier.padding(top = 8.dp)
                    )
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(blockedContacts, key = { it.id }) { contact ->
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        color = LocalSadaPalette.current.surfaceVariant,
                        shape = androidx.compose.foundation.shape.RoundedCornerShape(14.dp)
                    ) {
                        androidx.compose.foundation.layout.Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(text = contact.name, color = LocalSadaPalette.current.textPrimary)
                                Text(
                                    text = "ID: ${contact.id.take(12)}...",
                                    color = LocalSadaPalette.current.textSecondary,
                                    fontSize = 12.sp
                                )
                            }
                            Button(
                                onClick = { viewModel.unblockContact(contact.id) },
                                colors = ButtonDefaults.buttonColors(containerColor = SadaPrimary)
                            ) {
                                Text(tr("إلغاء الحظر", "Unblock"), color = Color.White)
                            }
                        }
                    }
                }
            }
        }
    }
}
