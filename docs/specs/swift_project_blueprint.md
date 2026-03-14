# Engineering Blueprint: Innuir BP Chart — Native Swift Project

**Document Version:** 1.0
**Date:** 14 March 2026
**Author:** Manus AI

---

## 1. Xcode Project Structure

The project will be named `InnuirBP` and will contain two primary targets:

| Target Name | Product | Description |
|---|---|---|
| `InnuirBP` | iOS/iPadOS/macOS App | The main application containing the full interactive chart, summary screen, and manual entry UI. |
| `InnuirBPWidgets` | Widget Extension | The companion WidgetKit extension for the Home Screen, Lock Screen, and Mac Desktop. |

## 2. Architectural Pattern

We will use a clean, SwiftUI-idiomatic architecture based on **MVVM (Model-View-ViewModel)**. This pattern provides a clear separation of concerns:

- **Model:** The data layer (SwiftData models, HealthKit data). Represents the app's content.
- **View:** The UI layer (SwiftUI views). Displays the data and captures user input.
- **ViewModel:** The presentation logic layer. Prepares data from the Model for the View and handles user actions.

This structure promotes testability, maintainability, and scalability.

## 3. File & Group Structure

The project will be organized into the following groups:

```
InnuirBP/
├── InnuirBP.xcodeproj
├── InnuirBP/  (Main App Target)
│   ├── Application/
│   │   ├── InnuirBPApp.swift         // Main app entry point
│   │   └── AppState.swift            // Global app state (e.g., navigation)
│   │
│   ├── Models/
│   │   ├── BPReading.swift           // SwiftData model for a single BP reading
│   │   └── ClinicalGuideline.swift   // Structs for AHA/ESC guidelines
│   │
│   ├── Views/
│   │   ├── MainView.swift            // Root view with sidebar navigation
│   │   ├── SummaryView.swift         // Screen 1: Summary with pinned tile
│   │   ├── BPDetailView.swift        // Screen 2: The main BP chart view
│   │   └── ManualEntryView.swift     // Screen 4: The manual entry modal
│   │
│   ├── ViewModels/
│   │   ├── BPChartViewModel.swift    // Logic for the BP chart (data aggregation)
│   │   └── SummaryViewModel.swift    // Logic for the summary screen
│   │
│   ├── Services/
│   │   ├── HealthKitService.swift    // Handles all HealthKit queries
│   │   └── iCloudSyncService.swift   // Manages SwiftData + CloudKit sync
│   │
│   ├── Components/ (Reusable UI)
│   │   ├── BPChartView.swift         // The core Swift Charts component
│   │   ├── SegmentedControl.swift    // Custom segmented control
│   │   └── BPLogCalendarView.swift   // The calendar view for the BP Log
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Guidelines/             // JSON files for AHA/ESC
│   │   │   ├── aha_hypertension.json
│   │   │   └── esc_hypertension.json
│   │   └── PrivacyInfo.xcprivacy
│
└── InnuirBPWidgets/ (Widget Extension Target)
    ├── InnuirBPWidgets.swift         // Main widget entry point
    ├── Provider.swift                // Timeline provider for the widget
    ├── WidgetViews.swift             // SwiftUI views for all widget sizes
    └── InnuirBPWidgetsBundle.swift   // Widget bundle definition
```

## 4. Key Component Responsibilities

### Models
- **`BPReading.swift`**: A `@Model` class for SwiftData. Stores systolic, diastolic, timestamp, and whether the entry was manual or from HealthKit.
- **`ClinicalGuideline.swift`**: Decodable structs that map directly to the `aha_hypertension.json` and `esc_hypertension.json` files.

### Services
- **`HealthKitService.swift`**: A singleton class responsible for requesting authorization and fetching `HKCorrelation` blood pressure data from the HealthKit store.
- **`iCloudSyncService.swift`**: Configures the SwiftData model container for automatic iCloud sync using CloudKit.

### ViewModels
- **`BPChartViewModel.swift`**: An `@Observable` class that fetches `BPReading` objects from SwiftData, aggregates them based on the selected time range (Day, Week, etc.), and provides arrays of data ready for `BPChartView` to render.

### Views
- **`MainView.swift`**: The root view of the app, containing the `NavigationSplitView` for the iPad/macOS sidebar layout.
- **`BPDetailView.swift`**: The main screen containing the chart, stats header, and BP Log calendar. It will observe the `BPChartViewModel`.

### Components
- **`BPChartView.swift`**: The heart of the application. A SwiftUI `View` that takes aggregated data and uses **Swift Charts** (`Chart`, `RuleMark`, `PointMark`, `RectangleMark`) to render the visual specification.

### Widget Extension
- **`Provider.swift`**: Implements the `TimelineProvider` protocol to provide snapshots and timelines for the widget, ensuring it updates periodically.
- **`WidgetViews.swift`**: Contains the SwiftUI views for each widget family (`.accessoryCircular`, `.systemSmall`, `.systemMedium`, etc.).

---

This blueprint provides a robust and scalable foundation for building the native Innuir BP Chart application, ensuring a clean separation of concerns and alignment with modern Swift development practices.
