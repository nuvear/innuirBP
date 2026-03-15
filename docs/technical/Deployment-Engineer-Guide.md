# Deployment Engineer Guide — InnuirBP

**Document:** Deployment Instructions  
**Date:** 2026-03-15  
**Status:** InnuirBP is the primary app; old project archived

---

## 1. What the Deployment Engineer Needs to Do in Xcode

### Build and Run

1. **Regenerate the Xcode project** from the updated `project.yml`:
   ```bash
   cd innuirBP
   xcodegen generate
   ```

2. **Open** `InnuirBP.xcodeproj` — both targets should appear:
   - **InnuirBP** (main app)
   - **InnuirBPWidget** (widget extension)

3. **Signing:** Select the **InnuirBP HealthKit Dev** manual provisioning profile for the InnuirBP target (Signing & Capabilities). The widget uses automatic signing.

4. **Clean Build** (⇧⌘K) then **Build** (⌘B).

5. **Run on iPad** — select your iPad as destination, then ⌘R.

6. **Verify widget:** After install, the widget should appear in the widget gallery under "Blood Pressure".

---

## 2. What Was Retired

The old **InnuirBP** project has been archived to `archived/InnuirBP-retired/`. The current **InnuirBP** (formerly HealthKitTest) has full feature parity:

| Feature | Status |
|---------|--------|
| HealthKit sync | ✅ Working (with timeout gates, Obj-C wrapper, quantity types only) |
| Manual entry | ✅ |
| SwiftData | ✅ |
| iCloudSyncService | ✅ (identical to InnuirBP) |
| WidgetKit extension | ✅ All families |
| App Groups | ✅ For widget data sharing |
| Clinical guidelines | ✅ AHA/ESC JSON |
| Entitlements | ✅ HealthKit, HealthKit access, background-delivery, App Groups |
| Authorization | ✅ Deferred to Sync tap (on-demand) |
| Timeout | ✅ 30s timeout gates |
| Diagnostic logging | ✅ os.log |

---

## 3. Provisioning Profile

Use **InnuirBP HealthKit Dev** in Developer Portal. Ensure:

- App ID: `com.innuir.bp` with HealthKit enabled
- Profile includes HealthKit
- Device is registered for development

---

## 4. Related Documents

- [ONBOARDING.md](../../ONBOARDING.md) — Full setup for new engineers
- [CHANGELOG.md](../../CHANGELOG.md) — Project history and all changes
- [HealthKit-Setup-and-Troubleshooting.md](./HealthKit-Setup-and-Troubleshooting.md) — HealthKit configuration and troubleshooting
