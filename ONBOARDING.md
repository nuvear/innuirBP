# InnuirBP — Developer Onboarding Guide

**Last updated:** 2026-03-15  
**Audience:** New engineers joining the InnuirBP project

---

## 1. Project Overview

**InnuirBP** is a native SwiftUI blood pressure app for the Innuir Health Intelligence platform. It replicates the Apple Health Blood Pressure chart experience with Innuir-specific extensions:

- **HealthKit integration** — Import BP readings from Apple Health (read-only)
- **Manual entry** — Add readings without HealthKit
- **Clinical guidelines** — AHA 2017 and ESC/ESH 2018 toggle for chart bands
- **SwiftData** — Local storage with iCloudSyncService
- **WidgetKit** — Home Screen, Lock Screen, and accessory widgets

| Target | Description | Min OS |
|--------|-------------|--------|
| `InnuirBP` | Main app (iPhone, iPad) | iOS 17+ |
| `InnuirBPWidget` | WidgetKit extension | iOS 17+ |

---

## 2. Project History (Important for New Engineers)

### What Changed (2026-03-15)

The project was restructured. **HealthKitTest** (a working test project created to debug HealthKit sync) was **merged and renamed** into **InnuirBP**. The old InnuirBP project was **archived**.

| Before | After |
|--------|-------|
| Two projects: InnuirBP (broken sync) + HealthKitTest (working) | Single project: InnuirBP (working) |
| HealthKit sync crashed or hung | HealthKit sync works |
| Old InnuirBP at root | Old project in `archived/InnuirBP-retired/` |
| HealthKitTest in `HealthKitTest/` | Merged into root as InnuirBP |

### Why This Matters

- **Do not use** `archived/InnuirBP-retired/` — it is for reference only.
- The **current** InnuirBP includes all fixes from HealthKitTest.
- HealthKit requires specific setup (see Section 4).

---

## 3. Prerequisites

### Hardware & Software

- **Mac** with Apple Silicon (M1 or later recommended)
- **Xcode 16.0+**
- **XcodeGen** — `brew install xcodegen` (project is generated from `project.yml`)
- **iOS 17+** device (iPhone or iPad) for testing
- **Apple Developer Account** (required for signing)

### Identifiers

- **Bundle ID:** `com.innuir.bp`
- **Widget Bundle ID:** `com.innuir.bp.widget`
- **App Group:** `group.com.innuir.bp`

---

## 4. Initial Setup

### 4.1. Clone and Generate Project

```bash
git clone <repo-url>
cd innuirBP
xcodegen generate
open InnuirBP.xcodeproj
```

**Important:** The project is generated from `project.yml`. After pulling changes, always run `xcodegen generate` before opening in Xcode.

### 4.2. Provisioning Profile (Critical for HealthKit)

**Automatic signing often omits HealthKit** from the provisioning profile. You must use a **manual** profile:

