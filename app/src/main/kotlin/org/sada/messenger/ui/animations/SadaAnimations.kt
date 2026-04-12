package org.sada.messenger.ui.animations

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay

/**
 * Sada Animations & Transitions
 * Smooth animations optimized for stress-free UX
 */

// Animation durations
object AnimationDurations {
    const val INSTANT = 100
    const val FAST = 200
    const val NORMAL = 300
    const val SLOW = 500
    const val RELAXING = 800
}

// Easing curves
object SadaEasing {
    val Standard = FastOutSlowInEasing
    val Enter = FastOutLinearInEasing
    val Exit = LinearOutSlowInEasing
    val Bounce = CubicBezierEasing(0.34f, 1.56f, 0.64f, 1f)
}

/**
 * Message appear animation - slide up with fade
 */
@Composable
fun MessageAppearAnimation(
    visible: Boolean,
    modifier: Modifier = Modifier,
    content: @Composable AnimatedVisibilityScope.() -> Unit
) {
    AnimatedVisibility(
        visible = visible,
        modifier = modifier,
        enter = slideInVertically(
            initialOffsetY = { it / 2 },
            animationSpec = tween(
                durationMillis = AnimationDurations.NORMAL,
                easing = SadaEasing.Standard
            )
        ) + fadeIn(
            animationSpec = tween(
                durationMillis = AnimationDurations.FAST,
                easing = SadaEasing.Standard
            )
        ),
        exit = slideOutVertically(
            targetOffsetY = { -it / 2 },
            animationSpec = tween(
                durationMillis = AnimationDurations.FAST,
                easing = SadaEasing.Exit
            )
        ) + fadeOut(
            animationSpec = tween(
                durationMillis = AnimationDurations.INSTANT
            )
        ),
        content = content
    )
}

/**
 * Screen enter animation - slide from right
 */
@Composable
fun ScreenEnterAnimation(
    visible: Boolean,
    modifier: Modifier = Modifier,
    content: @Composable AnimatedVisibilityScope.() -> Unit
) {
    AnimatedVisibility(
        visible = visible,
        modifier = modifier,
        enter = slideInHorizontally(
            initialOffsetX = { it },
            animationSpec = tween(
                durationMillis = AnimationDurations.NORMAL,
                easing = SadaEasing.Standard
            )
        ) + fadeIn(
            animationSpec = tween(
                durationMillis = AnimationDurations.FAST
            )
        ),
        exit = slideOutHorizontally(
            targetOffsetX = { -it / 2 },
            animationSpec = tween(
                durationMillis = AnimationDurations.FAST,
                easing = SadaEasing.Exit
            )
        ) + fadeOut(),
        content = content
    )
}

/**
 * Pulse animation for important elements
 */
@Composable
fun PulseAnimation(
    modifier: Modifier = Modifier,
    content: @Composable (scale: Float, alpha: Float) -> Unit
) {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.05f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = SadaEasing.Standard),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )
    
    val alpha by infiniteTransition.animateFloat(
        initialValue = 0.8f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = SadaEasing.Standard),
            repeatMode = RepeatMode.Reverse
        ),
        label = "alpha"
    )
    
    Box(
        modifier = modifier
            .scale(scale)
            .alpha(alpha)
    ) {
        content(scale, alpha)
    }
}

/**
 * Shimmer loading animation
 */
@Composable
fun ShimmerAnimation(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    val shimmerColors = listOf(
        androidx.compose.ui.graphics.Color.LightGray.copy(alpha = 0.2f),
        androidx.compose.ui.graphics.Color.LightGray.copy(alpha = 0.5f),
        androidx.compose.ui.graphics.Color.LightGray.copy(alpha = 0.2f)
    )
    
    val transition = rememberInfiniteTransition(label = "shimmer")
    val translateAnim by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = 1200,
                easing = LinearEasing
            ),
            repeatMode = RepeatMode.Restart
        ),
        label = "shimmer"
    )
    
    val brush = androidx.compose.ui.graphics.Brush.linearGradient(
        colors = shimmerColors,
        start = androidx.compose.ui.geometry.Offset.Zero,
        end = androidx.compose.ui.geometry.Offset(x = translateAnim, y = translateAnim)
    )
    
    Box(
        modifier = modifier.background(brush)
    ) {
        content()
    }
}

/**
 * Typing indicator animation - three dots
 */
