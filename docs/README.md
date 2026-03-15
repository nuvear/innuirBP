# InnuirBP — Documentation & Communications Log

This folder is the single source of truth for all project documentation, design decisions, and collaborative communications for the InnuirBP project.

---

## Folder Structure

```
docs/
├── communications/     # Session logs, test reports, and inter-team messages
├── decisions/         # Architecture Decision Records (ADRs)
├── design/            # Design references, observations, and visual specs
├── specs/             # Product and technical specification documents
└── technical/         # Technical reference guides and troubleshooting
```

---

## Folder Conventions

### `communications/`

All session notes, testing reports, and messages between team members are logged here. Each file is named using the format:

```
YYYY-MM-DD_<author>_<topic>.md
```

**Examples:**
- `2026-03-14_Manus_initial-design-observations.md`
- `2026-03-15_Engineer_iPad-test-session-1.md`
- `2026-03-16_Rajkumar_week-view-feedback.md`

### `decisions/`

Architecture Decision Records (ADRs) document every significant technical or design decision made during the project. Each ADR is numbered sequentially.

**Format:** `ADR-NNN_<short-title>.md`

**Examples:**
- `ADR-001_swift-charts-over-d3.md`
- `ADR-002_swiftdata-cloudkit-sync.md`
- `ADR-003_mac-catalyst-first.md`

### `design/`

Design references, Apple HIG observations, color tokens, and visual specification notes.

**Examples:**
- `apple_hig_tokens.md` — Typography, color, and spacing tokens extracted from Apple HIG
- `ipad_design_observations.md` — Notes from Apple Health iPad reference screenshots

### `specs/`

Product and technical specification documents.

**Examples:**
- `innuir_bp_chart_spec_v2.md` — Full product specification (Innuir Platform aligned)
- `swift_project_blueprint.md` — Engineering blueprint and file architecture

### `technical/`

Technical reference guides for setup, debugging, and avoiding known issues.

**Key documents:**
- [ONBOARDING.md](../ONBOARDING.md) — **Start here** for new engineers
- [CHANGELOG.md](../CHANGELOG.md) — Project history and all changes (2026-03-15)
- [HealthKit-Setup-and-Troubleshooting.md](technical/HealthKit-Setup-and-Troubleshooting.md) — HealthKit configuration, code patterns, error fixes
- [Deployment-Engineer-Guide.md](technical/Deployment-Engineer-Guide.md) — Xcode build steps, provisioning

---

## How to Contribute

1. Create your file in the appropriate folder using the naming convention above.
2. Use the provided templates (see `communications/TEMPLATE_session_log.md`).
3. Commit with a clear message: `docs: add [date] [author] [topic]`.
4. Push to the `main` branch or open a Pull Request for review.
