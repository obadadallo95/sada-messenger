package org.sada.messenger.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import org.sada.messenger.R
import org.sada.messenger.security.KeyManager
import org.sada.messenger.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RegisterScreen(
    keyManager: KeyManager,
    onComplete: (String) -> Unit
) {
    var nickname by remember { mutableStateOf("") }
    var isGenerating by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    Box(modifier = Modifier.fillMaxSize()) {
        MeshBackground()

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Logo/Icon Placeholder
            Surface(
                modifier = Modifier.size(100.dp),
                shape = RoundedCornerShape(24.dp),
                color = NeonTeal.copy(alpha = 0.1f),
                border = androidx.compose.foundation.BorderStroke(1.dp, NeonTeal.copy(alpha = 0.4f))
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        Icons.Default.Fingerprint, 
                        contentDescription = null, 
                        tint = NeonTeal,
                        modifier = Modifier.size(64.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(40.dp))

            Text(
                text = stringResource(R.string.register_title),
                style = MaterialTheme.typography.headlineMedium.copy(
                    fontWeight = FontWeight.ExtraBold,
                    letterSpacing = (-0.5).sp
                ),
                color = Color.White,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = "هويتك مشفرة محلياً ولا غبار عليها\nYour identity is locally encrypted and private",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White.copy(alpha = 0.5f),
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(48.dp))

            OutlinedTextField(
                value = nickname,
                onValueChange = { nickname = it },
                label = { Text(stringResource(R.string.register_nickname_hint)) },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                shape = RoundedCornerShape(16.dp),
                enabled = !isGenerating,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = NeonTeal,
                    unfocusedBorderColor = Color.White.copy(alpha = 0.2f),
                    focusedLabelColor = NeonTeal,
                    unfocusedLabelColor = Color.White.copy(alpha = 0.5f),
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White
                )
            )

            Spacer(modifier = Modifier.height(32.dp))

            Button(
                onClick = {
                    if (nickname.isNotBlank()) {
                        isGenerating = true
                        scope.launch {
                            keyManager.generateAndSaveKeyPair()
                            onComplete(nickname)
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(60.dp),
                shape = RoundedCornerShape(16.dp),
                enabled = nickname.isNotBlank() && !isGenerating,
                colors = ButtonDefaults.buttonColors(
                    containerColor = NeonTeal,
                    contentColor = Color.Black
                )
            ) {
                if (isGenerating) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = Color.Black,
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(stringResource(R.string.register_generating_keys), fontWeight = FontWeight.Bold)
                } else {
                    Text(stringResource(R.string.register_button), fontWeight = FontWeight.Bold, fontSize = 18.sp)
                }
            }
        }
    }
}
