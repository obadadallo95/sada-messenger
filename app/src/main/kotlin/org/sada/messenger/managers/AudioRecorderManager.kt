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

    fun startRecording(outputFile: File): Boolean {
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
            setOutputFile(outputFile.absolutePath)
            
            try {
                prepare()
                start()
            } catch (e: IOException) {
                Log.e("AudioRecorder", "prepare() failed", e)
                return false
            } catch (e: Exception) {
                Log.e("AudioRecorder", "start() failed", e)
                return false
            }
        }
        return true
    }

    fun stopRecording(): File? {
        try {
            recorder?.apply {
                stop()
                release()
            }
        } catch (e: Exception) {
            Log.e("AudioRecorder", "stop() failed", e)
        }
        recorder = null
        return currentFile
    }

    fun cancelRecording() {
        stopRecording()
        currentFile?.delete()
        currentFile = null
    }
}
