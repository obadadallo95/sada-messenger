package org.sada.messenger.ui.screens

import org.sada.messenger.ui.utils.tr
import androidx.compose.animation.core.EaseInOutSine
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.LocalShipping
import androidx.compose.material.icons.filled.MedicalServices
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.Storefront
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import org.sada.messenger.data.entities.ChatEntity
import org.sada.messenger.R
import org.sada.messenger.ui.theme.CyberBlue
import org.sada.messenger.ui.theme.*
import org.sada.messenger.ui.components.*
import org.sada.messenger.ui.viewmodels.HomeViewModel
import org.sada.messenger.ui.viewmodels.JoinGroupResult
import org.sada.messenger.ui.viewmodels.ServiceDirectoryItem

private enum class GroupFilter {
    ALL,
    PUBLIC,
    PRIVATE
}


@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GroupsScreen(
    viewModel: HomeViewModel,
    onGroupClick: (String) -> Unit,
    onCreateGroupClick: () -> Unit
) {
    val myGroups by viewModel.myGroups.collectAsState()
    val nearbyGroups by viewModel.nearbyGroups.collectAsState()
    val pendingRequests by viewModel.pendingJoinRequests.collectAsState()
    val memberCounts by viewModel.groupMemberCounts.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    var query by remember { mutableStateOf("") }
    var filter by remember { mutableStateOf(GroupFilter.ALL) }

    fun ChatEntity.matchesFilter(current: GroupFilter): Boolean {
        return when (current) {
            GroupFilter.ALL -> true
            GroupFilter.PUBLIC -> isPublic
            GroupFilter.PRIVATE -> !isPublic
        }
    }

    val filteredMy = myGroups.filter {
        it.name.contains(query, ignoreCase = true) &&
            it.matchesFilter(filter)
    }
    val filteredNearby = nearbyGroups.filter {
        it.name.contains(query, ignoreCase = true) &&
            it.matchesFilter(filter)
    }
    Box(modifier = Modifier.fillMaxSize()) {
        MeshBackground()

        Scaffold(
            snackbarHost = { SnackbarHost(hostState = snackbarHostState) },
            topBar = {
                LargeTopAppBar(
                    title = { Text(tr("المجموعات والمجتمعات", "Groups & Communities")) },
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
                contentPadding = PaddingValues(bottom = 84.dp)
            ) {
                item { RadarHeader() }

                item {
                    OutlinedTextField(
                        value = query,
                        onValueChange = { query = it },
                        label = { Text(tr("ابحث عن مجموعة", "Search groups")) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp),
                        shape = RoundedCornerShape(14.dp)
                    )
                }

                run {
                    item {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 8.dp),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            GroupFilter.entries.forEach { current ->
                                AssistChip(
                                    onClick = { filter = current },
                                    label = {
                                        Text(
                                            when (current) {
                                                GroupFilter.ALL -> tr("الكل", "All")
                                                GroupFilter.PUBLIC -> tr("عامة", "Public")
                                                GroupFilter.PRIVATE -> tr("خاصة", "Private")
                                            }
                                        )
                                    },
                                    leadingIcon = {
                                        if (filter == current) {
                                            Icon(Icons.Default.Groups, contentDescription = null, modifier = Modifier.size(16.dp))
                                        }
                                    }
                                )
                            }
                        }
                    }

                    if (pendingRequests.isNotEmpty()) {
                        item {
                            GroupsSectionHeader(tr("طلبات الانضمام بانتظار موافقتك", "Pending join requests"))
                        }
                        items(pendingRequests) { request ->
                            val onSurface = MaterialTheme.colorScheme.onSurface
                            Surface(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 16.dp, vertical = 6.dp),
                                shape = RoundedCornerShape(14.dp),
                                color = Color(0xFFFFC107).copy(alpha = 0.12f),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFFFC107).copy(alpha = 0.35f))
                            ) {
                                Column(modifier = Modifier.padding(12.dp)) {
                                    Text(request.chatName, color = onSurface, fontWeight = FontWeight.Bold)
                                    Text(
                                        "${tr("طلب من", "Request from")}: ${request.requesterName}",
                                        color = onSurface.copy(alpha = 0.72f),
                                        fontSize = 12.sp
                                    )
                                    Spacer(modifier = Modifier.height(8.dp))
                                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                        TextButton(
                                            onClick = {
                                                viewModel.handleJoinRequest(request.id, request.groupId, request.requesterId, approve = true)
                                            }
                                        ) { Text(tr("موافقة", "Approve")) }
                                        TextButton(
                                            onClick = {
                                                viewModel.handleJoinRequest(request.id, request.groupId, request.requesterId, approve = false)
                                            }
                                        ) { Text(tr("رفض", "Reject")) }
                                    }
                                }
                            }
                        }
                    }

                    item { GroupsSectionHeader(tr("مجموعاتي", "My Groups")) }
                    if (filteredMy.isEmpty()) {
                        item {
                            EmptyGroupsHint(text = tr("لا توجد مجموعات منضم لها", "You have not joined any groups"))
                        }
                    } else {
                        item {
                            LazyRow(
                                contentPadding = PaddingValues(horizontal = 16.dp),
                                horizontalArrangement = Arrangement.spacedBy(12.dp),
                                modifier = Modifier.padding(vertical = 8.dp)
                            ) {
                                items(filteredMy) { group ->
                                    MyGroupCard(
                                        group = group,
                                        membersCount = memberCounts[group.id] ?: 1,
                                        onClick = { onGroupClick(group.id) }
                                    )
                                }
                            }
                        }
                    }

                    item { GroupsSectionHeader(tr("المجموعات القريبة", "Nearby Groups")) }
                    if (filteredNearby.isEmpty()) {
                        item {
                            EmptyGroupsHint(text = tr("لا توجد مجموعات مطابقة للبحث أو الفلتر", "No groups match your search or filter"))
                        }
                    } else {
                        items(filteredNearby) { group ->
                            NearbyGroupItem(
                                group = group,
                                membersCount = memberCounts[group.id] ?: 0,
                                onJoin = {
                                    scope.launch {
                                        when (viewModel.joinGroup(group.id)) {
                                            JoinGroupResult.JOINED -> {
                                                snackbarHostState.showSnackbar("${tr("تم الانضمام إلى", "Joined")} ${group.name}")
                                                onGroupClick(group.id)
                                            }
                                            JoinGroupResult.REQUEST_SENT -> {
                                                snackbarHostState.showSnackbar(tr("تم إرسال طلب الانضمام", "Join request sent"))
                                            }
                                            JoinGroupResult.INVITE_REQUIRED -> {
                                                snackbarHostState.showSnackbar(tr("هذه المجموعة بدعوة فقط", "This group is invite-only"))
                                            }
                                            JoinGroupResult.ALREADY_MEMBER -> {
                                                onGroupClick(group.id)
                                            }
                                            JoinGroupResult.GROUP_NOT_FOUND -> {
                                                snackbarHostState.showSnackbar(tr("المجموعة غير موجودة", "Group not found"))
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}


@Composable
private fun EmptyGroupsHint(text: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(120.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(text = text, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.68f))
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
            .height(150.dp),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .size(120.dp)
                .blur(30.dp)
                .background(
                    Brush.radialGradient(listOf(NeonTeal.copy(alpha = 0.2f), Color.Transparent)),
                    CircleShape
                )
        )

        Image(
            painter = painterResource(id = R.drawable.logo),
            contentDescription = "Sada Logo",
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
        fontSize = 18.sp,
        color = MaterialTheme.colorScheme.onSurface,
        modifier = Modifier.padding(16.dp)
    )
}

@Composable
fun MyGroupCard(group: ChatEntity, membersCount: Int, onClick: () -> Unit) {
    val onSurface = MaterialTheme.colorScheme.onSurface
    val primary = MaterialTheme.colorScheme.primary
    Surface(
        modifier = Modifier
            .size(width = 180.dp, height = 120.dp)
            .clip(RoundedCornerShape(16.dp))
            .clickable(onClick = onClick),
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.94f),
        border = androidx.compose.foundation.BorderStroke(1.dp, onSurface.copy(alpha = 0.14f))
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.Center
        ) {
            Text(group.name, fontWeight = FontWeight.Bold, fontSize = 14.sp, color = onSurface)
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                group.groupDescription ?: tr("بدون وصف", "No description"),
                color = onSurface.copy(alpha = 0.72f),
                fontSize = 12.sp,
                maxLines = 2
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                if (group.isPublic) "${tr("عامة", "Public")} • ${group.joinPolicy}" else "${tr("خاصة", "Private")} • ${group.joinPolicy}",
                color = primary,
                fontSize = 11.sp
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                "${tr("الأعضاء", "Members")}: $membersCount",
                color = onSurface.copy(alpha = 0.78f),
                fontSize = 11.sp
            )
        }
    }
}

@Composable
fun NearbyGroupItem(
    group: ChatEntity,
    membersCount: Int,
    onJoin: () -> Unit
) {
    val onSurface = MaterialTheme.colorScheme.onSurface
    val primary = MaterialTheme.colorScheme.primary
    val secondary = MaterialTheme.colorScheme.secondary
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp),
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.94f),
        border = androidx.compose.foundation.BorderStroke(1.dp, onSurface.copy(alpha = 0.14f))
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(50.dp)
                    .background(secondary.copy(alpha = 0.12f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Default.Groups, contentDescription = null, tint = secondary)
            }

            Spacer(modifier = Modifier.width(16.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(group.name, fontWeight = FontWeight.Bold, color = onSurface)
                Text(
                    "${if (group.isPublic) tr("عامة", "Public") else tr("خاصة", "Private")} • ${group.joinPolicy}",
                    fontSize = 11.sp,
                    color = onSurface.copy(alpha = 0.72f)
                )
                Text(
                    "${tr("الأعضاء", "Members")}: $membersCount",
                    fontSize = 11.sp,
                    color = onSurface.copy(alpha = 0.72f)
                )
            }

            Button(
                onClick = onJoin,
                colors = ButtonDefaults.buttonColors(
                    containerColor = primary.copy(alpha = 0.14f),
                    contentColor = primary
                ),
                border = androidx.compose.foundation.BorderStroke(1.dp, primary.copy(alpha = 0.38f)),
                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                modifier = Modifier.height(32.dp)
            ) {
                Text(tr("انضمام", "Join"), color = primary, fontSize = 12.sp)
            }
        }
    }
}

