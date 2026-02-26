# UI Screens and Functional Flows

## 1) Screen Inventory
Main UI screens:
- `OnboardingScreen`
- `RegisterScreen`
- `HomeScreen`
- `AddedContactsScreen` (friends list)
- `ContactsScreen` (QR add/scan)
- `GroupsScreen`
- `ChatScreen`
- `CreateGroupScreen`
- `SettingsScreen`
- `MeshDiagnosticsScreen`
- `MyQrScreen`
- `CrisisReportScreen`

## 2) Core Flows

### A) Registration flow
1. Onboarding
2. Identity creation (nickname + keypair)
3. Home entry + foreground mesh service start

### B) Add friend (QR)
1. Open Add screen.
2. Show own QR (public identity).
3. Scan peer QR.
4. Save contact and open chat path.

### C) Message flow
1. User sends text/voice/media in chat.
2. MeshEngine stores to relay queue and tries direct forward.
3. ACK updates message status to delivered.
4. Chat list and details should both reflect same status source.

### D) Group flow
1. Create group with policy (`open`, `approval`, `invite_only`).
2. Discover nearby groups.
3. Join directly or request approval.
4. Group owner handles pending join requests.

### E) Diagnostics flow
Shows mesh truth in real time:
- service state
- peer state
- relay queue metrics
- handshake/ack metrics
- UDP transport telemetry

## 3) UI Truthfulness Requirements
- No hardcoded network numbers in production screens.
- Every indicator must map to runtime state.
- Chat list and chat detail must use consistent message source and chatId mapping.

## 4) Current UX issues to track
- Any missing text in light theme must be treated as a contrast bug.
- Any screen action without backend effect must be hidden or disabled.
- Keep settings/legal pages full-screen (not modal popups) for readability.
