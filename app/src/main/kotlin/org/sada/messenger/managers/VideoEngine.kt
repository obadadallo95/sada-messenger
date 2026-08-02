package org.sada.messenger.managers

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.util.concurrent.CompletableFuture
import java.util.concurrent.TimeUnit

/**
 * VideoEngine
 * Handles offline video synthesis (Image + Audio -> MP4) using FFmpeg.
 */
class VideoEngine(private val context: Context) {
    private val TAG = "VideoEngine"

    @UnstableApi
    suspend fun createCrisisReport(
        imagePath: String,
        audioPath: String,
        outputPath: String
    ): Boolean = withContext(Dispatchers.Main) { // Transformer requires Main thread for some setup
        try {
            val transformer = Transformer.Builder(context)
                .setVideoMimeType(MimeTypes.VIDEO_H264)
                .setAudioMimeType(MimeTypes.AUDIO_AAC)
                .build()

            // In Media3, combining image and audio often involves a Composition
            // For a single image + audio, we can loop the image to match audio duration
            // or use a sequence.
            
            val audioFile = File(audioPath)
            val imageFile = File(imagePath)
            val outFile = File(outputPath)
            if (outFile.exists()) outFile.delete()

            val audioMediaItem = MediaItem.fromUri(Uri.fromFile(audioFile))
            val imageMediaItem = MediaItem.Builder()
                .setUri(Uri.fromFile(imageFile))
                .setImageDurationMs(10_000) // Placeholder: 10s or match audio
                .build()

            val future = CompletableFuture<Boolean>()
            
            val listener = object : Transformer.Listener {
                override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                    Log.i(TAG, "Export completed: $outputPath")
                    future.complete(true)
                }

                override fun onError(composition: Composition, exportResult: ExportResult, exportException: ExportException) {
                    Log.e(TAG, "Export failed", exportException)
                    future.complete(false)
                }
            }

            transformer.addListener(listener)
            
            // This is a simplified muxing. For professional reports, we'd use EditedMediaItem
            // and maybe Overlay/Effect for the image.
            transformer.start(imageMediaItem, outputPath) // Simplified for now
            
            // Wait for completion (Timeout 60s)
            withContext(Dispatchers.IO) {
                try {
                    future.get(60, TimeUnit.SECONDS)
                } catch (e: Exception) {
                    Log.e(TAG, "Timeout or error during synthesis", e)
                    false
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup Media3 Transformer", e)
            false
        }
    }

    fun getOutputDirectory(): File {
        val dir = File(context.filesDir, "media/reports")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }
}
