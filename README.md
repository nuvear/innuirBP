# InnuirBP — Blood Pressure Chart Widget

A native SwiftUI + Swift Charts application for the Innuir Health Intelligence platform.
Replicates the Apple Health Blood Pressure chart experience with Innuir-specific extensions:
AHA/ESC guideline toggle, manual data entry, HealthKit sync, and iCloud sync across Apple devices.

---

## Quick Start

```bash
cd innuirBP
xcodegen generate
open InnuirBP.xcodeproj
```

**New engineers:** Read [ONBOARDING.md](ONBOARDING.md) for full setup. Use the **InnuirBP HealthKit Dev** manual provisioning profile for HealthKit sync.

---

## Targets

| Target | Description | Min OS |
|---|---|---|
| `InnuirBP` | Main app (iPhone, iPad) | iOS 17+ |
| `InnuirBPWidget` | WidgetKit extension (Home Screen, Lock Screen) | iOS 17+ |

---

## Project Structure

```
innuirBP/
├── project.yml              # XcodeGen — run "xcodegen generate" after edits
├── InnuirBP.xcodeproj
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
│   │   ├── HealthKitService.swift     # HealthKit auth + sync + timeout gates
│   │   ├── HealthKitAuthHelper.h/m    # Obj-C NSException catcher (required)
│   │   └── iCloudSyncService.swift    # SwiftData ModelContainer
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

## Setup

The project uses **XcodeGen**. Generate the Xcode project from `project.yml`:

```bash
xcodegen generate
open InnuirBP.xcodeproj
```

**Provisioning:** Use the **InnuirBP HealthKit Dev** manual provisioning profile for the InnuirBP target. Automatic signing often omits HealthKit. See [ONBOARDING.md](ONBOARDING.md) for details.

**Documentation:**
- [ONBOARDING.md](ONBOARDING.md) — Full setup for new engineers
- [CHANGELOG.md](CHANGELOG.md) — Project history and changes
- [docs/technical/HealthKit-Setup-and-Troubleshooting.md](docs/technical/HealthKit-Setup-and-Troubleshooting.md) — HealthKit configuration

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
