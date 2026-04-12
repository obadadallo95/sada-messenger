package org.sada.messenger.ui.screens

import org.sada.messenger.ui.utils.tr
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import org.sada.messenger.ui.viewmodels.CrisisReportStep
import org.sada.messenger.ui.viewmodels.CrisisReportViewModel
import org.sada.messenger.ui.theme.*
import java.io.File
import java.io.FileOutputStream

@OptIn(ExperimentalMaterial3Api::class, ExperimentalAnimationApi::class)
@Composable
fun CrisisReportScreen(
    viewModel: CrisisReportViewModel,
    onReportGenerated: (File) -> Unit,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val step by viewModel.step.collectAsState()
    val selectedImage by viewModel.selectedImage.collectAsState()
    val isRecording by viewModel.isRecording.collectAsState()

    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri ->
        uri?.let {
            val file = File(context.cacheDir, "temp_report_img_${System.currentTimeMillis()}")
            context.contentResolver.openInputStream(it)?.use { input ->
                FileOutputStream(file).use { output ->
                    input.copyTo(output)
                }
            }
            viewModel.selectImage(file)
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        MeshBackground()

        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text(tr("إنشاء تقرير أزمة", "Crisis Report"), fontWeight = FontWeight.Bold) },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
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
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                AnimatedContent(
                    targetState = step,
                    transitionSpec = { fadeIn() with fadeOut() },
                    label = "step"
                ) { currentStep ->
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        when (currentStep) {
                            CrisisReportStep.SelectImage -> {
                                StepHeader(number = "1", title = tr("اختر دليلاً (اختياري)", "Choose Evidence (Optional)"))
                                Spacer(modifier = Modifier.height(48.dp))
                                GlassButton(
                                    onClick = { launcher.launch("image/*") },
                                    icon = Icons.Default.AddPhotoAlternate,
                                    label = tr("اختر صورة", "Pick Image"),
                                    color = NeonTeal
                                )
                                Spacer(modifier = Modifier.height(24.dp))
                                TextButton(onClick = { viewModel.skipImage() }) {
                                    Text(tr("تخطى الصورة ←", "Skip Image →"), color = Color.White.copy(alpha = 0.7f))
                                }
                            }
                            CrisisReportStep.RecordAudio -> {
                                StepHeader(number = "2", title = tr("سجل الوقائع", "Record Facts"))
                                Spacer(modifier = Modifier.height(32.dp))
                                
                                selectedImage?.let {
                                    AsyncImage(
                                        model = it,
                                        contentDescription = null,
                                        modifier = Modifier
                                            .size(240.dp)
                                            .clip(RoundedCornerShape(24.dp))
                                            .border(2.dp, NeonTeal.copy(alpha = 0.3f), RoundedCornerShape(24.dp))
                                    )
                                }

                                Spacer(modifier = Modifier.height(48.dp))
                                
                                RecordingControl(
                                    isRecording = isRecording,
                                    onStart = { viewModel.startRecording() },
                                    onStop = { viewModel.stopRecording() }
                                )
                            }
                            CrisisReportStep.Processing -> {
                                CircularProgressIndicator(color = NeonTeal)
                                Spacer(modifier = Modifier.height(24.dp))
                                Text(
                                    tr("جارٍ إعداد التقرير...", "Synthesizing report..."),
                                    style = MaterialTheme.typography.titleMedium,
                                    color = Color.White
                                )
                                Text(
                                    tr("نسعى لتأمين البيانات قبل الإرسال", "Securing data before broadcast"),
                                    color = Color.White.copy(alpha = 0.5f),
                                    textAlign = TextAlign.Center,
                                    modifier = Modifier.padding(top = 8.dp)
                                )
                            }
                            is CrisisReportStep.Success -> {
                                Icon(Icons.Default.Verified, contentDescription = null, tint = NeonTeal, modifier = Modifier.size(80.dp))
                                Spacer(modifier = Modifier.height(16.dp))
                                Text(tr("التقرير جاهز", "Report Ready"), fontWeight = FontWeight.Bold, fontSize = 22.sp, color = Color.White)
                                Spacer(modifier = Modifier.height(48.dp))
                                Button(
                                    onClick = { onReportGenerated((currentStep as CrisisReportStep.Success).file) },
                                    modifier = Modifier.fillMaxWidth().height(60.dp),
                                    shape = RoundedCornerShape(16.dp),
                                    colors = ButtonDefaults.buttonColors(containerColor = NeonTeal, contentColor = Color.Black)
                                ) {
                                    Text(tr("إرسال التقرير", "Send Report"), fontWeight = FontWeight.Bold, fontSize = 18.sp)
                                }
                            }
                            is CrisisReportStep.Error -> {
                                Icon(Icons.Default.Error, contentDescription = null, tint = Color.Red, modifier = Modifier.size(80.dp))
                                Spacer(modifier = Modifier.height(16.dp))
                                Text(currentStep.message, color = Color.White, textAlign = TextAlign.Center)
                                Spacer(modifier = Modifier.height(48.dp))
                                Button(onClick = { viewModel.reset() }, shape = RoundedCornerShape(12.dp)) {
                                    Text(tr("حاول ثانية", "Try Again"))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun StepHeader(number: String, title: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Surface(
            shape = CircleShape,
            color = NeonTeal.copy(alpha = 0.1f),
            modifier = Modifier.size(40.dp)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Text(number, color = NeonTeal, fontWeight = FontWeight.Bold)
            }
        }
        Spacer(modifier = Modifier.height(16.dp))
        Text(title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = Color.White)
    }
}

@Composable
fun RecordingControl(isRecording: Boolean, onStart: () -> Unit, onStop: () -> Unit) {
    val infiniteTransition = rememberInfiniteTransition(label = "recording")
    val pulse by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulse"
    )

    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        if (isRecording) {
            Box(contentAlignment = Alignment.Center) {
                Box(
                    modifier = Modifier
                        .size(100.dp)
                        .scale(pulse)
                        .background(Color.Red.copy(alpha = 0.2f), CircleShape)
                )
                FloatingActionButton(
                    onClick = onStop,
                    containerColor = Color.Red,
                    contentColor = Color.White,
                    shape = CircleShape,
                    modifier = Modifier.size(80.dp)
                ) {
                    Icon(Icons.Default.Stop, contentDescription = "Stop", modifier = Modifier.size(40.dp))
                }
            }
            Spacer(modifier = Modifier.height(24.dp))
            Text(tr("جاري التسجيل...", "RECORDING..."), color = Color.Red, fontWeight = FontWeight.Bold)
        } else {
            FloatingActionButton(
                onClick = onStart,
                containerColor = NeonTeal,
                contentColor = Color.Black,
                shape = CircleShape,
                modifier = Modifier.size(80.dp)
            ) {
                Icon(Icons.Default.Mic, contentDescription = "Record", modifier = Modifier.size(40.dp))
            }
            Spacer(modifier = Modifier.height(24.dp))
            Text(tr("اضغط للتحدث ووصف ما حدث", "Tap to describe what happened"), color = Color.White)
            Text(tr("سيتم تحويل الصوت إلى تقرير", "Audio will be converted into a report"), color = Color.White.copy(alpha = 0.5f))
        }
    }
}

@Composable
fun GlassButton(onClick: () -> Unit, icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, color: Color) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(120.dp)
            .clip(RoundedCornerShape(24.dp))
            .clickable(onClick = onClick),
        color = Color.White.copy(alpha = 0.05f),
        border = androidx.compose.foundation.BorderStroke(1.dp, Color.White.copy(alpha = 0.1f))
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(40.dp))
            Spacer(modifier = Modifier.height(12.dp))
            Text(label, fontWeight = FontWeight.Bold, color = Color.White)
        }
    }
}