1. In [Developer Portal](https://developer.apple.com/account/resources/profiles/list), create or use **InnuirBP HealthKit Dev**:
   - App ID: `com.innuir.bp` with **HealthKit** enabled
   - Type: Development
   - Download and double-click to install

2. In Xcode → **InnuirBP** target → **Signing & Capabilities**:
   - Uncheck **Automatically manage signing**
   - Select **InnuirBP HealthKit Dev** under Provisioning Profile

3. **InnuirBPWidget** uses automatic signing (different bundle ID).

### 4.3. Build and Run

1. **Product → Clean Build Folder** (⇧⌘K)
2. Select your iPad or iPhone
3. **Product → Run** (⌘R)

### 4.4. First Sync

1. Tap **Sync** in the Summary toolbar
2. Grant HealthKit permission when the sheet appears
3. Blood pressure data imports from Apple Health

---

## 5. Project Structure

```
innuirBP/
├── project.yml              # XcodeGen config — run "xcodegen generate" after edits
├── InnuirBP.xcodeproj       # Generated — do not edit manually
│
├── InnuirBP/                 # Main app target
│   ├── Application/
│   │   ├── InnuirBPApp.swift
│   │   └── AppNavigation.swift
│   ├── Models/
│   │   ├── BPReading.swift
│   │   └── ClinicalGuideline.swift
│   ├── Services/
│   │   ├── HealthKitService.swift   # HealthKit auth + sync + timeout gates
│   │   ├── HealthKitAuthHelper.h/m  # Obj-C NSException catcher (required)
│   │   └── iCloudSyncService.swift
│   ├── ViewModels/
│   ├── Views/
│   ├── Components/
│   ├── Shared/
│   │   └── BPReadingSnapshot.swift  # Shared with widget
│   ├── Resources/
│   │   └── Guidelines/
│   ├── Info.plist
│   ├── InnuirBP.entitlements
│   └── InnuirBP-Bridging-Header.h  # Exposes HealthKitAuthHelper to Swift
│
├── InnuirBPWidget/
│   ├── BPWidget.swift
│   ├── Info.plist
│   └── InnuirBPWidget.entitlements
│
├── docs/
│   ├── technical/            # Reference guides (read these)
│   ├── communications/
│   ├── decisions/
│   ├── design/
│   └── specs/
│
├── archived/
│   └── InnuirBP-retired/     # Old project — reference only
│
├── README.md
├── ONBOARDING.md             # This file
└── DEPLOYMENT_GUIDE.md
```

---

## 6. HealthKit — Critical Patterns (Do Not Change)

These patterns were established after extensive debugging. **Do not modify** without reading the technical docs.

| Pattern | Why |
|---------|-----|
| **Request only quantity types** (systolic, diastolic) in `requestAuthorization` | Including `HKCorrelationType(.bloodPressure)` causes "disallowed" error |
| **Obj-C HealthKitAuthHelper** wraps `requestAuthorization` | HealthKit throws `NSException` when entitlement is missing; Swift cannot catch it |
| **Resume continuation directly** from HealthKit completion block | `Task { @MainActor in continuation.resume() }` causes deadlock |
| **Defer auth to Sync tap** | Calling `requestAuthorization` at launch can crash if entitlement is missing |
| **30-second timeout gates** | Prevents indefinite hang if HealthKit completion never fires |

**Reference:** [docs/technical/HealthKit-Setup-and-Troubleshooting.md](docs/technical/HealthKit-Setup-and-Troubleshooting.md)

---

## 7. Key Files

| File | Purpose |
|------|---------|
| `HealthKitService.swift` | HealthKit auth, fetch, SwiftData insert, timeout gates |
| `HealthKitAuthHelper.m` | Catches NSException; **must** use `__attribute__((noinline))` |
| `InnuirBP-Bridging-Header.h` | Exposes Obj-C helper to Swift |
| `iCloudSyncService.swift` | ModelContainer for SwiftData |
| `BPReadingSnapshot.swift` | Shared struct for widget (in `InnuirBP/Shared/`) |
| `project.yml` | XcodeGen config — edit this, then run `xcodegen generate` |

---

## 8. Documentation Index

| Document | Purpose |
|----------|---------|
| [HealthKit-Setup-and-Troubleshooting.md](docs/technical/HealthKit-Setup-and-Troubleshooting.md) | HealthKit config, code patterns, error fixes, verification checklist |
| [Deployment-Engineer-Guide.md](docs/technical/Deployment-Engineer-Guide.md) | Build steps, provisioning, what was retired |
| [HealthKit-Sync-Hang-Report.md](docs/technical/HealthKit-Sync-Hang-Report.md) | Original technical report (architecture, root-cause analysis) |
| [docs/decisions/](docs/decisions/) | ADRs (Swift Charts, SwiftData+CloudKit, etc.) |
| [docs/specs/](docs/specs/) | Chart spec, engineering blueprint |

---

## 9. Testing Checklist

Before committing:

- [ ] `xcodegen generate` runs without errors
- [ ] Clean build succeeds (⇧⌘K, then ⌘B)
- [ ] App launches on iPad
- [ ] Tap Sync — HealthKit permission sheet appears (or error if profile wrong)
- [ ] Manual entry works
- [ ] BP Detail chart displays
- [ ] Widget appears in widget gallery when data exists

---

## 10. Troubleshooting

| Issue | See |
|-------|-----|
| Sync crashes | [HealthKit-Setup-and-Troubleshooting.md](docs/technical/HealthKit-Setup-and-Troubleshooting.md) § 4 |
| "disallowed" error | Use manual profile; request only systolic/diastolic |
| App not in Health list | Tap Sync to trigger auth; reinstall if needed |
| Build fails after pull | Run `xcodegen generate` |
| Provisioning errors | Use **InnuirBP HealthKit Dev** manual profile |

---

## 11. Quick Reference

### Build from Terminal

```bash
cd innuirBP
xcodegen generate
xcodebuild -scheme InnuirBP -destination 'generic/platform=iOS' build
```

### Run on Device

```bash
# After building, install and launch
xcrun devicectl device install app --device <DEVICE_ID> <path-to-InnuirBP.app>
xcrun devicectl device process launch --device <DEVICE_ID> com.innuir.bp
```

---

*Welcome to the team. For HealthKit or sync issues, start with [HealthKit-Setup-and-Troubleshooting.md](docs/technical/HealthKit-Setup-and-Troubleshooting.md).*
