package org.sada.messenger.utils

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.content.FileProvider
import java.io.File

/**
 * Helper class to share the app APK with others
 * Enables offline app distribution for mesh network growth
 */
object ShareApkHelper {

    private const val TAG = "ShareApkHelper"

    /**
     * Share the current app APK via system share dialog
     */
    fun shareApp(context: Context) {
        try {
            val apkUri = getApkUri(context) ?: run {
                Log.e(TAG, "Could not get APK URI")
                return
            }

            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "application/vnd.android.package-archive"
                putExtra(Intent.EXTRA_STREAM, apkUri)
                putExtra(Intent.EXTRA_SUBJECT, "صدى - Sada Messenger")
                putExtra(
                    Intent.EXTRA_TEXT,
                    "جرب تطبيق صدى للمراسلة بدون إنترنت!\n\n" +
                            "Try Sada Messenger - works without internet!\n\n" +
                            "https://github.com/obadadallo/sada"
                )
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            val chooser = Intent.createChooser(
                shareIntent,
                "Share Sada Messenger"
            )
            context.startActivity(chooser)

            Log.i(TAG, "App shared successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to share app", e)
        }
    }

    /**
     * Get the APK file URI
     */
    private fun getApkUri(context: Context): Uri? {
        return try {
            val packageManager = context.packageManager
            val packageName = context.packageName
            val packageInfo = packageManager.getPackageInfo(packageName, 0)

            // Get the APK path
            val applicationInfo = packageInfo.applicationInfo
            val apkPath = applicationInfo?.sourceDir ?: return null

            val apkFile = File(apkPath)

            if (!apkFile.exists()) {
                Log.e(TAG, "APK file not found at: $apkPath")
                return null
            }

            // Use FileProvider for Android N+ (API 24+)
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.fileprovider",
                    apkFile
                )
            } else {
                Uri.fromFile(apkFile)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting APK URI", e)
            null
        }
    }

    /**
     * Check if APK sharing is available
     */
    fun canShareApp(context: Context): Boolean {
        return try {
            val packageName = context.packageName
            val packageInfo = context.packageManager.getPackageInfo(packageName, 0)
            packageInfo.applicationInfo?.sourceDir != null
        } catch (e: Exception) {
            false
        }
    }
}
