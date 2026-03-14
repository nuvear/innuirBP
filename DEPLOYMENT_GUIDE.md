# InnuirBP — Deployment & Testing Guide

**Version:** 1.0
**Date:** 14 Mar 2026
**Author:** Manus AI

---

## 1. Overview

This document provides comprehensive instructions for the deployment engineer to build, run, and test the `InnuirBP` application on both **iOS/iPadOS** and **macOS (via Mac Catalyst)**. The goal is to verify the core functionality as defined in the project's `README.md` and the visual specification (the Chart.js prototype).

---

## 2. Prerequisites

### 2.1. Hardware

- **Mac computer** with Apple Silicon (M1 or later recommended).
- **iPhone or iPad** running iOS 17 / iPadOS 17 or later (for device testing).
- **Apple Watch** running watchOS 10 or later (optional, for testing accessory widgets).

### 2.2. Software

- **macOS:** 14.0 (Sonoma) or later.
- **Xcode:** 16.0 or later.
- **Git:** Command line tools for Xcode.
- **Apple Developer Account:** Required for code signing and enabling capabilities.

### 2.3. Access

- **GitHub Repository:** Read/write access to `https://github.com/nuvear/innuirBP`.
- **Apple Health Data:** The test device should have some sample Blood Pressure data in the Apple Health app. If not, use the app's manual entry feature to add at least 10-15 readings with varying dates and values.

---

## 3. Initial Setup

### 3.1. Clone the Repository

```bash
git clone https://github.com/nuvear/innuirBP.git
cd InnuirBP
```

### 3.2. Create the Xcode Project

Follow the instructions in `README.md` section **3. Setup in Xcode** precisely. This involves:

1.  Creating the main `InnuirBP` app project in Xcode.
2.  Adding the `InnuirBPWidget` extension target.

### 3.3. Configure Capabilities & Signing

This is the most critical step.

1.  In Xcode, select the **InnuirBP** project in the Project Navigator.
2.  Select the **InnuirBP** target and go to the **Signing & Capabilities** tab.
3.  Select your **Team** to enable automatic signing.
4.  Click **+ Capability** and add the following:
    - **HealthKit:** Check the "Clinical Health Records" box.
    - **iCloud:** Select "CloudKit" and use the default container (`iCloud.com.your-bundle-id`).
    - **App Groups:** Add a new group named `group.com.innuir.bp` (or your chosen group name).
    - **Background Modes:** Enable "Background fetch".

5.  Select the **InnuirBPWidget** target and go to **Signing & Capabilities**.
6.  Select your **Team**.
7.  Click **+ Capability** and add **App Groups**, selecting the same `group.com.innuir.bp`.

### 3.4. Add Source Files

Drag and drop all the `.swift` and `.json` files from the cloned repository into the corresponding folders in the Xcode Project Navigator, ensuring correct target membership as specified in the `README.md`.

---

## 4. Build & Run Instructions

### 4.1. iOS / iPadOS

1.  Connect your iPhone or iPad to the Mac.
2.  In Xcode, select your device from the scheme menu (e.g., "My iPhone").
3.  Press **Cmd + R** or click the **Run (▶)** button.
4.  The app will build and install on your device.
5.  On first launch, the app will request HealthKit permissions. **You must grant access to Blood Pressure data.**

### 4.2. macOS (Mac Catalyst)

1.  In Xcode, select the **InnuirBP** target.
2.  Go to the **General** tab.
3.  Under **Deployment Info**, check the box for **Mac Catalyst**.
4.  Select **My Mac** from the scheme menu.
5.  Press **Cmd + R** or click the **Run (▶)** button.
6.  The app will build and launch as a native macOS application.
7.  The first time you access the chart, it will request HealthKit permissions.

---

## 5. Testing Plan

Execute the following test cases on both **iPad** and **Mac Catalyst**. Log all results, including screenshots and any console output for failures.

### 5.1. Test Case: First Launch & Data Sync

| Step | Action | Expected Result |
|---|---|---|
| 1 | Launch the app for the first time. | The "Summary" screen appears. A HealthKit authorization sheet is presented. |
| 2 | Grant HealthKit access for Blood Pressure. | The sheet dismisses. The "Pinned" BP tile on the Summary screen updates to show the latest reading from Apple Health. |
| 3 | Navigate to the BP Detail screen. | The chart displays the synced HealthKit data. The BP Log calendar shows checkmarks for days with readings. |

### 5.2. Test Case: Manual Data Entry

| Step | Action | Expected Result |
|---|---|---|
| 1 | On the BP Detail screen, tap the **+** button. | The Manual Entry modal appears. |
| 2 | Enter a new Systolic/Diastolic reading for today's date. | The data saves. The chart updates to include the new reading. The BP Log calendar adds a checkmark for today. |
| 3 | Add another reading for a past date (e.g., yesterday). | The chart and log update correctly. |

### 5.3. Test Case: Chart Interaction

| Step | Action | Expected Result |
|---|---|---|
| 1 | On the BP Detail screen, use the top segmented control. | The chart correctly switches between Day, Week, Month, 6 Months, and Year views. The stats header and stage counts update. |
| 2 | Use the AHA/ESC toggle. | The clinical bands, stage sidebar, and stage counts update to reflect the selected guideline. |
| 3 | Scrub your finger across the chart. | A tooltip appears, following your finger and showing the value of the nearest data point. |

### 5.4. Test Case: Widget Functionality

| Step | Action | Expected Result |
|---|---|---|
| 1 | On the iOS/iPadOS Home Screen, add the InnuirBP widget. | All widget sizes (Small, Medium, Large) are available and display correctly. |
| 2 | Add the Medium widget. | It shows the latest reading and a 7-day mini-chart. |
| 3 | Tap the widget. | The main InnuirBP app opens directly to the BP Detail screen. |
| 4 | On the macOS Desktop, add the widget. | The widget appears and functions identically to the iOS version. |

### 5.5. Test Case: iCloud Sync

| Step | Action | Expected Result |
|---|---|---|
| 1 | Add a manual entry on the iPad. | After a few moments, launch the app on the Mac. The new reading should appear automatically. |
| 2 | Delete a reading on the Mac (feature to be added). | The reading should disappear from the iPad. |

---

## 6. Logging & Reporting

Please log all test results, notes, and screenshots in the `/docs/communications` folder in the Git repository. Create a new markdown file for each testing session (e.g., `2026-03-15_iPad_Test_Session.md`). Use the provided template.

For any bugs or crashes, please file an issue in the GitHub repository's **Issues** tab, including:

- A clear, descriptive title.
- Steps to reproduce.
- Expected vs. Actual behavior.
- Device, OS version, and app version.
- Any relevant console logs or crash reports.
