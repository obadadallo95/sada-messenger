# 🚀 Native UDP Broadcast Implementation

## Overview

تم تنفيذ Native Android Layer للـ UDP Broadcast Service بالكامل. النظام الآن يدعم:
- ✅ UDP Socket للاستماع على Port 45454
- ✅ UDP Broadcast للإرسال إلى 255.255.255.255
- ✅ Background Coroutines للاستماع المستمر
- ✅ Filtering للبث الذاتي (تجاهل البث من نفس الجهاز)
- ✅ Battery-efficient lifecycle management
- ✅ Platform Channels للتواصل مع Flutter

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Layer                              │
│  UdpBroadcastService                                         │
│  - start() / stop()                                          │
│  - sendBroadcast()                                           │
│  - _startListening()                                         │
└──────────────────────┬──────────────────────────────────────┘
                       │ MethodChannel / EventChannel
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  Native Android Layer                         │
│  MainActivity.kt                                            │
│  - UDP_METHOD_CHANNEL                                        │
│  - UDP_EVENT_CHANNEL                                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              UdpBroadcastManager.kt                           │
│  - DatagramSocket (Listen)                                  │
│  - DatagramSocket (Broadcast)                               │
│  - CoroutineScope (Background Loop)                          │
│  - MulticastLock (WiFi Broadcast)                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Files Created/Modified

### 1. `UdpBroadcastManager.kt` (New)
**Location**: `android/app/src/main/kotlin/org/sada/messenger/managers/UdpBroadcastManager.kt`

**Key Features**:
- Singleton pattern for single instance
- DatagramSocket bound to Port 45454
- Background Coroutine loop for continuous listening
- MulticastLock for WiFi broadcast support
- Local IP detection (IPv4 only)
- WiFi connection status checking
- Proper resource cleanup

**Methods**:
- `startListening()`: Start UDP service
- `stop()`: Stop UDP service
- `sendBroadcast(message)`: Send UDP broadcast
- `getDeviceIp()`: Get local IP address
- `isWifiConnected()`: Check WiFi status
- `destroy()`: Cleanup resources

---

### 2. `MainActivity.kt` (Updated)
**Location**: `android/app/src/main/kotlin/org/sada/messenger/MainActivity.kt`

**Changes**:
- Added `UDP_METHOD_CHANNEL` constant
- Added `UDP_EVENT_CHANNEL` constant
- Initialized `UdpBroadcastManager` instance
- Added UDP MethodChannel handler
- Added UDP EventChannel handler
- Added cleanup in `onDestroy()`

**MethodChannel Methods**:
- `startUdpService`: Start UDP listening
- `stopUdpService`: Stop UDP service
- `sendBroadcast`: Send UDP broadcast packet
- `getDeviceIp`: Return local IP address
- `isWifiConnected`: Check WiFi connection status

**EventChannel**:
- Streams received UDP packets as JSON: `{"ip": "...", "payload": "..."}`

---

### 3. `AndroidManifest.xml` (Updated)
**Location**: `android/app/src/main/AndroidManifest.xml`

**Added Permissions**:
```xml
<!-- WiFi Multicast Lock (Required for UDP Broadcast) -->
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
```

**Added Network Config**:
```xml
<application
    ...
    android:usesCleartextTraffic="true">
```
*Note: Required for local network UDP traffic*

---

## Implementation Details

### UDP Socket Binding
```kotlin
listenSocket = DatagramSocket(DISCOVERY_PORT).apply {
    broadcastEnabled = true
    reuseAddress = true
}
```

### Background Listening Loop
```kotlin
listenJob = udpScope.launch {
    val buffer = ByteArray(1024)
    while (isActive && isRunning) {
        val packet = DatagramPacket(buffer, buffer.size)
        listenSocket?.receive(packet)
        // Process packet...
    }
}
```

### Multicast Lock
```kotlin
val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as? WifiManager
multicastLock = wifiManager?.createMulticastLock("SadaUDP")
multicastLock?.setReferenceCounted(true)
multicastLock?.acquire()
```

### Local IP Detection
- Iterates through network interfaces
- Filters out loopback and virtual interfaces
- Returns first IPv4 address found
- Used for filtering self-broadcasts

---

## Flutter Integration

### Event Channel Name
- Flutter: `org.sada.messenger/udpEvents`
- Native: `org.sada.messenger/udpEvents` ✅

### Method Channel Name
- Flutter: `org.sada.messenger/udp`
- Native: `org.sada.messenger/udp` ✅

### Event Format
```json
{
  "payload": "SADA_DISCOVERY|v1|DeviceId|Port",
  "ip": "192.168.1.100"
}
```

---

## Testing Checklist

- [ ] UDP Service starts successfully
- [ ] UDP Service stops cleanly
- [ ] Broadcast packets are sent every N seconds
- [ ] Received packets are filtered (self-broadcasts ignored)
- [ ] Events are streamed to Flutter correctly
- [ ] Local IP is detected correctly
- [ ] WiFi connection status is accurate
- [ ] MulticastLock is acquired/released properly
- [ ] Resources are cleaned up on destroy
- [ ] No memory leaks in background loop

---

## Performance Considerations

1. **Battery Efficiency**:
   - Background Coroutine uses `Dispatchers.IO`
   - Socket timeout prevents blocking indefinitely
   - Proper cleanup prevents resource leaks

2. **Network Efficiency**:
   - Small payload size (minimal overhead)
   - Filtering prevents processing own broadcasts
   - Single socket instance (reused)

3. **Memory Management**:
   - Singleton pattern (single instance)
   - Proper cleanup in `destroy()`
   - Coroutine cancellation on stop

---

## Error Handling

- **Socket Binding**: Try-catch with fallback
- **Network Errors**: Logged, loop continues
- **MulticastLock**: Null-safe handling
- **IP Detection**: Returns "unknown" on failure
- **WiFi Check**: Returns false on exception

---

## Future Enhancements

1. **IPv6 Support**: Add IPv6 address detection
2. **Network State Monitoring**: Listen to WiFi state changes
3. **Retry Logic**: Automatic retry on socket errors
4. **Packet Validation**: Validate payload format before processing
5. **Rate Limiting**: Prevent broadcast flooding
6. **Encryption**: Encrypt UDP payloads (optional)

---

## Troubleshooting

### UDP Broadcast Not Working
1. Check WiFi connection status
2. Verify MulticastLock is acquired
3. Check AndroidManifest permissions
4. Verify `usesCleartextTraffic="true"`

### Events Not Received in Flutter
1. Verify EventChannel name matches
2. Check EventSink is set correctly
3. Verify JSON format is correct
4. Check Logcat for errors

### Local IP Not Detected
1. Check WiFi is connected
2. Verify network interfaces are accessible
3. Check for IPv4 address availability

---

**Last Updated**: 2024
**Status**: ✅ Complete & Ready for Testing