@Composable
fun TypingAnimation(
    modifier: Modifier = Modifier
) {
    val dots = listOf(
        remember { Animatable(0f) },
        remember { Animatable(0f) },
        remember { Animatable(0f) }
    )
    
    dots.forEachIndexed { index, animatable ->
        LaunchedEffect(animatable) {
            delay(index * 100L)
            animatable.animateTo(
                targetValue = 1f,
                animationSpec = infiniteRepeatable(
                    animation = tween(600, easing = SadaEasing.Standard),
                    repeatMode = RepeatMode.Reverse
                )
            )
        }
    }
    
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        dots.forEach { animatable ->
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .graphicsLayer {
                        translationY = -animatable.value * 8
                    }
                    .background(
                        color = org.sada.messenger.ui.theme.TextSecondary,
                        shape = androidx.compose.foundation.shape.CircleShape
                    )
            )
        }
    }
}

/**
 * Connection status animation
 */
@Composable
fun ConnectionPulseAnimation(
    isConnected: Boolean,
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "connection")
    
    val scale by infiniteTransition.animateFloat(
        initialValue = if (isConnected) 0.8f else 1f,
        targetValue = if (isConnected) 1.2f else 0.8f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = if (isConnected) 1000 else 500,
                easing = SadaEasing.Standard
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "connection_scale"
    )
    
    val alpha by infiniteTransition.animateFloat(
        initialValue = if (isConnected) 0.6f else 0.3f,
        targetValue = if (isConnected) 1f else 0.6f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = if (isConnected) 1000 else 500,
                easing = SadaEasing.Standard
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "connection_alpha"
    )
    
    Box(
        modifier = modifier
            .scale(scale)
            .alpha(alpha)
    )
}

/**
 * Message list scroll animation
 */
@Composable
fun AnimatedMessageList(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    androidx.compose.animation.AnimatedContent(
        targetState = content,
        modifier = modifier,
        transitionSpec = {
            (slideInVertically { height -> height } + fadeIn()) togetherWith
            (slideOutVertically { height -> -height } + fadeOut())
        },
        label = "message_list"
    ) { targetContent ->
        targetContent()
    }
}

/**
 * Expandable section animation
 */
@Composable
fun ExpandableAnimation(
    expanded: Boolean,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    val enterTransition = expandVertically(
        animationSpec = tween(
            durationMillis = AnimationDurations.NORMAL,
            easing = SadaEasing.Standard
        )
    ) + fadeIn(
        animationSpec = tween(
            durationMillis = AnimationDurations.FAST
        )
    )
    
    val exitTransition = shrinkVertically(
        animationSpec = tween(
            durationMillis = AnimationDurations.FAST,
            easing = SadaEasing.Exit
        )
    ) + fadeOut()
    
    AnimatedVisibility(
        visible = expanded,
        modifier = modifier,
        enter = enterTransition,
        exit = exitTransition
    ) {
        content()
    }
}

/**
 * Scale on press animation
 */
@Composable
fun ScaleOnPressAnimation(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    var isPressed by remember { mutableStateOf(false) }
    
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.95f else 1f,
        animationSpec = tween(
            durationMillis = AnimationDurations.INSTANT,
            easing = SadaEasing.Standard
        ),
        label = "press_scale"
    )
    
    Box(
        modifier = modifier
            .scale(scale)
            .pointerInput(onClick) {
                detectTapGestures(
                    onPress = {
                        isPressed = true
                        tryAwaitRelease()
                        isPressed = false
                    },
                    onTap = { onClick() }
                )
            }
    ) {
        content()
    }
}

/**
 * Crossfade content animation
 */
@Composable
fun <T> CrossfadeAnimation(
    targetState: T,
    modifier: Modifier = Modifier,
    content: @Composable (T) -> Unit
) {
    Crossfade(
        targetState = targetState,
        modifier = modifier,
        animationSpec = tween(
            durationMillis = AnimationDurations.NORMAL,
            easing = SadaEasing.Standard
        ),
        label = "crossfade"
    ) { state ->
        content(state)
    }
}

/**
 * Staggered list animation
 */
@Composable
fun StaggeredListAnimation(
    itemCount: Int,
    modifier: Modifier = Modifier,
    content: @Composable (Int) -> Unit
) {
    Column(modifier = modifier) {
        repeat(itemCount) { index ->
            val visible = remember { MutableTransitionState(false) }
            
            LaunchedEffect(Unit) {
                delay(index * 50L)
                visible.targetState = true
            }
            
            AnimatedVisibility(
                visibleState = visible,
                enter = slideInVertically(
                    initialOffsetY = { it / 2 },
                    animationSpec = tween(
                        durationMillis = AnimationDurations.NORMAL,
                        easing = SadaEasing.Standard
                    )
                ) + fadeIn()
            ) {
                content(index)
            }
        }
    }
}
