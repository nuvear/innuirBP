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

### 2. HealthKit authorization crash (app launch)

**Problem:** `requestAuthorization(toShare:read:)` threw `_throwIfAuthorizationDisallowedForSharing` because the app lacked the HealthKit entitlement in its provisioning profile.

**Fixes:**
- Added `com.apple.developer.healthkit` entitlement to `InnuirBP.entitlements`
- **Deferred** HealthKit authorization from app launch to first Sync tap (in `SummaryView` toolbar). This allows the app to launch even if the provisioning profile does not yet include HealthKit.

**Files:** `InnuirBP/InnuirBP.entitlements`, `InnuirBP/Application/InnuirBPApp.swift`

---

### 3. GuidelineLoader crash (Blood Pressure tile)

**Problem:** `assertionFailure` when guideline JSON files failed to load (e.g., different bundle structure on device).

**Fix:** Removed `assertionFailure`; added fallback to load from `Guidelines` subdirectory. Returns `nil` gracefully so the chart still renders without guideline bands.

**File:** `InnuirBP/Models/ClinicalGuideline.swift`

---

## Data Sync Issue — Root Cause

HealthKit sync is triggered when the user taps the **Sync** (↻) button in the Summary screen toolbar. The flow is:

1. `HealthKitService.syncFromHealthKit(context:)` is called
2. If not authorized, it calls `requestAuthorization()`
3. `HKHealthStore.requestAuthorization(toShare:read:)` validates the request
4. **If the App ID does not have HealthKit enabled**, HealthKit throws an exception and the app crashes (or authorization fails silently)

The entitlements file contains `com.apple.developer.healthkit`, but the **provisioning profile** used to sign the app must be generated from an App ID that has HealthKit enabled. This is configured in Apple Developer Portal, not in the project files alone.

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
| `InnuirBP/InnuirBP.entitlements` | Added `com.apple.developer.healthkit` |
| `InnuirBP/Application/InnuirBPApp.swift` | Removed HealthKit request from app launch `.task` |
| `InnuirBP/Models/ClinicalGuideline.swift` | Removed `assertionFailure`; added `Guidelines` subdirectory fallback |

---

## Next Steps (Recommendations)

1. **Complete HealthKit setup** using the instructions above so users can sync from Apple Health
2. **Add user-facing error handling** when sync fails (e.g., show an alert with `syncError` instead of failing silently)
3. **Consider re-adding HealthKit request at launch** (optional) once the entitlement is confirmed working, so the permission sheet appears on first open
4. **Verify guideline JSON bundling** on device if chart bands do not appear (check that `InnuirBP/Resources/Guidelines/*.json` are in the app bundle)

---

## Contact

For questions about this deployment or the sync fix, refer to the session logs in `docs/communications/` or the ADRs in `docs/decisions/`.
