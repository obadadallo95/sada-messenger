# Phase 1 physical-device checklist

Status: not yet executed. Unit tests cannot verify Android radio or OEM background behavior.

Record device model, Android version, commit, permissions, battery restrictions, timestamps, logs, and runtime diagnostics for every run.

- [ ] Open the app and send a direct message through the canonical runtime.
- [ ] Destroy the activity while the foreground service remains; receive and persist an incoming packet.
- [ ] Lock the screen; verify the service remains active and document encounter latency.
- [ ] Swipe the app task away; document whether the service remains or restarts under the device policy.
- [ ] Kill the process and allow service restart where Android permits; verify exactly one runtime graph.
- [ ] Deliver an incoming packet while the UI is closed.
- [ ] Place a relay row in Room before restart; verify the service-owned relay pump attempts it after recreation.
- [ ] Reopen the UI and verify Room messages, connection state, and diagnostics are consistent.
- [ ] Rotate/recreate the activity repeatedly; verify no extra BLE scan, Wi-Fi Direct receiver, group creation, UDP callback, or socket callback.
- [ ] Pause/resume the service twice; verify start/stop counters advance once per transition and callbacks detach on stop.
