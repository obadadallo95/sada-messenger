package org.sada.messenger.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.draw.scale
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.sada.messenger.R
import org.sada.messenger.data.entities.ChatEntity
import org.sada.messenger.ui.theme.NeonTeal
import org.sada.messenger.ui.theme.CyberBlue
import org.sada.messenger.ui.viewmodels.HomeViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GroupsScreen(
    viewModel: HomeViewModel,
    onGroupClick: (String) -> Unit,
    onCreateGroupClick: () -> Unit
) {
    val allChats by viewModel.chats.collectAsState()
    val myGroups = allChats.filter { it.isGroup }
    
    // Mock nearby groups for parity UX
    val nearbyGroups = remember {
        listOf(
            ChatEntity("nearby_1", "General Square / الساحة العامة", isGroup = true),
            ChatEntity("nearby_2", "Emergency Alerts / تنبيهات الطوارئ", isGroup = true)
        )
    }

    Box(modifier = Modifier.fillMaxSize()) {
        MeshBackground()

        Scaffold(
            topBar = {
                LargeTopAppBar(
                    title = { Text(stringResource(R.string.groups_nearby_title)) },
                    colors = TopAppBarDefaults.largeTopAppBarColors(
                        containerColor = Color.Transparent,
                        scrolledContainerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.8f)
                    )
                )
            },
            floatingActionButton = {
                FloatingActionButton(
                    onClick = onCreateGroupClick,
                    containerColor = NeonTeal,
                    contentColor = Color.Black,
                    shape = CircleShape
                ) {
                    Icon(Icons.Default.Add, contentDescription = null)
                }
            },
            containerColor = Color.Transparent
        ) { padding ->
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentPadding = PaddingValues(bottom = 80.dp)
            ) {
                // Radar Animation Header (Conceptual match to Flutter)
                item {
                    RadarHeader()
                }

                // My Groups Section
                if (myGroups.isNotEmpty()) {
                    item {
                        GroupsSectionHeader(stringResource(R.string.groups_my_title))
                        LazyRow(
                            contentPadding = PaddingValues(horizontal = 16.dp),
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                            modifier = Modifier.padding(vertical = 8.dp)
                        ) {
                            items(myGroups) { group ->
                                MyGroupCard(group, onClick = { onGroupClick(group.id) })
                            }
                        }
                    }
                }

                // Nearby Communities Section
                item {
                    GroupsSectionHeader(stringResource(R.string.groups_nearby_title))
                }

                if (nearbyGroups.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(200.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                stringResource(R.string.groups_empty),
                                color = Color.White.copy(alpha = 0.4f)
                            )
                        }
                    }
                } else {
                    items(nearbyGroups) { group ->
                        NearbyGroupItem(group)
                    }
                }
            }
        }
    }
}

@Composable
fun RadarHeader() {
    val infiniteTransition = rememberInfiniteTransition(label = "radar")
    val scale by infiniteTransition.animateFloat(
        initialValue = 0.8f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = EaseInOutSine),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(180.dp),
        contentAlignment = Alignment.Center
    ) {
        // Aesthetic Gradient Back
        Box(
            modifier = Modifier
                .size(120.dp)
                .blur(30.dp)
                .background(
                    Brush.radialGradient(listOf(NeonTeal.copy(alpha = 0.2f), Color.Transparent)),
                    CircleShape
                )
        )
        
        Icon(
            Icons.Default.Radar,
            contentDescription = null,
            tint = NeonTeal.copy(alpha = 0.8f),
            modifier = Modifier
                .size(80.dp)
                .scale(scale)
        )
    }
}

@Composable
fun GroupsSectionHeader(title: String) {
    Text(
        text = title,
        fontWeight = FontWeight.Bold,
        fontSize = 20.sp,
        color = Color.White,
        modifier = Modifier.padding(16.dp)
    )
}

@Composable
fun MyGroupCard(group: ChatEntity, onClick: () -> Unit) {
    Surface(
        modifier = Modifier
            .size(width = 140.dp, height = 120.dp)
            .clip(RoundedCornerShape(16.dp))
            .clickable(onClick = onClick),
        color = Color.White.copy(alpha = 0.05f),
        border = androidx.compose.foundation.BorderStroke(1.dp, Color.White.copy(alpha = 0.1f))
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(Icons.Default.Groups, contentDescription = null, tint = CyberBlue, modifier = Modifier.size(32.dp))
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                group.name,
                fontWeight = FontWeight.Bold,
                fontSize = 12.sp,
                color = Color.White,
                maxLines = 2,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }
    }
}

@Composable
fun NearbyGroupItem(group: ChatEntity) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp),
        shape = RoundedCornerShape(16.dp),
        color = Color.White.copy(alpha = 0.05f),
        border = androidx.compose.foundation.BorderStroke(1.dp, Color.White.copy(alpha = 0.1f))
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(50.dp)
                    .background(CyberBlue.copy(alpha = 0.1f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Default.Groups, contentDescription = null, tint = CyberBlue)
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(group.name, fontWeight = FontWeight.Bold, color = Color.White)
                Text(
                    stringResource(R.string.groups_peers_nearby, 5), // Mock count
                    fontSize = 11.sp,
                    color = Color.White.copy(alpha = 0.5f)
                )
            }
            
            Button(
                onClick = { /* Join Logic */ },
                colors = ButtonDefaults.buttonColors(containerColor = NeonTeal.copy(alpha = 0.1f)),
                border = androidx.compose.foundation.BorderStroke(1.dp, NeonTeal.copy(alpha = 0.3f)),
                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                modifier = Modifier.height(32.dp)
            ) {
                Text(stringResource(R.string.groups_join), color = NeonTeal, fontSize = 12.sp)
            }
        }
    }
}
