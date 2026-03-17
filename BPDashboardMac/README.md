# BPDashboardMac

A native macOS application for visualising blood pressure data using **SwiftUI** and **Swift Charts**.

## Overview

BPDashboardMac is a clinical-grade blood pressure dashboard designed for physicians, patients, and caregivers. It implements the evidence-based visualisation principles from Wegier et al. (2021) and Koopman et al. (2025), featuring:

- **Calendar-aligned time-series chart** — ISO week calendar header (Month / Week / Day / DOW) with chart columns aligned pixel-perfectly to calendar day columns
- **All readings per day** — up to 3 individual scatter dots per day (morning, midday, evening) plotted on the chart
- **LOWESS trend lines** — locally weighted smoothing for both systolic and diastolic series, directing clinical attention to the mean trend rather than individual outliers
- **Clinical standard overlays** — toggle between 2017 ACC/AHA, 2018 ESC/ESH, 2019 JSH, and 2020 ISH goal bands
- **Annotation timeline** — clickable markers on the x-axis for lifestyle, exercise, diet, and medication notes
- **Medication timeline** — horizontal bar showing medication name, dose, and duration
- **File-open dialog** — load any `bp_data.json` file for testing different patient datasets

## Requirements

| Requirement | Version |
|---|---|
| macOS | 14.0 Sonoma or later |
| Xcode | 15.0 or later |
| Swift | 5.9 or later |
| Swift Charts | Included in macOS 14 SDK |

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/nuvear/innuirBP.git
   cd innuirBP/BPDashboardMac
   ```

2. Open the Xcode project:
   ```bash
   open BPDashboardMac.xcodeproj
   ```

3. Select the **BPDashboardMac** scheme and run on **My Mac**.

4. Click **"Open BP Data File"** and select `SampleData/bp_data_2026.json` to load the sample dataset.

## JSON Data Format

The app reads a JSON file conforming to the following schema (`schemaVersion: "1.0"`):

```json
{
  "schemaVersion": "1.0",
  "exportDate": "2026-03-17",
  "patient": {
    "id": "patient-001",
    "name": "Demo Patient",
    "dateOfBirth": "1965-03-15",
    "gender": "male",
    "targetSystolic": 130,
    "targetDiastolic": 80
  },
  "readings": [
    {
      "date": "2026-01-01",
      "time": "06:30",
      "session": "morning",
      "systolic": 128,
      "diastolic": 76,
      "pulse": 75
    }
  ],
  "medications": [
    {
      "name": "Amlodipine",
      "dose": "10 mg",
      "frequency": "Once daily",
      "startDate": "2026-01-01",
      "endDate": "2026-12-31",
      "color": "#2563EB",
      "notes": "Calcium channel blocker for hypertension management"
    }
  ],
  "annotations": [
    {
      "date": "2026-01-20",
      "tag": "lifestyle",
      "title": "Earlier morning routine begins",
      "text": "Started waking at 05:50 — earlier morning routine begins.",
      "author": "Self"
    }
  ]
}
```

### Session Values

| Value | Description |
|---|---|
| `morning` | First reading of the day, typically 06:00–07:45 |
| `midday` | Second reading, typically 11:45–13:30 |
| `evening` | Third reading, typically 17:30–21:10 |

### Annotation Tag Values

| Tag | Icon | Colour |
|---|---|---|
| `lifestyle` | 🌅 | Amber |
| `exercise` | 🚶 | Green |
| `diet` | 🥗 | Teal |
| `medication` | 💊 | Blue |
| `stress` | ⚡ | Red |

## Project Structure

```
BPDashboardMac/
├── BPDashboardMac.xcodeproj/
│   └── project.pbxproj
├── BPDashboardMacApp.swift        # App entry point + file-open logic
├── Models/
│   └── BPDataModels.swift         # Codable structs: BPDataDocument, BPReading, Medication, Annotation
├── Services/
│   └── JSONLoader.swift           # JSON parsing service
├── ViewModels/
│   └── (to be added by Cursor)    # DashboardViewModel with LOWESS, filtering, date range
├── Views/
│   ├── DashboardView.swift        # Main layout: toolbar + calendar + chart + timelines
│   ├── BPChartView.swift          # Swift Charts scatter + trend lines + goal bands
│   ├── CalendarHeaderView.swift   # ISO week calendar header (Month/Week/Day/DOW rows)
│   ├── AnnotationTimelineView.swift  # Clickable annotation markers on x-axis
│   ├── MedicationTimelineView.swift  # Horizontal medication duration bars
│   ├── DataTableView.swift        # SYS/DIA/PULSE value rows below calendar
│   └── ToolbarView.swift          # View/Smoothing/Standard controls
└── SampleData/
    └── bp_data_2026.json          # Full-year 2026 sample data (1095 readings)
