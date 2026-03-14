# ADR-002 — SwiftData + CloudKit for Data Persistence and Sync

**Date:** 14 Mar 2026
**Status:** Accepted
**Deciders:** Rajkumar (Product Owner), Manus AI

---

## Context

The InnuirBP app requires a data persistence strategy that satisfies the following constraints:

1. Data must be stored on-device to protect user privacy.
2. Data must sync seamlessly across the user's Apple devices (iPhone, iPad, Mac).
3. No data must be stored on Innuir servers.
4. Manual entries and HealthKit-sourced readings must coexist in the same store.

---

## Decision

**SwiftData** is used for on-device persistence, configured with a **CloudKit private database** for cross-device sync. No Innuir backend server is involved in data storage or sync.

---

## Rationale

SwiftData (introduced iOS 17) is the modern replacement for Core Data, with a declarative `@Model` macro syntax that integrates naturally with SwiftUI. Configuring the `ModelContainer` with `CloudKitDatabase(.private("iCloud.com.innuir.bp"))` enables automatic, peer-to-peer sync via the user's own private iCloud account — at no cost and with no server infrastructure required from Innuir.

This approach satisfies all four constraints: data is stored locally in a SQLite database managed by SwiftData, it syncs via the user's private iCloud, Innuir servers are never involved, and both `source: .healthKit` and `source: .manual` readings share the same `BPReading` model.

---

## Consequences

- The app requires the **iCloud (CloudKit)** capability to be enabled in Xcode.
- The user must be signed into iCloud on their device for cross-device sync to function. The app must handle the case where iCloud is not available gracefully (local-only mode).
- The `InnuirBPWidget` extension cannot access the SwiftData store directly. A JSON snapshot of recent readings is written to a shared **App Group** UserDefaults container by the main app, and the widget reads from this.
- Manual entries are never written back to HealthKit. They are stored only in the SwiftData store and synced via CloudKit.
