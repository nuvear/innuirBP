# ADR-003 — Mac Catalyst First for iMac Deployment

**Date:** 14 Mar 2026
**Status:** Accepted
**Deciders:** Rajkumar (Product Owner), Manus AI

---

## Context

The InnuirBP app targets iPhone, iPad, and iMac. Two options were considered for the iMac version:

1. **Mac Catalyst** — Enable the Mac Catalyst checkbox in Xcode to run the iPad app as a native macOS app.
2. **Native macOS Target** — Build a separate macOS target with macOS-specific SwiftUI idioms.

---

## Decision

**Mac Catalyst** is the chosen approach for the iMac version in Phase 1.

---

## Rationale

Mac Catalyst allows the iPad app to run as a native `.app` on macOS with minimal code changes. SwiftUI's `NavigationSplitView` automatically adapts to a proper macOS sidebar, sheets become macOS panels, and the chart renders identically. HealthKit, SwiftData, CloudKit, and Swift Charts are all fully supported on macOS 13+.

This approach delivers a working iMac app in under an hour of Xcode configuration, with zero additional Swift code for the chart itself. A full native macOS target would require a separate UI layer and significantly more development time.

---

## Required Code Changes for Mac Catalyst

The following conditional code changes are required:

| File | Change |
|---|---|
| `ManualEntryView.swift` | Wrap the custom numpad in `#if !targetEnvironment(macCatalyst)`. On Mac, use a standard `TextField` with `.keyboardType(.numberPad)` replaced by a plain text field. |
| `Xcode Capabilities` | Add the `com.apple.developer.healthkit` entitlement for the Mac Catalyst target. |

---

## Future Consideration

If a full native macOS experience is required in a future phase (e.g., menu bar integration, macOS-specific toolbar, drag-and-drop), a separate macOS target can be added. All Models, Services, ViewModels, and Components are 100% reusable — only the View layer would need macOS-specific variants.

---

## Consequences

- The deployment engineer must enable Mac Catalyst in Xcode and test on **My Mac** as a separate scheme.
- The `ManualEntryView` must be updated before Mac Catalyst testing to avoid a crash on the numpad keyboard type.
- HealthKit on Mac requires the user to have the Health app installed and data synced from their iPhone.
