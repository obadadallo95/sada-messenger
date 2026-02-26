package org.sada.messenger.security

import android.content.Context
import android.util.Log
import org.sada.messenger.data.db.AppDatabase
import kotlin.system.exitProcess

/**
 * مدير وضع الطوارئ (Duress Manager)
 * يقوم بمسح كافة البيانات الحساسة فوراً وبشكل نهائي في حال استخدامه
 */
class DuressManager(
    private val context: Context,
    private val database: AppDatabase,
    private val keyManager: KeyManager
) {
    companion object {
        private const val TAG = "SadaDuress"
    }

    /**
     * مسح شامل لكافة البيانات (Wipe Everything)
     */
    fun triggerWipeEverything() {
        Log.w(TAG, "DURESS TRIGGERED: Wiping all data...")
        
        try {
            // 1. Delete Encryption Keys
            keyManager.deleteKeys()
            
            // 2. Clear App State Preference
            context.getSharedPreferences("sada_app_state", Context.MODE_PRIVATE)
                .edit().clear().apply()
            
            // 3. Clear Database
            // We use a separate thread/scope to ensure it starts before process death
            Thread {
                try {
                    database.clearAllTables()
                    Log.i(TAG, "Database tables cleared")
                    
                    // 4. Kill Process to ensure nothing remains in memory
                    exitProcess(0)
                } catch (e: Exception) {
                    Log.e(TAG, "Error clearing database during duress", e)
                }
            }.start()
            
        } catch (e: Exception) {
            Log.e(TAG, "Critical error during duress wipe", e)
        }
    }
}
