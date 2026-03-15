# Manus Change Log — InnuirBP Project

**Document:** Change Log  
**Date:** 2026-03-15  
**Author:** Manus AI

---

## 1. Overview

This document provides a comprehensive, reverse-chronological log of every significant change made by Manus AI to the InnuirBP Swift project. It covers feature implementation, bug fixes, documentation, and project restructuring. Each entry includes the commit hash, date, a summary of the changes, and a list of the files affected.

---

## 2. Change History

### 2.1 2026-03-15: Minor Restorations

- **Commit:** `89a9e6d`
- **Date:** 2026-03-15 16:39

Restored three minor items from the archived `InnuirBP-retired` project to align the current codebase with the original design intent and best practices.

| Change | Description |
| :--- | :--- |
| **Polished Usage Strings** | Restored the original, more descriptive HealthKit usage strings in `Info.plist` for `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription`. These are clearer for users and better for App Store review. |
| **Widget Settings** | Added `INFOPLIST_KEY_CFBundleDisplayName: "Blood Pressure"` and `SKIP_INSTALL: YES` to the widget target in `project.yml`. This ensures the widget has the correct name on the Home Screen and follows best practices for app extensions. |
| **Background Modes Note** | Added a commented-out `# UIBackgroundModes: [fetch]` to the main app target in `project.yml` with a note to uncomment it when background HealthKit delivery is implemented. |

**Files Changed:**
- `InnuirBP/Info.plist`
- `project.yml`

### 2.2 2026-03-14: Deployment Engineer Gap Fixes

- **Commit:** `c52649b`
- **Date:** 2026-03-14 12:25

Addressed five specific gaps identified by the deployment engineer after their initial review. This commit fixed data model mismatches, widget data sharing, a Mac Catalyst UI issue, a SwiftData context bug, and calendar navigation.

| Gap | Fix |
| :-- | :-- |
| **1. JSON/Model Mismatch** | Rewrote `aha_hypertension.json` and `esc_hypertension.json` to match the `ClinicalGuidelineDocument` Swift model, fixing a decoding crash. |
| **2. Widget Data Sharing** | Added `writeWidgetSnapshot(from:)` to `HealthKitService` to write the 30 most recent readings to App Group UserDefaults after sync and manual entry, ensuring the widget stays current. |
| **3. Mac Catalyst Numpad** | Wrapped the custom `BPNumericKeypad` in `ManualEntryView.swift` with `#if !targetEnvironment(macCatalyst)` to prevent it from appearing on macOS. |
| **4. SummaryView Sync Context** | Fixed the Sync button in `SummaryView.swift` to use the shared `@Environment(\.modelContext)` instead of creating a new, isolated `ModelContainer` on each tap. |
| **5. Calendar Navigation** | Wired up the chevron buttons in `BPLogCalendarView.swift` to correctly increment and decrement the `displayedMonth`. |

**Files Changed:**
- `InnuirBP/Components/BPLogCalendarView.swift`
- `InnuirBP/Resources/Guidelines/aha_hypertension.json`
- `InnuirBP/Resources/Guidelines/esc_hypertension.json`
- `InnuirBP/Services/HealthKitService.swift`
- `InnuirBP/Views/ManualEntryView.swift`
- `InnuirBP/Views/SummaryView.swift`

### 2.3 2026-03-14: HealthKit Crash Fixes

Two commits were required to diagnose and fully resolve a crash when tapping the Sync button.

#### 2.3.1 The Definitive Fix

- **Commit:** `dbc45fe`
- **Date:** 2026-03-14 19:01

This commit addressed the two true root causes of the crash.

| Cause | Fix |
| :--- | :--- |
| **Wrong API Overload** | Switched from the `async/await` `requestAuthorization` overload (which does not accept `nil` for `toShare`) to the completion-handler overload (which does), bridged back to `async/await` with `withCheckedContinuation`. |
| **Missing `Info.plist`** | Added `InnuirBP/Info.plist` to the project with the required `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` keys. The file was missing from the repository entirely. |

**Files Changed:**
- `InnuirBP/Info.plist`
- `InnuirBP/Services/HealthKitService.swift`

#### 2.3.2 The Initial Attempt

- **Commit:** `0d7dfb5`
- **Date:** 2026-03-14 18:48

This was the first attempt to fix the crash, based on the initial diagnosis that passing an empty `Set` to `toShare` was the issue. While the theory was correct, the fix was applied to the wrong API overload.

**Files Changed:**
- `InnuirBP/Services/HealthKitService.swift`

### 2.4 2026-03-14: Documentation and Initial Project Build

Two commits established the initial project structure, documentation, and the full v1.0 Swift codebase.

#### 2.4.1 Documentation Suite

- **Commit:** `46b625f`
- **Date:** 2026-03-14 12:14

Created a comprehensive suite of documentation covering design decisions, technical specifications, and guides for future engineers.

**Files Added:**
- `DEPLOYMENT_GUIDE.md`
- `docs/README.md`
- `docs/communications/` (session logs)
- `docs/decisions/` (ADRs for Swift Charts, SwiftData, Mac Catalyst)
- `docs/design/` (iPad design analysis)
- `docs/specs/` (guideline JSON, chart spec, project blueprint)

#### 2.4.2 Initial Project Commit

- **Commit:** `8e137db`
- **Date:** 2026-03-14 11:56

This was the first commit, containing the entire initial build of the InnuirBP application and widget, based on the design specifications and analysis.

**Files Added:**
- All Swift source files for the main app (`InnuirBP/`)
- All Swift source files for the widget extension (`InnuirBPWidget/`)
- `.gitignore`
- `README.md`

---

## 3. Unlogged Commits

The following commits were made by the deployment team and are included here for completeness.

| Commit | Date | Summary |
| :--- | :--- | :--- |
| `21830a9` | 2026-03-15 20:53 | HealthKit sync fixes, project restructure, onboarding docs |
| `4dea785` | 2026-03-15 08:04 | docs: add HealthKit root causes and What to Do Now to deployment guide |
| `253448e` | 2026-03-15 07:28 | docs: add iPad deployment status and HealthKit sync fix instructions |
| `b011af5` | 2026-03-14 12:26 | docs: add gap-fixes response document for deployment engineer |
