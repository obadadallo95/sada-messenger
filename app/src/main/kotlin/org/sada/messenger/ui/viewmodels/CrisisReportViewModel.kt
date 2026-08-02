package org.sada.messenger.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.media3.common.util.UnstableApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import org.sada.messenger.managers.AudioRecorderManager
import org.sada.messenger.managers.VideoEngine
import java.io.File
import java.util.*

sealed class CrisisReportStep {
    object SelectImage : CrisisReportStep()
    object RecordAudio : CrisisReportStep()
    object Processing : CrisisReportStep()
    data class Success(val file: File) : CrisisReportStep()
    data class Error(val message: String) : CrisisReportStep()
}

class CrisisReportViewModel(
    private val videoEngine: VideoEngine,
    private val audioRecorderManager: AudioRecorderManager
) : ViewModel() {

    private val _step = MutableStateFlow<CrisisReportStep>(CrisisReportStep.SelectImage)
    val step = _step.asStateFlow()

    private val _selectedImage = MutableStateFlow<File?>(null)
    val selectedImage = _selectedImage.asStateFlow()

    private val _isRecording = MutableStateFlow(false)
    val isRecording = _isRecording.asStateFlow()

    private var recordedAudioFile: File? = null

    fun selectImage(file: File) {
        _selectedImage.value = file
        _step.value = CrisisReportStep.RecordAudio
    }

    fun skipImage() {
        // Allow proceeding without image - image is now optional
        _step.value = CrisisReportStep.RecordAudio
    }

    fun startRecording() {
        val file = File(videoEngine.getOutputDirectory(), "temp_audio_${System.currentTimeMillis()}.m4a")
        if (audioRecorderManager.startRecording(file)) {
            _isRecording.value = true
        }
    }

    fun stopRecording() {
        recordedAudioFile = audioRecorderManager.stopRecording()
        _isRecording.value = false
        generateReport()
    }

    @androidx.annotation.OptIn(markerClass = [UnstableApi::class])
    private fun generateReport() {
        val image = _selectedImage.value
        val audio = recordedAudioFile
        
        // Audio is required, image is optional
        if (audio == null) {
            _step.value = CrisisReportStep.Error("Missing audio recording")
            return
        }

        _step.value = CrisisReportStep.Processing

        viewModelScope.launch {
            val outputFile = File(videoEngine.getOutputDirectory(), "report_${UUID.randomUUID()}.mp4")
            // If no image, create audio-only report or use placeholder
            val success = if (image != null) {
                videoEngine.createCrisisReport(
                    imagePath = image.absolutePath,
                    audioPath = audio.absolutePath,
                    outputPath = outputFile.absolutePath
                )
            } else {
                // Audio-only report - copy audio file as output
                try {
                    audio.copyTo(outputFile, overwrite = true)
                    true
                } catch (e: Exception) {
                    false
                }
            }
            
            if (success) {
                _step.value = CrisisReportStep.Success(outputFile)
            } else {
                _step.value = CrisisReportStep.Error("Synthesis failed")
            }
            
            // Cleanup temp audio
            audio.delete()
        }
    }

    fun reset() {
        _selectedImage.value = null
        _step.value = CrisisReportStep.SelectImage
    }
}
