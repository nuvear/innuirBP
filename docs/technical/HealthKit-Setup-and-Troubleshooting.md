# HealthKit Setup and Troubleshooting Guide

**Document:** Reference Guide  
**Date:** 2026-03-15  
**Status:** Resolved — sync working on InnuirBP  
**Targets:** InnuirBP (HealthKitTest was merged and renamed)

---

## 1. Overview

This document captures everything learned from debugging HealthKit sync in InnuirBP. Follow this guide when setting up HealthKit for blood pressure or when troubleshooting sync failures.

---

## 2. Required Configuration

### 2.1 Apple Developer Portal

| Step | Action |
|------|--------|
| **App ID** | Create or edit App ID (e.g. `com.innuir.bp`). Enable **HealthKit** capability. |
| **Provisioning Profile** | Create a **Development** profile for the App ID. Ensure it includes HealthKit. Download and install (double-click `.mobileprovision`). |
| **Profile Name** | Use a descriptive name, e.g. "InnuirBP HealthKit Dev". |

**Note:** Automatic signing often generates profiles *without* HealthKit even when the App ID has it. Use a **manual** provisioning profile that explicitly includes HealthKit.

### 2.2 Xcode Project

| Setting | Value |
|---------|-------|
| **HealthKit capability** | Enable in target → Signing & Capabilities |
| **Provisioning Profile** | Select the manual profile (e.g. "InnuirBP HealthKit Dev"), not "Xcode Managed" |
| **Info.plist** | `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` (required for App Store) |

### 2.3 Entitlements

The entitlements file must include:

```xml
<key>com.apple.developer.healthkit</key>
<true/>
```

For App Groups (widget snapshot):

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.innuir.bp</string>
</array>
```

---

## 3. Critical Code Patterns

### 3.1 Request Only Quantity Types for Blood Pressure

**Problem:** Requesting `HKCorrelationType(.bloodPressure)` in `requestAuthorization` can fail with:

> Authorization to read the following types is disallowed: HKCorrelationTypeIdentifierBlood-Pressure

**Solution:** Request only the **quantity types** (systolic and diastolic). The correlation type is used for querying, not for authorization.

```swift
// ✅ Correct
let typesToRead: Set<HKObjectType> = [
    HKQuantityType(.bloodPressureSystolic),
    HKQuantityType(.bloodPressureDiastolic)
]

// ❌ Wrong — can trigger "disallowed" error
let typesToRead: Set<HKObjectType> = [
    HKCorrelationType(.bloodPressure),  // Do NOT include
    HKQuantityType(.bloodPressureSystolic),
    HKQuantityType(.bloodPressureDiastolic)
]
```

### 3.2 Use Obj-C Wrapper to Catch NSException

**Problem:** When the provisioning profile lacks the HealthKit entitlement, HealthKit throws `NSException`. Swift's `do/catch` cannot catch `NSException` → app crashes.

**Solution:** Wrap `requestAuthorization` in an Objective-C `@try/@catch` block. Expose a C function to Swift via a bridging header.

```objc
// HealthKitAuthHelper.m
__attribute__((noinline))
void InnuirBPRequestHealthKitAuthorization(HKHealthStore *store,
                                          NSSet<HKObjectType *> *typesToRead,
                                          void (^completion)(BOOL, NSError *)) {
    @try {
        [store requestAuthorizationToShareTypes:nil readTypes:typesToRead completion:completion];
    } @catch (NSException *exception) {
        if (completion) completion(NO, /* NSError from exception */);
    }
}
```

**Critical:** Use `__attribute__((noinline))` so LTO does not inline the function into Swift and discard the exception tables.

### 3.3 Resume Continuation Directly (No MainActor Hop)

**Problem:** Deadlock when the HealthKit completion runs on a background queue and the code does:

```swift
Task { @MainActor in
    continuation.resume()  // Scheduled on main
}
```

The main thread is suspended waiting for `resume()`, but `resume` is scheduled on main → deadlock.

**Solution:** Resume the continuation directly from the HealthKit completion block (which runs on a background thread). Update `@Published` state after the `await` returns (caller is already on `@MainActor`).

```swift
let (success, error) = await withCheckedContinuation { continuation in
    InnuirBPRequestHealthKitAuthorization(store, typesToRead) { success, error in
        continuation.resume(returning: (success, error))  // Direct, no Task
    }
}
// Update state here — we're on MainActor
if let error { syncError = error; isAuthorized = false }
else { isAuthorized = success }
```

### 3.4 Defer Authorization from Launch (Optional)

**Problem:** Calling `requestAuthorization` in `.task` at app launch can crash if the entitlement is missing (before the Obj-C wrapper catches it) or if the view hierarchy isn't ready.

**Solution:** Defer auth to when the user taps Sync. The app launches safely; auth runs when the user explicitly triggers sync.

```swift
// AppNavigation — do NOT call requestAuthorization in .task at launch
// Let the user tap Sync to trigger it
```

### 3.5 Timeout Gates for Continuations

**Problem:** If HealthKit's completion handler never fires (e.g. system drops the callback), `withCheckedContinuation` waits forever.

**Solution:** Race the HealthKit completion against a 30-second timeout. Use a thread-safe gate that ensures the continuation is resumed exactly once.

```swift
let gate = ContinuationGate(continuation)

