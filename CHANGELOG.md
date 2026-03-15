# Changelog — InnuirBP

All notable changes for engineer onboarding. See [ONBOARDING.md](ONBOARDING.md) for setup.

---

## 2026-03-15 — Project Restructure & HealthKit Fixes

### Summary

HealthKit sync was fixed and the project was consolidated. **HealthKitTest** (working) was merged into **InnuirBP**. The old InnuirBP project was archived.

### Changes

#### 1. Project Merge & Rename

- **HealthKitTest** → **InnuirBP** (renamed and promoted to main app)
- Old **InnuirBP** → **archived/InnuirBP-retired/** (reference only)
- Project now uses **XcodeGen** (`project.yml` at root)
- Single scheme: **InnuirBP** (main app + widget)

#### 2. HealthKit Fixes Applied

| Fix | Description |
|-----|-------------|
| **Quantity types only** | `requestAuthorization` requests only `bloodPressureSystolic` and `bloodPressureDiastolic` — not the correlation type. The correlation type caused "Authorization to read... is disallowed" error. |
| **Obj-C HealthKitAuthHelper** | Wraps `requestAuthorization` in `@try/@catch`. HealthKit throws `NSException` when entitlement is missing; Swift cannot catch it. Prevents crash, shows error instead. |
| **Continuation resume** | Resume `withCheckedContinuation` directly from HealthKit completion block. Using `Task { @MainActor in continuation.resume() }` caused deadlock. |
| **Deferred auth** | Authorization runs when user taps Sync, not at app launch. Launch-time auth crashed when entitlement was missing. |
| **30s timeout gates** | `ContinuationGate` and `ThrowingContinuationGate` race HealthKit completion against 30s timeout. Prevents indefinite hang. |
| **Diagnostic logging** | `os.log` at each stage (subsystem: `com.innuir.bp.test`). Filter in Console.app. |

#### 3. Provisioning

- **Manual profile required:** "InnuirBP HealthKit Dev"
- Automatic signing often omits HealthKit from the profile
- App ID `com.innuir.bp` must have HealthKit enabled in Developer Portal

#### 4. File Renames

- `HealthKitTest.entitlements` → `InnuirBP.entitlements`
- `HealthKitTest-Bridging-Header.h` → `InnuirBP-Bridging-Header.h`
- `CFBundleDisplayName`: "HealthKit Test" → "Innuir BP"

#### 5. Documentation Added

- `docs/technical/HealthKit-Setup-and-Troubleshooting.md` — Setup, patterns, error fixes
- `docs/technical/Deployment-Engineer-Guide.md` — Build steps, provisioning
- `docs/technical/HealthKit-Sync-Hang-Report.md` — Updated with resolved status
- `ONBOARDING.md` — Rewritten for new engineers
- `CHANGELOG.md` — This file

#### 6. Project Structure (Current)

```
innuirBP/
├── project.yml
├── InnuirBP.xcodeproj
├── InnuirBP/           # App sources
├── InnuirBPWidget/     # Widget extension
├── docs/
├── archived/
│   └── InnuirBP-retired/
└── ...
```

### For New Engineers

1. Read [ONBOARDING.md](ONBOARDING.md) first
2. Use manual provisioning profile "InnuirBP HealthKit Dev"
3. Run `xcodegen generate` after pulling
4. Do not modify HealthKit patterns without reading [HealthKit-Setup-and-Troubleshooting.md](docs/technical/HealthKit-Setup-and-Troubleshooting.md)
