# HealthKit Sync Hang — Technical Report for Developers and Architects

**Document:** Technical Report  
**Date:** 2026-03-15  
**Status:** Resolved — see [HealthKit-Setup-and-Troubleshooting.md](./HealthKit-Setup-and-Troubleshooting.md) for the definitive guide  
**Targets:** InnuirBP, HealthKitTest

---

## Executive Summary

When the user taps the Sync button in the InnuirBP app, the application became unresponsive due to multiple issues. All issues have been identified and fixed. Sync now works on HealthKitTest. This report documents the architecture, root-cause analysis, and fixes. **For setup and troubleshooting, use [HealthKit-Setup-and-Troubleshooting.md](./HealthKit-Setup-and-Troubleshooting.md).**

---

## 1. Architecture Overview

### 1.1 Sync Flow

```
User taps Sync (SummaryView toolbar)
    → Task { await healthKitService.syncFromHealthKit(context:) }
    → HealthKitService.syncFromHealthKit (if !isAuthorized)
        → requestAuthorization()
            → HKHealthStore.requestAuthorization(toShare: nil, read: typesToRead, completion:)
        → fetchCorrelations (HKCorrelationQuery)
        → convertToReadings
        → SwiftData insert + save
        → writeWidgetSnapshot
```

### 1.2 Key Components

| Component | Location | Responsibility |
|-----------|----------|----------------|
| `HealthKitService` | `Services/HealthKitService.swift` | Singleton, `@MainActor`, manages auth + fetch + SwiftData insert |
| `SummaryView` | `Views/SummaryView.swift` | Sync button in toolbar; invokes `Task { await syncFromHealthKit }` |
| `HealthKitAuthHelper` (InnuirBP only) | `Services/HealthKitAuthHelper.m` | Obj-C wrapper to catch `NSException` when entitlement is missing |
| `ModelContext` | SwiftData | Provided by `@Environment(\.modelContext)` |

### 1.3 Threading Model

- **HealthKitService** is `@MainActor` — all methods run on the main thread.
- **Sync entry point:** `SummaryView` toolbar button → `Task { await ... }` — the `Task` inherits the main actor context, so the `await` suspends the main thread.
- **HealthKit APIs** use completion handlers that run on background queues (not main).
- **Swift Concurrency:** `withCheckedContinuation` / `withCheckedThrowingContinuation` bridge completion handlers to `async/await`.

---

## 2. Observed Behaviour

### 2.1 Symptoms

- **UI:** App freezes; Sync button shows spinner indefinitely.
- **Debugger:** Main thread blocked in `requestAuthorization` / `withCheckedContinuation`.
- **Metrics:** CPU 0%, Memory ~32 MB, Energy Impact High.
- **Call stack (from Xcode):** `HKHealthStore requestAuthorizationToShareTypes:readTypes:completion:` → `HealthKitService.requestAuthorization()` → `HealthKitService.syncFromHealthKit(context:)` → `SummaryView.body.getter` (or toolbar closure).

### 2.2 When It Occurs

- On first sync (when `isAuthorized == false`) — authorization is requested.
- The HealthKit permission sheet may or may not appear before the hang.

---

## 3. Root-Cause Analysis

### 3.1 Deadlock (Fixed)

**Original bug:** The HealthKit completion handler ran on a background queue. The code used:

```swift
Task { @MainActor in
    // ... update state ...
    continuation.resume()
}
```

The main thread was suspended in `withCheckedContinuation` waiting for `resume()`. The `Task { @MainActor in }` scheduled the resume on the main actor. The main actor could not run that task because it was blocked. **Result: deadlock.**

**Fix applied:** Resume the continuation directly from the HealthKit completion block (no `Task { @MainActor in }`), return `(success, error)`, and update `syncError` / `isAuthorized` on the main actor after the `await` returns.

**Status:** Fix applied to both InnuirBP and HealthKitTest. If sync still hangs, this was either insufficient or a different issue.

