# Delivery / GitHub Checklist

## Before push
- [ ] `./gradlew :app:compileDebugKotlin`
- [ ] `./gradlew :app:assembleDebug`
- [ ] No debug-generated artifacts staged (`app/build`, logs, caches).
- [ ] Theme check in dark + light.
- [ ] Language check in Arabic + English.
- [ ] Diagnostics page opens and shows transport counters.

## For transport-related changes
- [ ] Two physical devices on same LAN tested.
- [ ] UDP discovery received on both sides.
- [ ] Socket connection established.
- [ ] Handshake ACK observed.
- [ ] `connectedPeers > 0` when ready.
- [ ] Message ACK increments + status updated.

## For release
- [ ] Foreground service notification shows status/actions.
- [ ] Battery optimization prompt path works.
- [ ] App lock flow verified (if enabled).
- [ ] Legal pages open as full pages.

## Commit hygiene
- [ ] Keep commits scoped by concern (docs, transport, ui, security).
- [ ] Never commit secrets, keystores, or local machine files.
