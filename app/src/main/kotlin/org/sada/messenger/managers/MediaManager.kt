package org.sada.messenger.managers

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import java.io.File
import java.io.FileOutputStream
import java.util.*

/**
 * MediaManager
 * Handles copying files from URIs to internal app storage for mesh persistence.
 */
class MediaManager(private val context: Context) {
    
    fun saveMediaToInternalStorage(uri: Uri): File? {
        val fileName = getFileName(uri) ?: UUID.randomUUID().toString()
        val destFile = File(getMediaDirectory(), fileName)
        
        try {
            context.contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(destFile).use { output ->
                    input.copyTo(output)
                }
            }
            return destFile
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    private fun getMediaDirectory(): File {
        val dir = File(context.filesDir, "media/received")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    private fun getFileName(uri: Uri): String? {
        var result: String? = null
        if (uri.scheme == "content") {
            val cursor = context.contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val index = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index != -1) result = it.getString(index)
                }
            }
        }
        if (result == null) {
            result = uri.path
            val cut = result?.lastIndexOf('/')
            if (cut != -1) {
                result = result?.substring(cut!! + 1)
            }
        }
        return result
    }
}
