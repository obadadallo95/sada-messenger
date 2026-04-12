package org.sada.messenger.security

import android.content.Context
import android.content.pm.PackageManager
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows
import org.robolectric.annotation.Config

/**
 * Unit tests for SecureKeyManager
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33])
class SecureKeyManagerTest {

    private lateinit var context: Context
    private lateinit var keyManager: SecureKeyManager

    @Before
    fun setup() {
        context = RuntimeEnvironment.getApplication()
    }

    private fun shadow() = Shadows.shadowOf(context.packageManager)

    @Test
    fun `isStrongBoxAvailable returns true when feature present`() {
        shadow().setSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE, true)
        val km = SecureKeyManager(context)
        assertTrue(km.isStrongBoxAvailable())
    }

    @Test
    fun `isStrongBoxAvailable returns false when feature absent`() {
        shadow().setSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE, false)
        val km = SecureKeyManager(context)
        assertFalse(km.isStrongBoxAvailable())
    }

    @Test
    fun `getKeyStorageInfo returns StrongBox when available`() {
        shadow().setSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE, true)
        val km = SecureKeyManager(context)
        assertEquals("StrongBox (Hardware)", km.getKeyStorageInfo())
    }

    @Test
    fun `getKeyStorageInfo returns TEE when StrongBox unavailable`() {
        shadow().setSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE, false)
        shadow().setSystemFeature(PackageManager.FEATURE_HARDWARE_KEYSTORE, true)
        val km = SecureKeyManager(context)
        assertEquals("TEE (Hardware-backed)", km.getKeyStorageInfo())
    }

    @Test
    fun `getKeyStorageInfo returns Software when no hardware support`() {
        // No features set — Robolectric defaults to false
        val km = SecureKeyManager(context)
        assertEquals("Software Keystore", km.getKeyStorageInfo())
    }
}
