# InnuirBP — Blood Pressure Chart Widget

A native SwiftUI + Swift Charts application for the Innuir Health Intelligence platform.
Replicates the Apple Health Blood Pressure chart experience with Innuir-specific extensions:
AHA/ESC guideline toggle, manual data entry, and iCloud sync across all Apple devices.

---

## Targets

| Target | Description | Min OS |
|---|---|---|
| `InnuirBP` | Main app (iPhone, iPad, Mac Catalyst) | iOS 17+ / macOS 14+ |
| `InnuirBPWidget` | WidgetKit extension (Home Screen, Lock Screen) | iOS 17+ |

---

## Project Structure

```
InnuirBP/
├── InnuirBP/
│   ├── Application/
│   │   ├── InnuirBPApp.swift          # @main entry point, ModelContainer, HealthKitService injection
│   │   └── AppNavigation.swift        # NavigationSplitView (iPad) / NavigationStack (iPhone)
│   │
│   ├── Models/
│   │   ├── BPReading.swift            # SwiftData @Model — core blood pressure reading
│   │   └── ClinicalGuideline.swift    # Decodable structs for AHA/ESC JSON guidelines
│   │
│   ├── Services/
│   │   ├── HealthKitService.swift     # HealthKit authorization + HKCorrelation fetch
│   │   └── iCloudSyncService.swift    # SwiftData ModelContainer with CloudKit configuration
│   │
│   ├── ViewModels/
│   │   └── BPChartViewModel.swift     # @Observable — data aggregation, range/guideline state
│   │
│   ├── Views/
│   │   ├── SummaryView.swift          # Summary screen (profile, pinned tile, highlights)
│   │   ├── BPDetailView.swift         # BP chart screen (chart + log + stage bar)
│   │   └── ManualEntryView.swift      # Manual entry modal with custom numpad
│   │
│   ├── Components/
│   │   ├── BPChartView.swift          # Swift Charts BP chart component
│   │   ├── BPLogCalendarView.swift    # Blood Pressure Log calendar grid
│   │   └── SegmentedControl.swift     # Custom Apple HIG segmented control
│   │
│   └── Resources/
│       ├── aha_hypertension.json      # AHA 2017 guideline stages and thresholds
│       └── esc_hypertension.json      # ESC/ESH 2018 guideline stages and thresholds
│
└── InnuirBPWidget/
    └── BPWidget.swift                 # All widget families (small/medium/large/accessory)
```

---

## Setup in Xcode

### 1. Create the Xcode Project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Product Name: `InnuirBP`
4. Bundle ID: `com.innuir.bp`
5. Interface: **SwiftUI**, Language: **Swift**, Storage: **SwiftData**
6. Check **Include Tests**

### 2. Add the Widget Extension

1. **File → New → Target → Widget Extension**
2. Product Name: `InnuirBPWidget`
3. Uncheck "Include Configuration Intent" (we use StaticConfiguration)

### 3. Configure Capabilities

For the **InnuirBP** target, enable:
- **HealthKit** — required for reading BP data from Apple Health
- **iCloud** (CloudKit) — required for cross-device sync
- **App Groups** — `group.com.innuir.bp` — required for widget data sharing

For the **InnuirBPWidget** target, enable:
- **App Groups** — `group.com.innuir.bp`

### 4. Add Resource Files

Copy `aha_hypertension.json` and `esc_hypertension.json` into the `InnuirBP` target's **Resources** folder.

### 5. Add Swift Files

Copy each `.swift` file from this repository into the corresponding folder in your Xcode project,
ensuring each file is added to the correct target membership.

---

## Key Architecture Decisions

### Data Flow

```
Apple Health (HealthKit)
        │
        ▼ HKCorrelation (systolic + diastolic HKQuantitySample)
HealthKitService.syncFromHealthKit()
        │
        ▼ BPReading (SwiftData @Model, source: .healthKit)
SwiftData ModelContainer (on-device SQLite)
        │
        ├──▶ CloudKit (user's private iCloud) — cross-device sync
        │
        └──▶ BPChartViewModel — aggregation, range, guideline state
                    │
                    ▼
             BPChartView (Swift Charts)
             BPLogCalendarView
             SummaryView → BPPinnedTile
```

### Manual Entry

Manual readings (`source: .manual`) are stored in the same SwiftData store as HealthKit readings.
They are **never written back to HealthKit**. On display, manual readings are shown alongside
HealthKit readings and are visually distinguished by a pencil indicator (Phase 2 feature).

### iCloud Sync

The SwiftData `ModelContainer` is configured with a `CloudKitDatabase` pointing to the user's
**private** CloudKit container (`iCloud.com.innuir.bp`). No data is stored on Innuir servers.
All sync is peer-to-peer between the user's own Apple devices.

### Widget Data Sharing

The widget extension cannot access the SwiftData store directly. The main app writes a JSON
snapshot of the latest 30 readings to `UserDefaults(suiteName: "group.com.innuir.bp")` after
every HealthKit sync and manual entry. The widget reads from this shared defaults store.

---

## Clinical Guidelines

Guidelines are loaded at runtime from JSON files bundled in the app:

| File | Standard | Stages |
|---|---|---|
| `aha_hypertension.json` | AHA 2017 | Normal, Elevated, Stage 1, Stage 2, Crisis |
| `esc_hypertension.json` | ESC/ESH 2018 | Optimal, Normal, High Normal, Grade 1, 2, 3 |

The `ClinicalGuidelineDocument` struct decodes both files identically.
`BPChartViewModel.selectedGuideline` controls which document is active.

---

## Minimum Requirements

| Requirement | Value |
|---|---|
| Xcode | 16.0+ |
| Swift | 5.10+ |
| iOS Deployment Target | 17.0 |
| macOS Deployment Target | 14.0 (Sonoma) |
| Swift Charts | Built-in (no package dependency) |
| SwiftData | Built-in (no package dependency) |
| WidgetKit | Built-in (no package dependency) |

---

## Roadmap

| Phase | Features |
|---|---|
| **Phase 1** (current) | HealthKit read, manual entry, Swift Charts BP chart, iCloud sync, WidgetKit |
| **Phase 2** | Manual entry visual distinction, reading edit/delete, export to PDF |
| **Phase 3** | T-LICC context tagging, time-of-day pattern analysis, trend insights |
| **Phase 4** | On-device AI insight generation (Apple Intelligence / Core ML) |
