# HealthKit Sync — Troubleshooting (Same Error After Enabling)

**Date:** 2026-03-15  
**Issue:** "Sync Failed" persists after enabling HealthKit on App ID in Developer Portal

---

## Code Change Applied

**Pre-flight check bypassed** — The `InnuirBPIsHealthKitEntitlementAvailable` check was failing even when the entitlement might be correct (e.g. profile propagation delay). The flow now goes straight to `requestAuthorization`. If the entitlement is present, the permission sheet will appear. If not, the Obj-C wrapper catches the exception.

**File:** `HealthKitService.swift`

---

## Verification Checklist

### 1. Bundle ID Must Match Exactly

The App ID in Developer Portal must be **`com.innuir.bp`** (lowercase `bp`).

- ✅ Correct: `com.innuir.bp`
- ❌ Wrong: `com.innuir.BP` (capital BP)

Bundle IDs are case-sensitive. If they differ, Xcode uses a different provisioning profile.

### 2. Provisioning Profile Propagation

After enabling HealthKit and saving the App ID, profile updates can take **5–15 minutes**. Then:

1. **Xcode → Settings → Accounts** → select your Apple ID
2. Click **Download Manual Profiles**
3. Wait for the download to complete

### 3. Force Fresh Build

1. **Product → Clean Build Folder** (⇧⌘K)
2. Delete the InnuirBP app from the iPad (long-press → Remove App)
3. **Product → Run** (⌘R)

### 4. Check Signing in Xcode

1. Select the **InnuirBP** target
2. **Signing & Capabilities** tab
3. Verify **HealthKit** appears in the capabilities list
4. Note the **Provisioning Profile** name — it should reference your team and `com.innuir.bp`

### 5. Manual Signing (If Automatic Fails)

If automatic signing still uses an old profile:

1. In **Signing & Capabilities**, uncheck **Automatically manage signing**
2. In Developer Portal: **Profiles** → create a new **iOS App Development** profile for `com.innuir.bp`
3. Download the profile and double-click to install
4. In Xcode, select this profile for the InnuirBP target

---

## Expected Result After Fix

When you tap **Sync**:

- **Success:** HealthKit permission sheet appears → grant access → readings import
- **Still failing:** "Sync Failed" alert — profile likely still missing HealthKit; try manual signing (step 5)
