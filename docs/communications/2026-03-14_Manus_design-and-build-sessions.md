# Session Log — 2026-03-14 — Manus AI — Design & Build Sessions (Summary)

**Date:** 14 Mar 2026
**Author:** Manus AI
**Session Type:** [x] Design Review  [x] Development  [x] Decision
**Participants:** Rajkumar (Product Owner), Manus AI (Design & Development)

---

## Summary

This log summarises all design and development sessions conducted between Rajkumar and Manus AI leading up to the initial commit of the InnuirBP Swift project. The sessions covered analysis of Apple Health reference screenshots, iterative development of a Chart.js visual specification prototype, and the production of the full native Swift project structure.

---

## Key Decisions Made

### Decision 1 — Chart.js as Visual Specification Tool

The Chart.js web prototype (`index.html`) was established as the **living visual specification** for the native Swift Charts implementation. It is not the final product — it is the design source of truth that the Swift developer will implement.

### Decision 2 — Apple Ecosystem Only

The project scope was explicitly narrowed to the Apple ecosystem: iPhone, iPad, and iMac (via Mac Catalyst). No Android, Windows, or web platform support is planned.

### Decision 3 — Single Vital First (Blood Pressure)

The first build focuses exclusively on Blood Pressure as the single vital. After successful replication and customisation of the BP chart, other vitals will be considered.

### Decision 4 — Two-Tier Architecture

- **Tier 1 (Drill-down Detail View):** The full interactive BP chart — the primary chart experience with all five time ranges, clinical bands, AHA/ESC toggle, and scrubbing tooltip.
- **Tier 2 (Summary / Insight Panel):** A secondary panel showing statistical summaries, trend indicators, and T-LICC context. To be built in a subsequent phase.

### Decision 5 — Data Model

- HealthKit is the primary data source (read-only).
- Manual entry UI allows adding data not captured by HealthKit. Manual data is **never written back to HealthKit**.
- All data is stored on-device using SwiftData and synced across the user's Apple devices via iCloud (CloudKit). No data is stored on Innuir servers.

### Decision 6 — AHA + ESC Dual Guideline Support

Both AHA 2017 and ESC/ESH 2018 clinical guidelines are supported via a toggle. Guidelines are loaded at runtime from bundled JSON files (`aha_hypertension.json`, `esc_hypertension.json`).

### Decision 7 — Mac Catalyst First

The iMac version will be delivered via Mac Catalyst (enabling the Mac Catalyst checkbox in Xcode) rather than a separate native macOS target. This is the fastest path to a working iMac app with zero additional Swift code for the chart itself.

---

## Visual Specification Iterations

The Chart.js prototype went through the following key iterations:

| Version | Key Changes |
|---|---|
| v1 | Initial Chart.js prototype — basic chart with AHA stages |
| v2 | Centered x-axis alignment for all views; AHA/ESC guideline toggle added |
| v3 | Full Apple HIG compliance — SF Pro typography, system colors, Apple segmented control |
| v4 | Day view: time in tooltip; word-wrapped band labels ("Below\n120"); ESC JSON audit |
| v5 | Full-width layout — card fills viewport in all three format modes (iOS/iMac/PWC) |
| v6 | D3.js prototype added for quality comparison; Chart.js confirmed as spec reference |

---

## Reference Files

The following files were used as design references throughout the sessions:

| File | Description |
|---|---|
| `sample_images/*.jpeg` | Apple Health iPad screenshots from the original `hypertension-chart.zip` |
| `1.jpg` | Apple Health Summary screen with pinned BP tile |
| `2.jpg` | Apple Health BP Detail screen (with sidebar) |
| `3.jpg` | Apple Health BP Detail screen (full-width, sidebar hidden) |
| `4.jpg` | Apple Health Manual Entry modal |
| `innuir_color_pallette.md` | Innuir brand color palette |
| `bp_chart_requirement.md` | Original BP chart requirements |
| `Innuir_Platform_Spec_Pack_v1.0.md` | Innuir Platform Specification |

---

## Action Items

| # | Task | Owner | Status |
|---|---|---|---|
| 1 | Create Xcode project following README setup guide | Deployment Engineer | Pending |
| 2 | Configure capabilities (HealthKit, iCloud, App Groups) | Deployment Engineer | Pending |
| 3 | Test on iPad — all 5 time range views | Deployment Engineer | Pending |
| 4 | Test on Mac Catalyst | Deployment Engineer | Pending |
| 5 | Continue Week view review and fixes | Manus AI + Rajkumar | Pending |
| 6 | Build Tier 2 Summary/Insight Panel | Manus AI | Pending |

---

## Next Session

**Planned:** Next available session with Rajkumar
**Agenda:**
- Continue Week view review
- Begin Tier 2 Summary/Insight Panel design
- Review deployment engineer test results