### 3.2 Possible Remaining Causes

| Hypothesis | Description | How to Verify |
|------------|-------------|---------------|
| **HealthKit completion never fires** | `requestAuthorization` presents a sheet; if the sheet cannot be shown (simulator, entitlements, view hierarchy), the completion may never be called. | Run on physical device with Health app; check entitlements and provisioning. |
| **Main-thread requirement** | Apple docs: "Call this method from your app's main thread." We are `@MainActor`, so the *call* is on main. The `await` suspends; when we resume, we are still on main. | Confirm no other code path calls from a background context. |
| **HKCorrelationQuery hang** | If auth succeeds but `fetchCorrelations` never completes, the app would hang later. | Add logging before/after `fetchCorrelations` to see if we reach it. |
| **ModelContext / SwiftData** | `ModelContext` is main-actor bound. Long-running fetches in the sync loop could block. | Profile with Instruments; check for main-thread work in `context.fetch`. |
| **Provisioning / entitlements** | Missing or incorrect HealthKit entitlement can cause `NSException` (caught by Obj-C helper) or undefined behaviour. | Verify manual profile "InnuirBP HealthKit Dev" is used; confirm HealthKit capability in entitlements. |

---

## 4. Code Reference

### 4.1 Sync Entry Point

```swift
// SummaryView.swift (toolbar)
Button {
    Task {
        await healthKitService.syncFromHealthKit(context: modelContext)
        if healthKitService.syncError != nil {
            showSyncError = true
        }
    }
} label: { ... }
```

### 4.2 requestAuthorization (Post-Fix)

```swift
// HealthKitService.swift
let (success, error) = await withCheckedContinuation { continuation in
    store.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
        continuation.resume(returning: (success, error))  // Direct resume, no Task
    }
}
if let error { syncError = error; isAuthorized = false }
else { isAuthorized = success }
```

### 4.3 fetchCorrelations

```swift
try await withCheckedThrowingContinuation { continuation in
    let query = HKCorrelationQuery(...) { _, correlations, error in
        if let error { continuation.resume(throwing: error) }
        else { continuation.resume(returning: correlations ?? []) }
    }
    store.execute(query)
}
```

---

## 5. Recommendations

### 5.1 Immediate Diagnostics

1. **Add logging** at each stage:
   - Before `requestAuthorization`
   - After `requestAuthorization` (success/error)
   - Before/after `fetchCorrelations`
   - Before/after `context.save`

2. **Run on a physical device** with the Health app and a valid HealthKit provisioning profile.

3. **Confirm provisioning:** Use the manual profile "InnuirBP HealthKit Dev" that includes the HealthKit entitlement.

### 5.2 Architectural Improvements

1. **Offload sync from MainActor:** Move `syncFromHealthKit` (or at least the HealthKit fetch + SwiftData work) to a background actor or `Task.detached`, and only update `@Published` state on the main actor. This prevents any long-running work from blocking the UI.

2. **Separate auth from sync:** Request authorization at app launch (e.g. in `.task` on the root view) so the permission sheet appears before the user taps Sync. The Sync button would then only trigger the fetch, reducing complexity at tap time.

3. **Timeout for authorization:** Wrap `requestAuthorization` in a `Task` with a timeout (e.g. 30 seconds); if the completion never fires, resume with an error to avoid indefinite hang.

### 5.3 Testing

- **HealthKitTest** project: Minimal repro with direct Swift API (no Obj-C wrapper). Use it to isolate whether the issue is InnuirBP-specific (e.g. Obj-C helper, SwiftData, view hierarchy) or HealthKit/system-level.

---

## 6. File Manifest

| File | Purpose |
|------|---------|
| `InnuirBP/Services/HealthKitService.swift` | Main app HealthKit service (uses Obj-C helper) |
| `InnuirBP/Services/HealthKitAuthHelper.m` | NSException catcher for missing entitlement |
| `HealthKitTest/HealthKitTest/Services/HealthKitService.swift` | Test app service (direct Swift API) |
| `InnuirBP/Views/SummaryView.swift` | Sync button and entry point |
| `HealthKitTest/HealthKitTest/Views/SummaryView.swift` | Same for test app |

