package org.sada.messenger.network

import android.content.Context
import org.sada.messenger.SocketManager
import org.sada.messenger.network.direct.WifiDirectManager

/**
 * Unified multi-transport selector.
 * Priority order is True P2P (Wi-Fi Direct) first, then raw TCP/LAN as fallback.
 */
class TransportManager(
    context: Context,
    private val socketManager: SocketManager,
    private val wifiDirectManager: WifiDirectManager,
) {
    private val appContext = context.applicationContext
    private var switchCount = 0L
    private var lastActiveTransport = "NONE"

    private fun noteTransportSelection(selected: String) {
        if (selected != lastActiveTransport) {
            switchCount++
            lastActiveTransport = selected
        }
    }

    fun sendFramed(bytes: ByteArray): Boolean {
        if (bytes.isEmpty()) return false
        
        // Since both Wi-Fi Direct and LAN fallback use the same TCP SocketManager
        // we just verify if the socket is connected.
        return if (socketManager.isSocketConnected()) {
            val transportType = if (wifiDirectManager.isConnected.value) "True_P2P_Wi-Fi_Direct" else "TCP_LAN_Fallback"
            noteTransportSelection(transportType)
            socketManager.write(bytes)
        } else {
            noteTransportSelection("NONE")
            false
        }
    }

    fun isConnected(): Boolean {
        return socketManager.isSocketConnected()
    }

    fun isNearbyConnected(): Boolean = wifiDirectManager.isConnected.value && socketManager.isSocketConnected()

    fun isLanConnected(): Boolean = !wifiDirectManager.isConnected.value && socketManager.isSocketConnected()

    fun activeTransportLabel(): String {
        return when {
            isNearbyConnected() -> "True_P2P_Wi-Fi_Direct"
            isLanConnected() -> "TCP_LAN_Fallback"
            else -> "NONE"
        }
    }

    private fun blockerHint(): String {
        val p2pConnected = wifiDirectManager.isConnected.value
        val socketConnected = socketManager.isSocketConnected()
        val lanFallbackEnabled = isLanFallbackEnabled()

        return when {
            p2pConnected && socketConnected -> ""
            !lanFallbackEnabled && !socketConnected -> "lan_fallback_disabled_waiting_p2p"
            !p2pConnected && socketConnected -> "p2p_not_connected_using_lan_fallback"
            !p2pConnected && !socketConnected -> "waiting_for_peer_connection"
            p2pConnected && !socketConnected -> "p2p_group_formed_waiting_for_socket"
            else -> "transport_state_unknown"
        }
    }

    fun getDiagnostics(): Map<String, Any> {
        return mapOf(
            "transportPolicy" to "D2D_FIRST",
            "activeTransport" to activeTransportLabel(),
            "transportSwitchCount" to switchCount,
            "isConnected" to isConnected(),
            "isNearbyConnected" to isNearbyConnected(),
            "isLanConnected" to isLanConnected(),
            "lanFallbackEnabled" to isLanFallbackEnabled(),
            "transportBlockerHint" to blockerHint(),
        )
    }

    private fun isLanFallbackEnabled(): Boolean {
        return appContext
            .getSharedPreferences("sada_app_state", Context.MODE_PRIVATE)
            .getBoolean("lan_fallback_enabled", true)
    }
}