@Composable
private fun ServiceDirectoryCard(
    service: ServiceDirectoryItem,
    onContact: () -> Unit
) {
    val onSurface = MaterialTheme.colorScheme.onSurface
    val primary = MaterialTheme.colorScheme.primary
    val isNew = (System.currentTimeMillis() - service.updatedAtMs) <= 24L * 60L * 60L * 1000L
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp),
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.94f),
        border = androidx.compose.foundation.BorderStroke(1.dp, onSurface.copy(alpha = 0.14f))
    ) {
        Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(service.name, fontWeight = FontWeight.Bold, color = onSurface, modifier = Modifier.weight(1f))
                if (isNew) {
                    Surface(
                        shape = RoundedCornerShape(999.dp),
                        color = Color(0xFF10B981).copy(alpha = 0.18f)
                    ) {
                        Text(
                            text = tr("جديد", "NEW"),
                            color = Color(0xFF10B981),
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                        )
                    }
                }
            }
            service.category?.let {
                Text(
                    "${tr("التصنيف", "Category")}: $it",
                    color = onSurface.copy(alpha = 0.72f),
                    fontSize = 12.sp
                )
            }
            if (!service.address.isNullOrBlank()) {
                Text(
                    "${tr("العنوان", "Address")}: ${service.address}",
                    color = onSurface.copy(alpha = 0.72f),
                    fontSize = 12.sp
                )
            }
            if (!service.workingHours.isNullOrBlank()) {
                Text(
                    "${tr("وقت العمل", "Working hours")}: ${service.workingHours}",
                    color = onSurface.copy(alpha = 0.72f),
                    fontSize = 12.sp
                )
            }
            val deliveryLabel = if (service.deliveryAvailable) {
                tr("توصيل متاح", "Delivery available")
            } else {
                tr("بدون توصيل", "No delivery")
            }
            Text(
                deliveryLabel + if (service.deliveryAvailable) " (${service.deliveryRadiusKm ?: "5"} km)" else "",
                color = primary,
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold
            )
            Button(
                onClick = onContact,
                colors = ButtonDefaults.buttonColors(
                    containerColor = primary.copy(alpha = 0.14f),
                    contentColor = primary
                ),
                border = androidx.compose.foundation.BorderStroke(1.dp, primary.copy(alpha = 0.38f)),
                shape = RoundedCornerShape(10.dp)
            ) {
                Text(tr("تواصل الآن", "Contact Now"), color = primary, fontWeight = FontWeight.Bold)
            }
        }
    }
}
