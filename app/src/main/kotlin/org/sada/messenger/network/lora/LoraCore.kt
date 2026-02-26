package org.sada.messenger.network.lora

import kotlinx.coroutines.flow.StateFlow

/**
 * Interface for LoRa Transports (Serial, BLE, etc.)
 */
interface LoraInterface {
    val isConnected: StateFlow<Boolean>
    val deviceName: StateFlow<String?>
    
    fun start()
    fun stop()
    fun sendData(data: ByteArray)
    fun setOnDataReceived(callback: (data: ByteArray, rssi: Int?, snr: Double?) -> Unit)
}

/**
 * Handles fragmentation and reassembly of mesh messages over LoRa's limited MTU.
 */
class LoraPacketizer(private val mtu: Int = 200) {
    private val buffer = mutableMapOf<String, MutableMap<Int, ByteArray>>()
    
    // Header format: [MsgIDHash (4B)][TotalChunks (1B)][ChunkIdx (1B)][Payload...]
    fun fragment(messageId: String, data: ByteArray): List<ByteArray> {
        val msgIdHash = messageId.hashCode().toByte() // Simplified 1-byte hash for demo
        val totalChunks = Math.ceil(data.size.toDouble() / (mtu - 3)).toInt()
        val fragments = mutableListOf<ByteArray>()
        
        for (i in 0 until totalChunks) {
            val start = i * (mtu - 3)
            val end = Math.min(start + (mtu - 3), data.size)
            val payload = data.sliceArray(start until end)
            
            val fragment = ByteArray(3 + payload.size)
            fragment[0] = msgIdHash
            fragment[1] = totalChunks.toByte()
            fragment[2] = i.toByte()
            System.arraycopy(payload, 0, fragment, 3, payload.size)
            fragments.add(fragment)
        }
        return fragments
    }
    
    fun reassemble(fragment: ByteArray): ByteArray? {
        if (fragment.size < 4) return null
        
        val msgIdHash = fragment[0].toString()
        val totalChunks = fragment[1].toInt()
        val chunkIdx = fragment[2].toInt()
        val payload = fragment.sliceArray(3 until fragment.size)
        
        val msgBuffer = buffer.getOrPut(msgIdHash) { mutableMapOf() }
        msgBuffer[chunkIdx] = payload
        
        if (msgBuffer.size == totalChunks) {
            // All chunks received
            val result = ByteArray(msgBuffer.values.sumOf { it.size })
            var offset = 0
            for (i in 0 until totalChunks) {
                val chunk = msgBuffer[i] ?: return null
                System.arraycopy(chunk, 0, result, offset, chunk.size)
                offset += chunk.size
            }
            buffer.remove(msgIdHash)
            return result
        }
        return null
    }
}
