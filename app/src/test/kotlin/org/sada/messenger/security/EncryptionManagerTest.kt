package org.sada.messenger.security

import io.mockk.every
import io.mockk.mockk
import org.junit.Assert.*
import org.junit.Before
import org.junit.Ignore
import org.junit.Test
import com.goterl.lazysodium.LazySodiumAndroid
import com.goterl.lazysodium.SodiumAndroid
import com.goterl.lazysodium.utils.Key
import com.goterl.lazysodium.utils.KeyPair

// NOTE: These tests require native JNI (.so) from lazysodium-android.
// Run as instrumented tests on a real device: ./gradlew :app:connectedAndroidTest
@Ignore("Requires native JNI - run as instrumented test on device")
class EncryptionManagerTest {

    private lateinit var keyManager: KeyManager
    private lateinit var encryptionManager: EncryptionManager
    private val sodium = LazySodiumAndroid(SodiumAndroid())

    @Before
    fun setup() {
        keyManager = mockk(relaxed = true)

        // Generate a real Curve25519 keypair for testing
        val kp = sodium.cryptoBoxKeypair()
        every { keyManager.getKeyPair() } returns kp

        encryptionManager = EncryptionManager(keyManager)
    }

    @Test
    fun `encrypt then decrypt should return original message`() {
        val testMessage = "Hello, SADA Mesh!"

        // Use a fresh keypair as the "remote" side
        val remoteKp = sodium.cryptoBoxKeypair()
        val sharedSecret = encryptionManager.calculateSharedSecret(remoteKp.publicKey.asBytes)

        val encrypted = encryptionManager.encryptMessage(testMessage, sharedSecret)
        assertNotEquals(testMessage, encrypted)

        val decrypted = encryptionManager.decryptMessage(encrypted, sharedSecret)
        assertEquals(testMessage, decrypted)
    }

    @Test
    fun `different messages should produce different ciphertext`() {
        val remoteKp = sodium.cryptoBoxKeypair()
        val sharedSecret = encryptionManager.calculateSharedSecret(remoteKp.publicKey.asBytes)

        val enc1 = encryptionManager.encryptMessage("Message A", sharedSecret)
        val enc2 = encryptionManager.encryptMessage("Message B", sharedSecret)

        assertNotEquals(enc1, enc2)
    }

    @Test
    fun `same message encrypted twice should produce different ciphertext (nonce randomness)`() {
        val remoteKp = sodium.cryptoBoxKeypair()
        val sharedSecret = encryptionManager.calculateSharedSecret(remoteKp.publicKey.asBytes)
        val message = "Repeated message"

        val enc1 = encryptionManager.encryptMessage(message, sharedSecret)
        val enc2 = encryptionManager.encryptMessage(message, sharedSecret)

        // Nonce is random each time, so ciphertext must differ
        assertNotEquals(enc1, enc2)
    }
}
