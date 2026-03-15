// AppNavigation.swift
// InnuirBP
//
// Root navigation structure for the Innuir BP app.
// On iPad: NavigationSplitView with a sidebar (left column) and content area.
// On iPhone: NavigationStack with a tab bar.
//
// iPad sidebar matches Apple Health reference screenshot (1.jpg):
// ┌──────────────────────────────┐
// │  Edit                   [⊞] │  ← collapse/expand sidebar button
// │  🔍 Search                   │
// │  ♡ Summary (selected)        │
// │  👥 Sharing                  │
// │                              │
// │  Health Categories     ∨     │
// │  🔥 Activity                 │
// │  📏 Body Measurements        │
// │  ...                         │
// │  ❤ Heart                    │
// │  ...                         │
// │  📊 Vitals                   │
// │  ➕ Other Data               │
// │                              │
// │  Health Records        ∨     │
// │  📄 Clinical Documents       │
// └──────────────────────────────┘

import SwiftUI

// MARK: - Navigation Destination

enum NavDestination: Hashable {
    case summary
    case sharing
    case category(HealthCategory)
    case healthRecords(HealthRecord)
}

// MARK: - Health Category

enum HealthCategory: String, CaseIterable, Identifiable {
    case activity       = "Activity"
    case bodyMeasure    = "Body Measurements"
    case cycleTracking  = "Cycle Tracking"
    case hearing        = "Hearing"
    case heart          = "Heart"
    case medications    = "Medications"
    case mentalWellbeing = "Mental Wellbeing"
    case mobility       = "Mobility"
    case nutrition      = "Nutrition"
    case respiratory    = "Respiratory"
    case sleep          = "Sleep"
    case symptoms       = "Symptoms"
    case vitals         = "Vitals"
    case otherData      = "Other Data"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .activity:         return "flame.fill"
        case .bodyMeasure:      return "figure.arms.open"
        case .cycleTracking:    return "circle.dotted"
        case .hearing:          return "ear"
        case .heart:            return "heart.fill"
        case .medications:      return "pills.fill"
        case .mentalWellbeing:  return "brain.head.profile"
        case .mobility:         return "figure.walk"
        case .nutrition:        return "leaf.fill"
        case .respiratory:      return "lungs.fill"
        case .sleep:            return "bed.double.fill"
        case .symptoms:         return "waveform.path.ecg"
        case .vitals:           return "waveform.path.ecg.rectangle.fill"
        case .otherData:        return "plus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .activity:         return .orange
        case .bodyMeasure:      return .purple
        case .cycleTracking:    return .pink
        case .hearing:          return .blue
        case .heart:            return .red
        case .medications:      return .teal
        case .mentalWellbeing:  return .green
        case .mobility:         return .orange
        case .nutrition:        return .green
        case .respiratory:      return .blue
        case .sleep:            return .indigo
        case .symptoms:         return .orange
        case .vitals:           return .red
        case .otherData:        return .blue
        }
    }
}

// MARK: - Health Record

enum HealthRecord: String, CaseIterable, Identifiable {
    case clinicalDocuments = "Clinical Documents"
    var id: String { rawValue }
}

// MARK: - Root App Navigation

struct AppNavigation: View {

    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var selectedDestination: NavDestination? = .summary
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selected: $selectedDestination)
        } detail: {
            NavigationStack {
                destinationView(for: selectedDestination)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .task {
            await healthKitService.requestAuthorization()
        }
    }

    @ViewBuilder
    private func destinationView(for destination: NavDestination?) -> some View {
        switch destination {
        case .summary, nil:
            SummaryView()
        case .sharing:
            Text("Sharing")
                .navigationTitle("Sharing")
        case .category(let cat):
            if cat == .heart || cat == .vitals {
                BPDetailView()
            } else {
                Text(cat.rawValue)
                    .navigationTitle(cat.rawValue)
            }
        case .healthRecords(let rec):
            Text(rec.rawValue)
                .navigationTitle(rec.rawValue)
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {

    @Binding var selected: NavDestination?
    @State private var categoriesExpanded = true
    @State private var recordsExpanded = true

    var body: some View {
        List(selection: $selected) {

            // ── Search ─────────────────────────────────────────────────────
            NavigationLink(value: NavDestination.summary) {
                Label("Search", systemImage: "magnifyingglass")
            }

            // ── Top-level ──────────────────────────────────────────────────
            NavigationLink(value: NavDestination.summary) {
                Label("Summary", systemImage: "heart")
                    .foregroundStyle(Color(.systemBlue))
            }

            NavigationLink(value: NavDestination.sharing) {
                Label("Sharing", systemImage: "person.2.fill")
            }

            // ── Health Categories ──────────────────────────────────────────
            Section(isExpanded: $categoriesExpanded) {
                ForEach(HealthCategory.allCases) { category in
                    NavigationLink(value: NavDestination.category(category)) {
                        Label {
                            Text(category.rawValue)
                        } icon: {
                            Image(systemName: category.systemImage)
                                .foregroundStyle(category.color)
                        }
                    }
                }
            } header: {
                Text("Health Categories")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(.secondaryLabel))
            }

            // ── Health Records ─────────────────────────────────────────────
            Section(isExpanded: $recordsExpanded) {
                ForEach(HealthRecord.allCases) { record in
                    NavigationLink(value: NavDestination.healthRecords(record)) {
                        Label(record.rawValue, systemImage: "doc.text.fill")
                    }
                }
            } header: {
                Text("Health Records")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(.secondaryLabel))
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Health")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Edit") {}
                    .font(.system(size: 17))
            }
        }
    }
}
