# ADR-001 — Swift Charts over D3.js for Native Implementation

**Date:** 14 Mar 2026
**Status:** Accepted
**Deciders:** Rajkumar (Product Owner), Manus AI

---

## Context

The InnuirBP project requires a high-quality Blood Pressure chart that matches the visual fidelity of the Apple Health app. Two candidate technologies were evaluated for the native implementation:

1. **Swift Charts** — Apple's native charting framework, built into SwiftUI since iOS 16.
2. **D3.js** — A JavaScript SVG charting library, used in a web-based prototype.

A side-by-side comparison prototype was built (`bp_d3.html` vs `index.html`) to evaluate visual quality differences.

---

## Decision

**Swift Charts** is selected as the charting framework for the native InnuirBP application.

---

## Rationale

Swift Charts is the definitive choice for native Apple platform development for the following reasons:

- It is built into SwiftUI and renders using Metal/Core Graphics, producing pixel-perfect output at 120 Hz on ProMotion displays.
- It automatically uses SF Pro at the correct HIG sizes and weights — no manual font configuration required.
- Dark Mode, Dynamic Type, VoiceOver, and Audio Graphs are supported out of the box with zero configuration.
- It is the same framework used by Apple in the Health app itself, ensuring visual consistency.
- No external dependencies are introduced — the framework is part of the Apple SDK.

D3.js, while excellent for web-based SVG rendering, is not applicable to a native Swift application.

---

## Consequences

- The Chart.js web prototype (`index.html`) serves as the **visual specification** — a pixel-level reference for every design decision — rather than as production code.
- The deployment engineer must use Xcode 16+ and target iOS 17+ / macOS 14+ to access the full Swift Charts API.
- Custom mark types (vertical segment with circle + diamond) must be implemented using Swift Charts' `PointMark` and `RuleMark` primitives.
