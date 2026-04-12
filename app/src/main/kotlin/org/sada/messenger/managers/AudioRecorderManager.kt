package org.sada.messenger.managers

import android.content.Context
import android.media.MediaRecorder
import android.util.Log
import java.io.File
import java.io.IOException

/**
 * AudioRecorderManager
 * Handles simple voice recording for Crisis Reports and Voice Notes.
 */
class AudioRecorderManager(private val context: Context) {
    private var recorder: MediaRecorder? = null
    private var currentFile: File? = null
    private var isRecording = false
    
    var onMaxDurationReached: (() -> Unit)? = null
    var onAmplitudeChanged: ((Float) -> Unit)? = null
    private val maxDurationMs = 30_000L
    private var startTimeMs = 0L
    
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    private val amplitudePoller = object : Runnable {
        override fun run() {
            if (!isRecording) return
            
            val amplitude = recorder?.maxAmplitude ?: 0
            // Normalize amplitude to 0.0 - 1.0 (Approx 32767 is max for 16-bit PCM)
            onAmplitudeChanged?.invoke(amplitude.toFloat() / 32767f)
            
            val elapsed = System.currentTimeMillis() - startTimeMs
            if (elapsed >= maxDurationMs) {
                onMaxDurationReached?.invoke()
            } else {
                handler.postDelayed(this, 100)
            }
        }
    }

    fun createVoiceTempFile(): File {
        val dir = File(context.cacheDir, "media/voice")
        dir.mkdirs()
        return File(dir, "voice_${System.currentTimeMillis()}.m4a")
    }

    fun startRecording(outputFile: File): Boolean {
        // Reset stale recorder instance if any
        runCatching {
            recorder?.release()
        }
        recorder = null
        isRecording = false
        currentFile = outputFile

        // Ensure parent exists
        outputFile.parentFile?.mkdirs()

        recorder = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            MediaRecorder(context)
        } else {
            MediaRecorder()
        }.apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setAudioEncodingBitRate(96000)
            setAudioSamplingRate(44100)
            setOutputFile(outputFile.absolutePath)
            
            try {
                prepare()
                start()
                isRecording = true
                startTimeMs = System.currentTimeMillis()
                handler.post(amplitudePoller)
            } catch (e: IOException) {
                Log.e("AudioRecorder", "prepare() failed", e)
                runCatching { release() }
                recorder = null
                currentFile = null
                return false
            } catch (e: Exception) {
                Log.e("AudioRecorder", "start() failed", e)
                runCatching { release() }
                recorder = null
                currentFile = null
                return false
            }
        }
        return true
    }

    fun stopRecording(): File? {
        try {
            if (isRecording) {
                isRecording = false
                handler.removeCallbacks(amplitudePoller)
                recorder?.apply {
                    stop()
                }
            }
        } catch (e: Exception) {
            Log.e("AudioRecorder", "stop() failed", e)
        } finally {
            runCatching { recorder?.release() }
        }
        recorder = null
        isRecording = false
        return currentFile
    }

    fun cancelRecording() {
        stopRecording()
        currentFile?.delete()
        currentFile = null
    }
}
