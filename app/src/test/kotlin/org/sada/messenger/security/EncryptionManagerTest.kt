package org.sada.messenger.security

import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import android.content.Context

@RunWith(RobolectricTestRunner::class)
class EncryptionManagerTest {
    
    private lateinit var context: Context
    private lateinit var keyManager: KeyManager
    private lateinit var encryptionManager: EncryptionManager

    @Before
    fun setup() {
        context = RuntimeEnvironment.getApplication()
        keyManager = KeyManager(context)
        encryptionManager = EncryptionManager(keyManager)
    }

    @Test
    fun testEncryptionDecryption() {
        val testMessage = "Hello, SADA Mesh!"
        
        // Generate a dummy remote keypair for testing
        val remoteKeyPair = keyManager.generateAndSaveKeyPair() // Just for getting a valid pubkey
        val remotePubKey = remoteKeyPair.publicKey.asBytes
        
        // My shared secret calculation
        val sharedSecret = encryptionManager.calculateSharedSecret(remotePubKey)
        
        // Encrypt
        val encrypted = encryptionManager.encryptMessage(testMessage, sharedSecret)
        assertNotEquals(testMessage, encrypted)
        
        // Decrypt
        val decrypted = encryptionManager.decryptMessage(encrypted, sharedSecret)
        assertEquals(testMessage, decrypted)
    }
}