InnuirBPRequestHealthKitAuthorization(store, typesToRead) { success, error in
    gate.resume(returning: (success, error))
}

DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
    gate.resume(returning: (false, timeoutError))
}
```

---

## 4. Error Messages and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| **App crashes on Sync** | HealthKit throws `NSException` (missing entitlement) | Add Obj-C `HealthKitAuthHelper` with `@try/@catch` |
| **"Authorization to read... is disallowed: HKCorrelationTypeIdentifierBlood-Pressure"** | Correlation type in `requestAuthorization` | Request only `bloodPressureSystolic` and `bloodPressureDiastolic` |
| **"Sync Failed" with generic message** | Provisioning profile lacks HealthKit | Use manual profile "InnuirBP HealthKit Dev"; download from Developer Portal |
| **App hangs on Sync** | Deadlock (continuation resume on MainActor) | Resume continuation directly from HealthKit completion block |
| **App hangs indefinitely** | HealthKit completion never fires | Add 30-second timeout gate |
| **App crashes at launch** | `requestAuthorization` in `.task` with bad entitlement | Defer auth to Sync tap |

---

## 5. Verification Checklist

Before release or when onboarding a new developer:

- [ ] App ID in Developer Portal has HealthKit enabled
- [ ] Manual provisioning profile includes HealthKit and is downloaded
- [ ] Xcode target uses the manual profile (not automatic)
- [ ] Entitlements file has `com.apple.developer.healthkit`
- [ ] Info.plist has `NSHealthShareUsageDescription`
- [ ] `requestAuthorization` requests only quantity types (systolic, diastolic) for blood pressure
- [ ] Obj-C `HealthKitAuthHelper` wraps HealthKit call
- [ ] Continuation is resumed directly (no `Task { @MainActor in }`)
- [ ] Timeout gate (30s) prevents indefinite hang

---

## 6. Health App Integration

When sync works correctly:

- The app appears under **Settings → Health → Data Access & Devices → Apps**
- User can grant or revoke access per data type
- If the app disappears from the list (e.g. after reinstall), tap **Sync** to trigger `requestAuthorization` again and re-add it

---

## 7. File Reference

| File | Purpose |
|------|---------|
| `HealthKitService.swift` | Auth, fetch, SwiftData insert, timeout gates |
| `HealthKitAuthHelper.m` / `.h` | Obj-C NSException catcher |
| `*-Bridging-Header.h` | Exposes Obj-C to Swift |
| `*.entitlements` | HealthKit, App Groups |
| `Info.plist` | NSHealthShareUsageDescription, NSHealthUpdateUsageDescription |

---

## 8. Related Documents

- [HealthKit-Sync-Hang-Report.md](./HealthKit-Sync-Hang-Report.md) — Original technical report and architecture

---

## 9. Revision History

| Date | Change |
|------|--------|
| 2026-03-15 | Initial guide; documented all fixes and patterns from sync debugging |
