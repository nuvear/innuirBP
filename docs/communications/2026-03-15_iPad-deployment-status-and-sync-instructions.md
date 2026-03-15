# iPad Deployment Status & Data Sync Fix Instructions

**Date:** 2026-03-15  
**Author:** Deployment Engineer  
**Audience:** InnuirBP Developers  
**Status:** App runs on iPad; HealthKit sync requires Developer Portal configuration

---

## Executive Summary

The InnuirBP app **launches and runs on iPad** (tested on iPad16,6, iOS 26.0.1). Several launch and navigation crashes were resolved. **HealthKit data sync** (importing blood pressure readings from Apple Health) will fail or crash until the HealthKit capability is correctly enabled for the App ID in Apple Developer Portal. This document provides the current status, what was fixed, and step-by-step instructions for developers to enable data sync.

---

## Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| App launch | ✅ Working | SwiftData ModelContainer simplified; no longer crashes |
| Summary screen | ✅ Working | Displays; "Never synced" shown until first successful sync |
| Blood Pressure tile / BP Detail | ✅ Working | GuidelineLoader no longer crashes; chart displays (with or without guideline bands) |
| Manual entry | ✅ Working | Users can add readings without HealthKit |
| **HealthKit sync** | ⚠️ Blocked | Requires HealthKit capability on App ID; see instructions below |
| Widget | ✅ Working | App Group configured; widget displays snapshot when data exists |

---

## Fixes Applied (2026-03-15)

### 1. SwiftData ModelContainer crash (app launch)

**Problem:** Both local and in-memory `ModelContainer` creation failed on device, triggering `fatalError`.

**Fix:** Simplified to `ModelContainer(for: BPReading.self)` with in-memory fallback. No explicit `Schema` or custom `ModelConfiguration` for the default case.

**File:** `InnuirBP/Services/iCloudSyncService.swift`

---

### 2. HealthKit authorization crash (Sync tap)

**Two root causes, both fixed:**

**Cause A — Wrong API overload:** The async/await overload `requestAuthorization(toShare:read:)` has a non-optional `toShare` parameter. Passing an empty `Set` triggers `_throwIfAuthorizationDisallowedForSharing`, which raises an `NSException`. Swift's `do/catch` cannot catch `NSException`; the process terminates.

**Fix:** Use the completion-handler overload with `toShare: nil`, bridged to async/await via `withCheckedContinuation`. Only the completion-handler API accepts `nil` for read-only authorization.

**Cause B — Missing Info.plist keys:** Apple requires `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription`; without them, the app crashes when requesting authorization.

**Fix:** `InnuirBP/Info.plist` includes both keys with appropriate usage strings.

**Additional:** Added `com.apple.developer.healthkit` entitlement; deferred authorization to first Sync tap so the app launches even before HealthKit is configured.

**Files:** `InnuirBP/Services/HealthKitService.swift`, `InnuirBP/Info.plist`, `InnuirBP/InnuirBP.entitlements`, `InnuirBP/Application/InnuirBPApp.swift`

---

### 3. GuidelineLoader crash (Blood Pressure tile)

**Problem:** `assertionFailure` when guideline JSON files failed to load (e.g., different bundle structure on device).

**Fix:** Removed `assertionFailure`; added fallback to load from `Guidelines` subdirectory. Returns `nil` gracefully so the chart still renders without guideline bands.

**File:** `InnuirBP/Models/ClinicalGuideline.swift`

---

## Data Sync Issue — Root Causes (Resolved)

HealthKit sync is triggered when the user taps the **Sync** (↻) button in the Summary screen toolbar. Multiple issues were identified and fixed:

1. **Wrong API overload:** The async/await `requestAuthorization(toShare:read:)` does not accept `nil` for `toShare`. Passing `[]` triggers `_throwIfAuthorizationDisallowedForSharing` → `NSException` → process termination (Swift cannot catch it).
2. **Missing Info.plist:** `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` are required; without them, the app crashes on authorization request.
3. **Missing `com.apple.developer.healthkit.access` (iOS 26):** The HealthKit capability was enabled in Developer Portal and `com.apple.developer.healthkit` was in the entitlements file — but the **`com.apple.developer.healthkit.access`** sub-entitlement was missing. On iOS 26, HealthKit requires this key to define the access scope. Without it, the authorization request is rejected with "Authorization to read the following types is disallowed" even though the base entitlement is present. **Fix:** Added `com.apple.developer.healthkit.access = []` (standard health data scope) to `InnuirBP.entitlements`.

Additionally, the **provisioning profile** must include HealthKit (enable it on the App ID in Developer Portal) for authorization to succeed.

---

## What to Do Now

1. In Xcode: **pull the latest** (`git pull origin main`) or let Xcode detect the changes
2. **Verify Info.plist** is in the target: select Info.plist in the navigator → check it appears under the InnuirBP target in File Inspector. If not, drag it into the target's **Build Phases → Copy Bundle Resources**
3. **Clean Build Folder** (⇧⌘K)
4. **Delete the app from the iPad** and reinstall (⌘R)
5. **Tap Sync** (↻) — the HealthKit permission sheet should appear
6. **Grant Read access** to Blood Pressure data

---

## Instructions for Developers: Enable HealthKit Data Sync

Follow these steps to enable HealthKit sync on physical devices.

### Step 1: Enable HealthKit on the App ID

