# Code Style, Localization, and Contribution Rules

## 1) Kotlin/Compose coding rules
- Use clear feature boundaries:
  - UI: `ui/screens`, `ui/viewmodels`
  - Domain/network/security: dedicated packages
  - Data persistence: Room entities/dao/db
- Prefer `StateFlow`/immutable state exposure for shared state.
- Keep network and crypto work on `Dispatchers.IO`.
- Avoid silent catches; log context with component tag.
- Keep diagnostics fields updated when changing transport behavior.

## 2) Naming and structure
- Use explicit names (`sendMeshMessage`, `handleHandshakeAck`).
- Keep one responsibility per function when possible.
- Put constants in companion objects.

## 3) UI style rules
- Do not hardcode `Color.White`/`Color.Black` for dynamic themes.
- Prefer `MaterialTheme.colorScheme` for text/background/icon colors.
- Ensure contrast in both dark/light modes before merge.

## 4) Localization strategy
The codebase currently uses two parallel methods:
1. Resource strings (`values/strings.xml`, `values-ar/strings.xml`).
2. Inline helper `tr(ar, en)` based on current locale.

### Required policy
- New reusable UI text should go to `strings.xml` (+ Arabic counterpart).
- `tr()` is allowed for rapid parity migration, but should be reduced over time.
- Every new feature must be verified in both Arabic and English.
- Layout must respect RTL/LTR behavior from locale.

## 5) Translation QA checklist
- Switch language from settings and verify full-screen reload.
- Verify app bar titles, labels, buttons, empty states.
- Verify no mixed-language leftovers on the same screen unless intentional.
- Verify direction-sensitive icons/text alignment in RTL mode.

## 6) Pull request expectations
Each functional PR should include:
- What changed.
- Why it changed.
- Impacted files/routes.
- Diagnostics keys affected.
- Manual test steps (2-device scenario for transport changes).
