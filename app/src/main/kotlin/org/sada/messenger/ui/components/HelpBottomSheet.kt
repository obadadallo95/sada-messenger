package org.sada.messenger.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.HelpOutline
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.sada.messenger.R
import org.sada.messenger.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuickHelpBottomSheet(onDismiss: () -> Unit) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = LocalSadaPalette.current.background,
        dragHandle = { BottomSheetDefaults.DragHandle(color = LocalSadaPalette.current.surface) }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 40.dp, start = 24.dp, end = 24.dp, top = 8.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.HelpOutline, contentDescription = null, tint = SadaPrimary)
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = stringResource(R.string.help_title),
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.ExtraBold,
                    color = LocalSadaPalette.current.textPrimary
                )
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            HelpItem(
                question = stringResource(R.string.help_q1),
                answer = stringResource(R.string.help_a1)
            )
            
            Spacer(modifier = Modifier.height(20.dp))
            
            HelpItem(
                question = stringResource(R.string.help_q2),
                answer = stringResource(R.string.help_a2),
                isCritical = true
            )
            
            Spacer(modifier = Modifier.height(20.dp))
            
            HelpItem(
                question = stringResource(R.string.help_q3),
                answer = stringResource(R.string.help_a3)
            )
            
            Spacer(modifier = Modifier.height(32.dp))
            
            Button(
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    contentColor = Color.Black
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
                Text(stringResource(R.string.help_close), fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
fun HelpItem(question: String, answer: String, isCritical: Boolean = false) {
    Column {
        Text(
            text = question,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = if (isCritical) ErrorRed else NeonTeal
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = answer,
            style = MaterialTheme.typography.bodyMedium,
            color = LocalSadaPalette.current.textSecondary,
            lineHeight = 22.sp
        )
    }
}
