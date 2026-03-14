# Product Specification: Innuir BP Chart — Native Apple Ecosystem

**Document Version:** 2.0
**Date:** 14 March 2026
**Platform Targets:** iOS 17+, iPadOS 17+, macOS 14+ (Sonoma)
**Author:** Manus AI

---

## 1. Executive Summary

This document defines the product requirements for the **Innuir Blood Pressure (BP) Chart**, a core component of the Innuir Health Intelligence Platform. The chart is a native Apple ecosystem product, built with **SwiftUI** and **Swift Charts** to deliver a pixel-perfect, HIG-compliant user experience on iPhone, iPad, and Mac.

In alignment with the Innuir Platform Specification v1.0, this component follows a **two-tier architecture**: a full interactive chart view within the main Innuir application, and a family of companion WidgetKit widgets for the Home Screen and Lock Screen. The product adheres to Innuir’s core principles of **privacy-first AI**, **on-device data storage**, and **context-aware health intelligence**.

Data is sourced from two streams: direct read-only access to the user’s **HealthKit** store, and a **manual data entry UI** within the app. All data is stored locally on the user’s device and securely synced across their Apple ecosystem devices using **iCloud (CloudKit)**. No health data is ever sent to Innuir’s servers.

## 2. Strategic Alignment with Innuir Platform

The BP Chart is a foundational element of the Innuir Health Intelligence Model, directly providing the **Intensity** and **Change** dimensions of the **T-LICC framework** for blood pressure events.

> **T-LICC Framework:**
> - **T**ime: When did the reading occur?
> - **L**ocation: Where was the user?
> - **I**ntensity: What was the reading? (e.g., 131/86 mmHg, Stage 1)
> - **C**ontext: What else was happening? (e.g., Travel, Poor Sleep)
> - **C**hange: How does it differ from baseline? (e.g., +12 vs. 7-day average)

The chart serves as the primary visualization layer for the “Body Signals” component of the Innuir ecosystem, transforming raw biometric data into actionable visual information.

## 3. Architecture & Data Flow

### 3.1. Two-Tier Architecture

| Tier | Component | Description |
|---|---|---|
| **Tier 1** | Main App Chart View | Full interactive SwiftUI view. The primary user experience for deep analysis. |
| **Tier 2** | WidgetKit Widget Family | Glanceable companion widgets for the Home Screen, Lock Screen, and Mac Desktop. Tapping deep-links to the main app. |

### 3.2. Data Flow & Privacy

The data flow strictly adheres to the Innuir privacy-first model.

```mermaid
graph TD
    subgraph On-Device
        A[HealthKit] --> C{Innuir App}
        B[Manual Entry UI] --> C
        C --> D[Local Database (Core Data / SwiftData)]
        D --> E[iCloud Sync (CloudKit)]
        E --> F[Other User Devices]
        D --> G[BP Chart View]
    end
```

1.  **Data Ingestion:** The app reads BP data from HealthKit and accepts manual entries from the user.
2.  **Local Storage:** All data is saved to a local on-device database (e.g., Core Data or SwiftData).
3.  **iCloud Sync:** The local database is securely synced across the user’s other Apple devices (iPhone, iPad, Mac) via their private iCloud account. **No data is transmitted to Innuir servers.**
4.  **Chart Rendering:** The BP Chart view reads directly from the local database.

### 3.3. Technology Stack

| Layer | Technology | Rationale |
|---|---|---|
| UI Framework | SwiftUI | Native Apple framework for modern, declarative UI. |
| Charting | Swift Charts | Apple’s native charting library for HIG-compliant visuals. |
| Data Storage | Core Data / SwiftData | Robust, on-device persistence with built-in iCloud sync capabilities. |
| Widget | WidgetKit + AppIntents | Native widget framework for Home/Lock Screen integration. |
| Language | Swift 5.9+ | Modern, safe, and performant language for Apple platforms. |

## 4. Feature Set

### 4.1. Data Management

- **HealthKit Integration:** One-time read authorization to import the user’s full BP history from Apple Health.
- **Manual Entry UI:** A simple, dedicated interface for users to manually log a new BP reading (systolic, diastolic, timestamp). This data is stored exclusively within the Innuir app’s local database.

### 4.2. Chart View (Tier 1)

- **Time Ranges:** Segmented control for Day, Week, Month, 6 Months, and Year views.
- **Guideline Toggle:** AHA / ESC guideline selection with animated chart updates.
- **Interactive Scrubbing:** Tooltip with exact reading and timestamp on tap-and-drag.
- **Clinical Context:** Color-coded bands and dashed threshold lines.
- **Stats Header:** Dynamic summary of the visible data range.
- **Stage Sidebar:** List of clinical stages with reading counts for the selected period.

### 4.3. Widget Family (Tier 2)

- **Accessory Widgets:** Glanceable view of the most recent BP reading and its classification.
- **System Widgets (Small, Medium, Large):** Ranging from a simple 7-day sparkline to a fully interactive chart with an AHA/ESC toggle, powered by App Intents.

## 5. Design Language (Innuir Brand + Apple HIG)

The design merges the Innuir brand identity with Apple’s native Human Interface Guidelines.

| Element | Specification |
|---|---|
| **Font** | **Inter** (as per Innuir Brand Guide). Use SwiftUI’s built-in font styles (`.headline`, `.body`) to ensure Dynamic Type support. |
| **Primary Color** | **#5E3BC5 (Innuir Purple)**. Used for active states, selected buttons, and key highlights. |
| **Secondary Color** | **#7A64D6 (Innuir Light Purple)**. Used for secondary UI elements. |
| **Chart Anatomy** | Follows Apple HIG for marks, axes, and layout, as detailed in the previous specification document. The core visual structure of the chart remains identical to the Apple Health app. |
| **Iconography** | SF Symbols, Apple’s native icon library. |

## 6. Development Roadmap (Aligned with Innuir Phases)

| Phase | Innuir Platform Goal | BP Chart Deliverable |
|---|---|---|
| **Phase 1** | Health diary, BP tracking, Timeline | **Core Chart View:** HealthKit import, manual entry UI, Week/Month views, AHA guideline. |
| **Phase 2** | Diet, Meditation, Supplements | **Full Chart View:** All 5 time ranges, ESC toggle, stats header, sidebar. |
| **Phase 3** | Environment context, Travel detection | **Widget Family:** Accessory, Small, and Medium widgets. |
| **Phase 4** | AI intelligence engine | **Interactive Widgets:** Large/XL widgets with App Intents for direct interaction. |

## 7. Updated Scope (User Feedback)

Based on your feedback, the following points from the previous document are now clarified:

- **Data Storage:** The system uses a hybrid model: HealthKit (read-only) + Manual Entry (read/write). All data is stored locally and synced via the user’s private iCloud. **This explicitly excludes any Innuir-side cloud storage.**
- **Device Connectivity:** The app does **not** pair directly with Bluetooth monitors. It leverages Apple Health as the central aggregation layer.
- **Platform Support:** The scope is strictly limited to the Apple ecosystem (iOS, iPadOS, macOS). No Android, Windows, or web versions are planned.

---

This revised specification provides a clear roadmap for developing the BP Chart as a core, privacy-first component of the Innuir Health Intelligence Platform, fully aligned with both the Innuir technical architecture and the native Apple user experience.
