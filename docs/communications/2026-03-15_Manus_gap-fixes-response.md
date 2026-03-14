# InnuirBP — Gap Fixes Response

**Date:** 2026-03-15  
**Author:** Manus AI  
**Commit:** `c52649b` — `fix: address 5 deployment engineer gaps`  
**Branch:** `main` → [github.com/nuvear/innuirBP](https://github.com/nuvear/innuirBP)

---

All five gaps identified in the deployment engineer's review have been resolved. The changes are contained in a single commit (`c52649b`) pushed to `main`. Below is a precise account of what was changed and why.

---

## Gap 1 — Guideline JSON/Model Mismatch

**Files changed:** `InnuirBP/Resources/Guidelines/aha_hypertension.json`, `InnuirBP/Resources/Guidelines/esc_hypertension.json`

**Root cause.** The JSON files used a dictionary-keyed `stages` object with ad-hoc fields (`thresholds`, `bands`, `labels`). The Swift `ClinicalGuidelineDocument` model expects a top-level `guideline`, `version`, `source`, `description`, an array-typed `stages` (each with `id`, `name`, `shortName`, `systolicMin`, `systolicMax`, `diastolicMin`, `diastolicMax`, `color`, `description`), a `chartBands` array, and a `thresholdLines` array.

**Fix.** Both JSON files were completely rewritten to conform to the model. The AHA file now encodes five stages (Normal, Elevated, Stage 1, Stage 2, Hypertensive Crisis) and four chart bands. The ESC file encodes six stages (Optimal, Normal, High Normal, Grade 1–3) and four chart bands. All `null` thresholds use JSON `null` so the Swift `Double?` optionals decode correctly. `GuidelineLoader` can now decode both files without modification.

---

## Gap 2 — Widget Data Sharing

**Files changed:** `InnuirBP/Services/HealthKitService.swift`, `InnuirBP/Views/ManualEntryView.swift`

**Root cause.** The WidgetKit extension (`BPWidget.swift`) already reads from `UserDefaults(suiteName: "group.com.innuir.bp")` under the key `"bp_readings"`, but nothing in the main app ever wrote to that key. Widgets therefore always showed "No data".

**Fix.** A new public method `writeWidgetSnapshot(from:)` was added to `HealthKitService`:

```swift
func writeWidgetSnapshot(from readings: [BPReading]) {
    let snapshots = readings.prefix(30).map {
        BPReadingSnapshot(systolic: $0.systolic, diastolic: $0.diastolic, timestamp: $0.timestamp)
    }
    guard let data = try? JSONEncoder().encode(Array(snapshots)),
          let defaults = UserDefaults(suiteName: Self.appGroupID) else { return }
    defaults.set(data, forKey: Self.widgetSnapshotKey)
    WidgetCenter.shared.reloadAllTimelines()
}
```

This method is now called in two places:

1. **`syncFromHealthKit`** — after `context.save()` succeeds, all readings are fetched and the snapshot is written.
2. **`ManualEntryView.saveReading()`** — after the manual entry is saved, all readings are fetched and the snapshot is written.

Both paths call `WidgetCenter.shared.reloadAllTimelines()` so the widget refreshes immediately without waiting for its 30-minute polling interval.

---

## Gap 3 — Mac Catalyst Numpad Conditional

**File changed:** `InnuirBP/Views/ManualEntryView.swift`

**Root cause.** ADR-003 explicitly requires `#if !targetEnvironment(macCatalyst)` around the custom numeric keypad, because Mac Catalyst provides a full hardware keyboard and the custom numpad is both unnecessary and visually inappropriate on macOS.

**Fix.** The `BPNumericKeypad` block in `ManualEntryView` is now wrapped:

```swift
#if !targetEnvironment(macCatalyst)
BPNumericKeypad { key in handleKeyInput(key) }
    .padding(.horizontal, 20)
    .padding(.bottom, 20)
#endif
```

On Mac Catalyst the systolic and diastolic fields remain tappable text rows; the system keyboard handles input. The `handleKeyInput` function and `NumpadKey` enum are still compiled on all platforms so the `saveReading` logic is unaffected.

---

## Gap 4 — SummaryView Sync Context

**File changed:** `InnuirBP/Views/SummaryView.swift`

**Root cause.** The sync toolbar button called:

```swift
Task { await healthKitService.syncFromHealthKit(
    context: ModelContext(try! iCloudSyncService.makeModelContainer())
) }
```

This creates a brand-new, isolated `ModelContainer` and `ModelContext` on every button tap. Any readings inserted into that context are invisible to the main app's `@Query` and are never reflected in the UI. It also risks data duplication and crashes if the CloudKit container is unavailable.

**Fix.** `@Environment(\.modelContext) private var modelContext` was added to `SummaryView`. The sync button now passes the environment-provided context:

```swift
Task { await healthKitService.syncFromHealthKit(context: modelContext) }
```

This ensures all inserts happen in the same context that drives the `@Query` on the same view, so the UI updates reactively.

---

## Gap 5 — Calendar Navigation

**File changed:** `InnuirBP/Components/BPLogCalendarView.swift`

**Root cause.** `BPCalendarGrid` had chevron buttons with empty action closures (`// Navigate to previous month (handled by parent)`), but the parent `BPLogSection` never passed any callbacks and `displayedMonth` was never mutated.

**Fix.** Two closure parameters were added to `BPCalendarGrid`:

```swift
let onPreviousMonth: () -> Void
let onNextMonth: () -> Void
```

The chevron buttons now call these closures. `BPLogSection` passes implementations that increment/decrement `displayedMonth` by one month:

```swift
onPreviousMonth: {
    if let prev = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
        displayedMonth = Calendar.current.startOfMonth(for: prev)
    }
},
onNextMonth: {
    if let next = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
        displayedMonth = Calendar.current.startOfMonth(for: next)
    }
}
```

A computed property `isCurrentMonth` was also added to `BPCalendarGrid` to disable the forward chevron when the user is already viewing the current month, preventing navigation into the future.

---

## Testing Checklist for Re-Review

| # | Test | Expected result |
|---|------|----------------|
| 1 | Build the project in Xcode | Zero compile errors; `GuidelineLoader` decodes both JSON files without `assertionFailure` |
| 2 | Toggle AHA ↔ ESC in the chart | Stage bands and threshold lines update correctly from JSON data |
| 3 | Add a manual BP entry | Widget on Home Screen updates within seconds |
| 4 | Tap the sync button on the Summary screen | HealthKit sync completes; no crash; new readings appear in the chart |
| 5 | Build for Mac Catalyst | No numeric keypad visible; system keyboard accepts input in the entry sheet |
| 6 | Tap ‹ chevron in the Blood Pressure Log | Calendar navigates to the previous month |
| 7 | Tap › chevron when on the current month | Button is disabled (greyed out) |

---

*Please log test results in `docs/communications/` using the standard template and flag any regressions.*
