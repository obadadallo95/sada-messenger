package org.sada.messenger.ui.navigation

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.sada.messenger.R
import org.sada.messenger.ui.theme.NeonTeal

sealed class NavItem(
    val route: String,
    val labelRes: Int,
    val icon: ImageVector,
    val selectedIcon: ImageVector
) {
    object Home : NavItem("home", R.string.navigation_home, Icons.Outlined.Home, Icons.Default.Home)
    object Chats : NavItem("chats", R.string.navigation_chat, Icons.Outlined.ChatBubbleOutline, Icons.Default.ChatBubble)
    object Groups : NavItem("groups", R.string.navigation_groups, Icons.Outlined.Groups, Icons.Default.Groups)
    object Contacts : NavItem("contacts", R.string.navigation_add, Icons.Outlined.PersonAdd, Icons.Default.PersonAdd)
    object Settings : NavItem("settings", R.string.navigation_settings, Icons.Outlined.Settings, Icons.Default.Settings)
}

@Composable
fun SadaBottomBar(
    currentRoute: String?,
    onNavigate: (String) -> Unit
) {
    val items = listOf(
        NavItem.Home,
        NavItem.Chats,
        NavItem.Groups,
        NavItem.Contacts,
        NavItem.Settings
    )

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp)
            .height(72.dp),
        shape = RoundedCornerShape(24.dp),
        color = Color.Black.copy(alpha = 0.6f),
        border = androidx.compose.foundation.BorderStroke(
            1.dp,
            Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.1f), Color.Transparent))
        )
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            // Glass Blur Effect background (Conceptual as Compose doesn't have native backdrop blur yet easily)
            // But we simulate with color + alpha + border
            
            Row(
                modifier = Modifier.fillMaxSize(),
                horizontalArrangement = Arrangement.SpaceAround,
                verticalAlignment = Alignment.CenterVertically
            ) {
                items.forEach { item ->
                    val isSelected = currentRoute == item.route
                    
                    BottomNavItem(
                        item = item,
                        isSelected = isSelected,
                        onClick = { onNavigate(item.route) }
                    )
                }
            }
        }
    }
}

@Composable
fun BottomNavItem(
    item: NavItem,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val infiniteTransition = rememberInfiniteTransition(label = "glow")
    val glowAlpha by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 0.6f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "alpha"
    )

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .padding(8.dp)
            .width(64.dp)
    ) {
        Box(contentAlignment = Alignment.Center) {
            if (isSelected) {
                // Glow behind active icon
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .blur(8.dp)
                        .background(NeonTeal.copy(alpha = glowAlpha), CircleShape)
                )
            }
            
            Icon(
                imageVector = if (isSelected) item.selectedIcon else item.icon,
                contentDescription = stringResource(item.labelRes),
                tint = if (isSelected) NeonTeal else Color.White.copy(alpha = 0.4f),
                modifier = Modifier.size(26.dp)
            )
        }
        
        Spacer(modifier = Modifier.height(4.dp))
        
        Text(
            text = stringResource(item.labelRes),
            style = MaterialTheme.typography.labelSmall,
            color = if (isSelected) NeonTeal else Color.White.copy(alpha = 0.4f),
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            fontSize = 9.sp,
            maxLines = 1
        )
    }
}