1. Go to [developer.apple.com](https://developer.apple.com) → **Account** → **Certificates, Identifiers & Profiles**
2. Select **Identifiers** in the sidebar
3. Find and select the App ID **com.innuir.bp** (or create it if it does not exist)
4. Under **Capabilities**, enable:
   - **HealthKit** (required for blood pressure read access)
   - **Health Records** (optional; only if you plan to use clinical health record types)
5. Click **Save**

### Step 2: Regenerate Provisioning Profiles

1. In Xcode, select the **InnuirBP** target
2. Open **Signing & Capabilities**
3. Ensure **Automatically manage signing** is enabled
4. Select your Team
5. Xcode will regenerate the provisioning profile on the next build

### Step 3: Clean Build and Reinstall

1. In Xcode: **Product → Clean Build Folder** (⇧⌘K)
2. **Product → Build** (⌘B)
3. Delete the InnuirBP app from the iPad (long-press → Remove App)
4. Run the app again from Xcode (⌘R)

### Step 4: Verify Sync

1. Open the app on the iPad
2. Ensure the device has blood pressure data in Apple Health (or add a test reading in the Health app)
3. Tap the **Sync** (↻) button in the Summary screen toolbar
4. When prompted, grant **Read** access to Blood Pressure data
5. The "Last sync" label should update, and readings should appear in the Blood Pressure chart

---

## Troubleshooting

| Symptom | Likely Cause | Action |
|---------|--------------|--------|
| App crashes when tapping Sync | HealthKit not enabled on App ID | Complete Step 1 above |
| "Never synced" never updates | User denied HealthKit access, or no BP data in Health | Check Settings → Health → Data Access; add test data in Health app |
| Sync button spins but no data | No blood pressure data in Apple Health | Add BP readings in the Health app first |
| Provisioning profile errors | App ID and capabilities mismatch | Re-save the App ID in Developer Portal; clean and rebuild |

---

## Files Modified (Reference)

| File | Change |
|------|--------|
| `InnuirBP/Services/iCloudSyncService.swift` | Simplified `makeModelContainer()` |
| `InnuirBP/Services/HealthKitService.swift` | Use completion-handler `requestAuthorization(toShare: nil, read:)`; added pre-flight entitlement check via `InnuirBPIsHealthKitEntitlementAvailable` |
| `InnuirBP/Services/HealthKitAuthHelper.h` | Added `__attribute__((noinline))`; added `InnuirBPIsHealthKitEntitlementAvailable` pre-flight function |
| `InnuirBP/Services/HealthKitAuthHelper.m` | `__attribute__((noinline))` on both functions; pre-flight check; improved error messages |
| `InnuirBP/InnuirBP.entitlements` | Added `com.apple.developer.healthkit`; added `com.apple.developer.healthkit.access = []` (iOS 26) |
| `InnuirBPWidget/InnuirBPWidget.entitlements` | Added `com.apple.security.application-groups` with `group.com.innuir.bp` (widget can read shared data) |
| `InnuirBP/Info.plist` | Added `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription` |
| `InnuirBP/Application/InnuirBPApp.swift` | Removed HealthKit request from app launch `.task` |
| `InnuirBP/Models/ClinicalGuideline.swift` | Removed `assertionFailure`; added `Guidelines` subdirectory fallback |
| `InnuirBP/Views/BPDetailView.swift` | `@StateObject` → `@State` for `BPChartViewModel` (@Observable) |
| `InnuirBP/Views/SummaryView.swift` | `HighlightTilePlaceholder.body` → `bodyText`; added alert to surface sync errors |
| `InnuirBPWidget/BPWidget.swift` | Removed duplicate `BPReadingSnapshot` (use Shared/) |
| `InnuirBP.xcodeproj/project.pbxproj` | Removed Info.plist from Copy Bundle Resources |

---

## Next Steps (Recommendations)

1. **Complete HealthKit setup** using the instructions above so users can sync from Apple Health
2. **Add user-facing error handling** when sync fails (e.g., show an alert with `syncError` instead of failing silently)
3. **Consider re-adding HealthKit request at launch** (optional) once the entitlement is confirmed working, so the permission sheet appears on first open
4. **Verify guideline JSON bundling** on device if chart bands do not appear (check that `InnuirBP/Resources/Guidelines/*.json` are in the app bundle)

---

## Notes for Development Team

### Build Fixes & Conventions (2026-03-15)

**1. Info.plist — Do NOT add to Copy Bundle Resources**

The main app's `Info.plist` is used via the `INFOPLIST_FILE` build setting. Adding it to **Copy Bundle Resources** causes a duplicate output error: *"Multiple commands produce .../Info.plist"*. Remove it from Copy Bundle Resources if present.

**2. @Observable vs @StateObject**

`BPChartViewModel` uses `@Observable` (iOS 17 Observation framework). Use `@State`, not `@StateObject`:

```swift
@State private var viewModel = BPChartViewModel()  // ✓
@StateObject private var viewModel = BPChartViewModel()  // ✗ — requires ObservableObject
```

**3. SwiftUI View property names — Avoid `body`**

Do not name a stored property `body` in a SwiftUI `View` struct. It conflicts with the required `var body: some View`. Use `bodyText`, `content`, or similar:

```swift
struct HighlightTilePlaceholder: View {
    let bodyText: String   // ✓ — not "body"
    var body: some View { ... }
}
```

**4. Shared types — Single definition only**

`BPReadingSnapshot` is defined in `Shared/BPReadingSnapshot.swift` and included in both app and widget targets. Do not redefine it in `BPWidget.swift` or elsewhere — causes "Invalid redeclaration" and "ambiguous for type lookup".

**5. HealthKitService — Use `if` not `guard` for auth flow**

When requesting authorization and then checking success, use `if !isAuthorized` so the block can fall through when authorized. A `guard` body must exit the scope; the inner `guard isAuthorized else { return }` is fine, but the outer must be `if`:

```swift
if !isAuthorized {
    await requestAuthorization()
    guard isAuthorized else { return }
}
```

---

## Contact

For questions about this deployment or the sync fix, refer to the session logs in `docs/communications/` or the ADRs in `docs/decisions/`.
