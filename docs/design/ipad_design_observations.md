# iPad Reference Screenshot Design Observations

## Screen 1 — Summary Screen (1.jpg)

### Left Navigation Sidebar (~250px wide)
- Top: "Edit" (top-left, gray text) + sidebar collapse icon (top-right, square icon)
- Search row: magnifier icon + "Search" label, gray text
- "Summary" row: heart icon (blue/purple tinted) + "Summary" label — ACTIVE state, purple pill highlight, purple text
- "Sharing" row: two-person icon + "Sharing" label, gray text
- Section header: "Health Categories" with chevron-down (collapsible)
- Category list (icon + label, gray text): Activity (flame), Body Measurements (figure), Cycle Tracking (circle), Hearing (ear), Heart (heart), Medications (pill), Mental Wellbeing (brain), Mobility (figure), Nutrition (apple), Respiratory (lungs), Sleep (bed), Symptoms (thermometer), Vitals (waveform), Other Data (plus)
- Section header: "Health Records" with chevron-down
- "Clinical Documents" row (document icon)

### Main Content Area — Summary Screen
- **Profile Header:** Large gradient background (pink/salmon gradient top ~200px)
  - Avatar circle (~72px): purple/lavender with initials "RR" in white, bold
  - Name: "Rajkumar" — SF Pro Display, ~28pt, bold, black
  - "Profile >" — blue link text, ~15pt
  - "Last sync: Yesterday at 11:51PM" — gray, ~13pt
- **"Pinned" section header:** "Pinned" bold ~20pt + "Edit" blue link right-aligned
- **Blood Pressure tile** (white card, rounded ~12pt):
  - "❤️ Blood Pressure" — red heart icon + "Blood Pressure" blue link text, ~15pt
  - "12 Mar ›" — gray date + chevron, right-aligned
  - "125/78 mmHg" — large bold ~34pt black + "mmHg" ~17pt gray
  - Card has subtle shadow, ~16px padding
- **"Show All Health Data" row** — white card, health icon + label + chevron-right
- **"Trends" section header** — "Trends" bold ~20pt
- **"Show All Health Trends" row** — white card, trends icon + label + chevron-right
- **"Highlights" section header** — "Highlights" bold ~20pt
- **Highlight cards** (3-column grid):
  - Each card: white background, rounded, icon + colored title + description text + mini chart/map
  - "Workouts" — flame icon orange, map of workout route
  - "Active Energy" — flame icon orange, bar chart with orange baseline
  - "Heart Rate: Workout" — heart icon red, sparkline chart with MAX/MIN labels

---

## Screen 2 — BP Detail Chart with Left Nav (2.jpg)

### Navigation Bar (top)
- Back arrow "<" (left)
- Title: "Blood Pressure" — centered, bold ~17pt
- "+" button (right) — add new reading

### Left Sidebar (same as Screen 1, "Summary" still highlighted)

### Chart Area (right of sidebar)
- Segmented control: Day | Week | Month | 6 Months | Year — "Week" selected (darker pill)
- Stats header:
  - "● SYSTOLIC" — black dot + "SYSTOLIC" allcaps gray ~11pt
  - "120–130" — bold ~34pt black
  - "◆ DIASTOLIC" — red diamond + "DIASTOLIC" allcaps gray ~11pt  
  - "78–88 mmHg" — bold ~34pt black + "mmHg" ~17pt gray
  - "8–14 Mar 2026" — gray ~13pt date range
  - "ⓘ" info button — right-aligned
- Chart: Week view, Sun–Sat x-axis labels
  - Two data clusters: Wed (black marks, two readings stacked) + Thu (single black dot systolic, single red diamond diastolic)
  - Black marks = data NOT in hypertension zone (normal/elevated)
  - Red marks = data IN hypertension zone
  - No clinical band visible in this view (readings are in normal range)
  - Y-axis: 60, 80, 100, 120, 140, 160 — right-aligned
- **Stage pill** (below chart): "Hypertension - Stage 1" gray pill + "1 day" right-aligned
- **"Show All Blood Pressure Ranges"** — blue link text, right-aligned

### Blood Pressure Log (below chart)
- Section header: "Blood Pressure Log" bold ~20pt + "Options" blue link right-aligned
- White card:
  - "Measurements Taken: 2" — bold label + value
  - "Days Left: 23" — bold label + value
  - Calendar grid (month view):
    - Column headers: Sun Mon Tue Wed Thu Fri Sat — gray ~12pt
    - Month label "Mar" above the week row
    - Days with readings: Wed 11 + Thu 12 have purple checkmark (✓)
    - Today (15) has purple circle outline
    - Future dates shown normally
    - Next month "Apr" label shown mid-calendar

---

## Screen 3 — BP Detail Chart, Nav Hidden (3.jpg)

### Navigation Bar
- Back arrow "<" (left)
- Centered tab bar: sidebar-icon | "Summary" (blue, active) | "Sharing" | "Hearing" | search-icon
- Title: "Blood Pressure" — below tab bar, bold ~17pt
- "+" button (right)

### Chart Area (full width — no left sidebar)
- Same chart as Screen 2 but wider
- Segmented control: Day | Week | Month | 6 Months | Year
- Stats header same as Screen 2
- Chart fills full content width
- Stage pill: "Hypertension - Stage 1" + "1 day" + "Show All Blood Pressure Ranges" blue link

### Blood Pressure Log (below chart, narrower card ~40% width)
- Same calendar structure but card is narrower (left-aligned, ~50% width)

---

## Screen 4 — Manual Entry Modal (4.jpg)

### Background
- Chart screen is dimmed/blurred behind the modal

### Modal Card (~520px wide, centered)
- White card, rounded ~16pt corners
- **Top bar:**
  - "✕" close button — left, gray circle ~28pt
  - Checkmark "✓" — right, gray (inactive until form filled)
- **Icon:** Blood pressure cuff icon (pink/red tinted circle, ~56pt)
- **Title:** "Blood Pressure" — bold ~22pt, centered
- **Form fields:**
  - "Date" row — label left + "15 Mar 20..." right (date picker, tappable)
  - Separator line
  - "Systolic" row — label left + "e.g. 115" placeholder gray right
  - Separator line
  - "Diastolic" row — label left + "e.g. 75" placeholder gray right
  - Separator line
- **Helper text:** "Try to position the blood pressure cuff in the same location each time. Learn More..." — gray ~13pt, "Learn More..." blue link
- **Numpad** (floating, overlapping modal bottom-right):
  - Standard iOS phone numpad: 1-9 + 0 + backspace
  - White background, rounded ~16pt, shadow
  - Each key: number large ~28pt bold + letters small ~11pt below (ABC, DEF, etc.)
  - Backspace key: ⌫ symbol

---

## Key Design Tokens Observed

| Token | Value |
|---|---|
| Left sidebar width | ~250px |
| Active nav item | Purple pill (#5E3BC5 or system purple) |
| Profile avatar | ~72px circle, purple/lavender bg, white initials |
| Gradient header | Pink/salmon, ~200px tall |
| Card corner radius | 12pt |
| Card shadow | Subtle, 2-layer |
| Section header font | SF Pro Display, ~20pt, Bold |
| Body font | SF Pro Text, ~15pt, Regular |
| Blue link color | System Blue (#007AFF) |
| Calendar checkmark | Purple/violet (system purple) |
| Calendar today | Purple circle outline |
| Modal width | ~520px |
| Numpad width | ~240px |
