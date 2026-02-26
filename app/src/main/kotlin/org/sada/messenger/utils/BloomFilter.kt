package org.sada.messenger.utils

import android.util.Base64
import java.nio.charset.StandardCharsets

/**
 * فلتر بلوم (Bloom Filter) لتقليل حجم البيانات المتداولة أثناء المزامنة
 */
class BloomFilter(
    private var sizeInBits: Int = DEFAULT_SIZE,
    private var numHashFunctions: Int = DEFAULT_HASHES
) {
    companion object {
        const val DEFAULT_SIZE = 8192
        const val DEFAULT_HASHES = 5

        fun fromBase64(
            base64String: String,
            numHashFunctions: Int = DEFAULT_HASHES
        ): BloomFilter {
            val bytes = Base64.decode(base64String, Base64.DEFAULT)
            val filter = BloomFilter(bytes.size * 8, numHashFunctions)
            System.arraycopy(bytes, 0, filter.bits, 0, bytes.size)
            return filter
        }
    }

    private val bits: ByteArray = ByteArray((sizeInBits + 7) / 8)

    /**
     * إضافة عنصر (String) إلى الفلتر
     */
    fun add(item: String) {
        val itemBytes = item.toByteArray(StandardCharsets.UTF_8)
        for (i in 0 until numHashFunctions) {
            val hash = fnv1a(itemBytes, i)
            val index = hash % sizeInBits
            setBit(index)
        }
    }

    /**
     * التحقق من وجود عنصر
     */
    fun contains(item: String): Boolean {
        val itemBytes = item.toByteArray(StandardCharsets.UTF_8)
        for (i in 0 until numHashFunctions) {
            val hash = fnv1a(itemBytes, i)
            val index = hash % sizeInBits
            if (!getBit(index)) {
                return false
            }
        }
        return true
    }

    /**
     * تحويل الفلتر إلى Base64 (للإرسال عبر الشبكة)
     */
    fun toBase64(): String {
        return Base64.encodeToString(bits, Base64.NO_WRAP)
    }

    private fun setBit(index: Int) {
        val byteIndex = index / 8
        val bitIndex = index % 8
        bits[byteIndex] = (bits[byteIndex].toInt() or (1 shl bitIndex)).toByte()
    }

    private fun getBit(index: Int): Boolean {
        val byteIndex = index / 8
        val bitIndex = index % 8
        return (bits[byteIndex].toInt() and (1 shl bitIndex)) != 0
    }

    /**
     * خوارزمية FNV-1a Hash (متوافقة مع نسخة Flutter)
     */
    private fun fnv1a(bytes: ByteArray, seed: Int): Int {
        var hash = -0x7ee3623b // 2166136261 as signed int

        // Mix the seed (salt) first
        hash = hash xor seed
        hash *= 16777619

        for (byte in bytes) {
            hash = hash xor (byte.toInt() and 0xFF)
            hash *= 16777619
        }

        // Ensure positive integer
        return hash and 0x7FFFFFFF
    }
}