---

## 7. Applied Fixes (Post-Report)

### 7.1 Continuation Timeout Gates

**Problem:** If HealthKit's completion handler never fires (e.g. permission sheet cannot present on iPad, system drops the callback), `withCheckedContinuation` waits forever, freezing the sync flow.

**Fix:** Introduced `ContinuationGate<T>` and `ThrowingContinuationGate<T>` — thread-safe wrappers that ensure a continuation is resumed **exactly once**. Both `requestAuthorization()` and `fetchCorrelations()` now race the HealthKit completion against a 30-second `DispatchQueue.global().asyncAfter` timeout. The first to fire wins; the second is a no-op.

```swift
let gate = ContinuationGate(continuation)

InnuirBPRequestHealthKitAuthorization(store, typesToRead) { success, error in
    gate.resume(returning: (success, error))
}

DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
    gate.resume(returning: (false, timeoutError))
}
```

**Files changed:** `InnuirBP/Services/HealthKitService.swift`, `HealthKitTest/Services/HealthKitService.swift`

### 7.2 Authorization at Launch

**Problem:** Authorization was only requested when the user tapped Sync. If the HealthKit permission sheet needed to present, it competed with the sync flow and could fail silently on iPad.

**Fix:** Added `.task { await healthKitService.requestAuthorization() }` to `AppNavigation` (root view). The permission sheet now presents at launch when the view hierarchy is fully established, before the user taps anything.

**Files changed:** `InnuirBP/Application/AppNavigation.swift`, `HealthKitTest/Application/AppNavigation.swift`

### 7.3 Diagnostic Logging

Added `os.log` (`Logger`) at every stage of the sync pipeline:
- Before/after `requestAuthorization`
- HealthKit completion handler fire
- Timeout triggers
- Before/after `fetchCorrelations`
- Correlation count and new reading count
- Errors

Log subsystem: `com.innuir.bp`, category: `HealthKitSync`. View in Console.app with filter: `subsystem:com.innuir.bp`.

**Files changed:** `InnuirBP/Services/HealthKitService.swift`, `HealthKitTest/Services/HealthKitService.swift`

---

## 8. Additional Fixes (Final Resolution)

### 8.1 Blood Pressure: Quantity Types Only

**Problem:** Error "Authorization to read the following types is disallowed: HKCorrelationTypeIdentifierBlood-Pressure" — the correlation type triggered a disallowed error even with correct provisioning.

**Fix:** Request only `HKQuantityType(.bloodPressureSystolic)` and `HKQuantityType(.bloodPressureDiastolic)` in `requestAuthorization`. Use `HKCorrelationQuery` for fetching (no auth needed for query).

### 8.2 Defer Auth from Launch

**Problem:** Calling `requestAuthorization` in `.task` at launch caused immediate crash when entitlement was missing.

**Fix:** Removed launch-time auth. User taps Sync to trigger auth. App launches safely.

### 8.3 Obj-C Wrapper in HealthKitTest

**Problem:** HealthKitTest used direct Swift API; when profile lacked entitlement, app crashed.

**Fix:** Added `HealthKitAuthHelper.m` to HealthKitTest (same as InnuirBP). Catches NSException, shows error instead of crash.

---

## 9. Revision History

| Date | Change |
|------|--------|
| 2026-03-15 | Initial report; documented deadlock fix and remaining hypotheses |
| 2026-03-15 | Applied timeout gates, launch-time auth, and diagnostic logging (both projects) |
| 2026-03-15 | Resolved: quantity types only, defer auth, Obj-C wrapper in HealthKitTest. Created [HealthKit-Setup-and-Troubleshooting.md](./HealthKit-Setup-and-Troubleshooting.md) |
