package org.sada.messenger.ui.screens

import org.sada.messenger.ui.utils.tr
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.sada.messenger.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MyQrScreen(
    nickname: String,
    publicKey: String,
    onBack: () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        MeshBackground()

        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text(tr("معرّفي", "My Identity"), fontWeight = FontWeight.Bold) },
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
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                // Identity Card
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(32.dp),
                    color = Color.White.copy(alpha = 0.05f),
                    border = androidx.compose.foundation.BorderStroke(
                        1.dp,
                        Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.1f), Color.Transparent))
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // QR Placeholder
                        Surface(
                            modifier = Modifier
                                .size(240.dp)
                                .padding(16.dp),
                            shape = RoundedCornerShape(24.dp),
                            color = Color.White,
                            border = androidx.compose.foundation.BorderStroke(1.dp, NeonTeal)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(Icons.Default.QrCode, contentDescription = null, modifier = Modifier.size(160.dp), tint = Color.Black)
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(32.dp))
                        
                        Text(
                            text = nickname,
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.ExtraBold,
                            color = Color.White
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Text(
                            text = tr("هويتك مشفرة بمفتاح فريد", "Your identity is secured with E2EE"),
                            style = MaterialTheme.typography.bodySmall,
                            color = NeonTeal
                        )
                        
                        Spacer(modifier = Modifier.height(24.dp))
                        
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = Color.Black.copy(alpha = 0.3f),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = publicKey.take(32) + "...",
                                modifier = Modifier.padding(12.dp),
                                style = MaterialTheme.typography.labelSmall,
                                color = Color.White.copy(alpha = 0.5f),
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(48.dp))
                
                Text(
                    text = tr("اجعل أصدقاءك يمسحون هذا الكود لإضافتك عبر الشبكة مباشرة.", "Let your friends scan this code to add you over the mesh."),
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color.White.copy(alpha = 0.6f),
                    textAlign = TextAlign.Center,
                    lineHeight = 24.sp
                )
            }
        }
    }
}
