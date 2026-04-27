package org.sada.messenger.core.workers

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.ListenableWorker
import org.sada.messenger.data.db.AppDatabase
import java.util.*

/**
 * Background worker that cleans up old messages to save storage space.
 * Default retention: 30 days for normal messages, 90 days for emergency/SOS.
 */
class CleanupWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        Log.d("CleanupWorker", "Starting database cleanup...")
        
        return try {
            val database = AppDatabase.getDatabase(applicationContext)
            
            // 1. Purge normal messages older than 30 days
            val calendar = Calendar.getInstance()
            calendar.add(Calendar.DAY_OF_YEAR, -30)
            val cutoffDate = calendar.time
            
            database.messageDao().purgeOldMessages(cutoffDate)
            
            // 2. Purge relay queue expired items (handled by DAO but we can trigger it)
            database.relayQueueDao().removeExpired(Date())
            
            Log.i("CleanupWorker", "Cleanup completed successfully")
            ListenableWorker.Result.success()
        } catch (e: Exception) {
            Log.e("CleanupWorker", "Cleanup failed", e)
            ListenableWorker.Result.retry()
        }
    }
}