```

## Collaboration with Cursor

This project is designed for collaborative development with [Cursor](https://cursor.sh/). The following tasks are ready to be implemented:

### Priority 1 — ViewModel
Create `ViewModels/DashboardViewModel.swift` as an `@ObservableObject` that:
- Holds the loaded `BPDataDocument`
- Computes daily averages grouped by date
- Implements LOWESS smoothing (bandwidth = 0.3) for systolic and diastolic trend lines
- Manages `selectedView` (week/month/year), `selectedStandard` (none/accaha/eschesh/jsh/ish), and `showSmoothing` state
- Exposes `visibleDays: [Date]` based on the selected view and scroll position

### Priority 2 — Calendar Alignment
Implement the pixel-perfect calendar alignment in `CalendarHeaderView.swift`:
- Fixed left panel (160pt wide) with row labels: MONTH / WEEK / DAY / DOW
- Scrollable right panel with one column per day (32pt wide)
- Month spans, week spans, day numbers, and DOW abbreviations
- Weekends dimmed (0.4 opacity)
- All scroll panels (calendar, chart, annotation, medication, data table) share a single `ScrollViewReader` or `ScrollView` with `.synchronize` to scroll together

### Priority 3 — Chart Alignment
In `BPChartView.swift`, use a **linear numeric x-axis** (day index 0…364) rather than a Date-based axis to achieve exact column alignment:
- Each data point at day index `i` maps to pixel `i * 32`
- Use a `beforeDraw` plugin equivalent (custom `Canvas` overlay) to draw goal bands and trend lines
- Y-axis drawn in the fixed left panel as an SVG/Canvas, not inside the Chart

### Priority 4 — Annotation Popups
In `AnnotationTimelineView.swift`, implement tap-to-show popups:
- Each annotation marker is a `Button` with an emoji icon
- Tapping shows a `popover` or `overlay` card with: date, title, text, tag badge, and author
- Dismiss on tap-outside or × button

### Priority 5 — Standard Overlays
In `BPChartView.swift`, implement the 4 clinical standard overlays as `RectangleMark` bands:

| Standard | Sys Normal | Sys Elevated | Sys HT1 | Sys HT2 | Dia Normal | Dia HT1 | Dia HT2 |
|---|---|---|---|---|---|---|---|
| ACC/AHA 2017 | <120 | 120–129 | 130–139 | ≥140 | <80 | 80–89 | ≥90 |
| ESC/ESH 2018 | <120 | 120–129 | 130–139 | ≥140 | <80 | 80–89 | ≥90 |
| JSH 2019 | <120 | 120–129 | 130–139 | ≥140 | <80 | 80–89 | ≥90 |
| ISH 2020 | <130 | 130–139 | 140–159 | ≥160 | <85 | 85–99 | ≥100 |

## References

- Wegier, P. et al. (2021). *Visualizing blood pressure data: A human factors approach.* Journal of the American Medical Informatics Association. [DOI: 10.1093/jamia/ocab098](https://doi.org/10.1093/jamia/ocab098)
- Koopman, R. et al. (2025). *Physician and patient interpretation of blood pressure visualizations.* Journal of General Internal Medicine.
