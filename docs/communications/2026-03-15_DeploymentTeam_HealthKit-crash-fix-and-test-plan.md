# Deployment Team — HealthKit Crash Fix & Test Plan

**Date:** 2026-03-15  
**Audience:** Deployment Team  
**Subject:** InnuirBP HealthKit sync crash fix — build verification and test instructions

---

## What's Ready

| Item | Status |
|------|--------|
| **Crash fix** | Logically sound — three defense layers in place |
| **HealthKit call paths** | All covered (only one exists: `HealthKitService.requestAuthorization()`) |
| **Error surfacing** | UI now shows errors instead of failing silently |

The app no longer crashes when HealthKit authorization fails (e.g., missing entitlement). Instead, it displays a "Sync Failed" alert with a descriptive message.

---

## What Should Happen First

### 1. Build Verification

**These changes need to be compiled.** Someone with **Xcode 16+** should:

1. **Clean Build Folder** — Shift+Cmd+K  
2. **Build** — Cmd+B  
3. Confirm **zero errors** (and ideally zero new warnings)

The Objective-C `__attribute__((noinline))` and the new function signature must pass through the bridging header cleanly. If the build fails, report the error before proceeding.

---

### 2. HealthKit Entitlement Decision

The crash fix **prevents the crash**, but sync will still fail gracefully with an alert saying the entitlement is missing until HealthKit is enabled on the App ID.

**Two options for the deployment team:**

| Option | Description |
|--------|-------------|
| **(a)** | Test the crash fix as-is — expect the "Sync Failed" alert instead of a crash |
| **(b)** | First enable HealthKit on the App ID `com.innuir.bp` in Apple Developer Portal ([ONBOARDING.md](../../ONBOARDING.md) Section 3.3), then test the full happy path |

**Recommendation:** **Option (b)** — Enable the HealthKit entitlement first, then run the full test plan. This validates both the crash fix and the actual sync flow in one pass.

---

### 3. How to Enable HealthKit on the App ID

1. Go to [developer.apple.com](https://developer.apple.com) → **Account** → **Certificates, Identifiers & Profiles**
2. **Identifiers** → select **com.innuir.bp**
3. Under **Capabilities**, enable **HealthKit**
4. **Save**
5. In Xcode: **Clean Build Folder** (Shift+Cmd+K), then **Build** (Cmd+B)
6. Delete the app from the device and reinstall (Cmd+R)

---

## Recommended Test Plan

Execute these tests in order. Log results (pass/fail) and any notes.

| # | Test | Expected Result |
|---|------|-----------------|
| 1 | **Clean build succeeds** | No errors or warnings |
| 2 | **App launches on iPad** (same iPad16,6 if possible) | No crash at launch |
| 3 | **Tap Sync without HealthKit entitlement enabled** | "Sync Failed" alert with descriptive message — **no crash** |
| 4 | **Enable HealthKit on App ID**, rebuild, tap Sync | HealthKit permission sheet appears |
| 5 | **Grant permission**, tap Sync again | Readings import; "Last sync" updates |
| 6 | **Manual entry** via + button | Reading saved; widget updates |
| 7 | **Widget displays** on Home Screen | Shows latest reading |

**Note on Test 3:** If you enable HealthKit first (Option b), you can still validate the crash fix by temporarily revoking the entitlement or testing on a separate provisioning profile. Otherwise, run Test 3 before enabling HealthKit.

---

## Summary

1. **Build** — Clean build, confirm zero errors  
2. **Enable HealthKit** — On App ID `com.innuir.bp` in Developer Portal (recommended before deployment)  
3. **Run test plan** — All 7 tests above  
4. **Report** — Log results in `docs/communications/` (e.g., `2026-03-15_Deployment_iPad-test-results.md`)

---

## Contact

For questions about the crash fix or test plan, refer to:
- `ONBOARDING.md` — Developer onboarding, Section 3.3 (HealthKit setup)
- `docs/communications/2026-03-15_iPad-deployment-status-and-sync-instructions.md` — Full deployment status
