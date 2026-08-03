package org.sada.messenger.runtime

import androidx.core.content.FileProvider
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class DiagnosticsRecorderTest {
    private val context get() = RuntimeEnvironment.getApplication()

    @Test fun `events remain ordered and bounded to latest 100`() {
        val recorder = DiagnosticsRecorder()
        repeat(105) { recorder.record("test", "event_$it", "success") }
        val events = recorder.snapshot()
        assertEquals(100, events.size)
        assertEquals("event_5", events.first().eventType)
        assertEquals("event_104", events.last().eventType)
        assertEquals(events.sortedBy { it.sequence }, events)
    }

    @Test fun `clear removes all events`() {
        val recorder = DiagnosticsRecorder()
        recorder.record("test", "one", "success")
        recorder.clear()
        assertTrue(recorder.snapshot().isEmpty())
    }

    @Test fun `identifiers are stable redacted tokens`() {
        val recorder = DiagnosticsRecorder()
        val first = recorder.record("test", "one", "success", peerId = "full-peer-public-key", messageId = "full-message-id")
        val second = recorder.record("test", "two", "success", peerId = "full-peer-public-key", messageId = "full-message-id")
        assertEquals(first.peerToken, second.peerToken)
        assertEquals(first.messageToken, second.messageToken)
        assertFalse(first.peerToken!!.contains("full-peer"))
        assertFalse(first.messageToken!!.contains("full-message"))
        assertEquals(16, first.peerToken!!.length)
    }

    @Test fun `network addresses are redacted`() {
        assertEquals("192.168.x.x", DiagnosticsRedactor.ip("192.168.49.1"))
        assertEquals("2001:…", DiagnosticsRedactor.ip("2001:db8:0:1::1"))
    }

    @Test fun `safe diagnostic reason codes remain visible`() {
        assertEquals("permissions_missing", DiagnosticsRedactor.safeReason("permissions_missing"))
        assertEquals("bluetooth_disabled", DiagnosticsRedactor.safeReason("bluetooth_disabled"))
    }

    @Test fun `report is valid versioned JSON and supports empty diagnostics`() {
        val report = DiagnosticsReportFactory.create(context, emptyMap(), emptyMap(), emptyList())
        val json = JSONObject(report.encode())
        assertEquals(1, json.getInt("schemaVersion"))
        assertEquals(0, json.getJSONArray("events").length())
        listOf("device", "app", "runtime", "transport", "ble", "wifiDirect", "udp", "handshake", "relayQueue", "counters")
            .forEach { assertTrue(json.has(it)) }
    }

    @Test fun `export excludes unapproved plaintext keys and payloads`() {
        val secret = "PRIVATE_KEY_MATERIAL_1234567890"
        val plaintext = "message plaintext must never export"
        val report = DiagnosticsReportFactory.create(
            context,
            mapOf("privateKey" to secret, "messagePayload" to plaintext, "myPeerId" to "full-peer-id"),
            mapOf("filesystemPath" to "/Users/person/private"),
            emptyList()
        ).encode()
        assertFalse(report.contains(secret))
        assertFalse(report.contains(plaintext))
        assertFalse(report.contains("full-peer-id"))
        assertFalse(report.contains("/Users/person"))
    }

    @Test fun `FileProvider creates content URI for exported JSON`() {
        val report = DiagnosticsReportFactory.create(context, emptyMap(), emptyMap(), emptyList())
        val file = DiagnosticsExporter.write(context.cacheDir.resolve("diagnostics"), report)
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        assertEquals("content", uri.scheme)
        assertEquals("application/json", "application/json")
        assertTrue(file.readText().startsWith("{"))
    }
}
