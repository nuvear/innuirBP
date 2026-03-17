import SwiftUI

struct ToolbarView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        HStack(spacing: 16) {
            // View range picker
            HStack(spacing: 4) {
                Text("View:").font(.caption).foregroundStyle(.secondary)
                Picker("View", selection: $viewModel.selectedView) {
                    ForEach(BPTimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            Spacer()

            // Smoothing toggle
            HStack(spacing: 6) {
                Text("Smoothing:").font(.caption).foregroundStyle(.secondary)
                Toggle("LOWESS", isOn: $viewModel.showSmoothing)
                    .toggleStyle(.checkbox)
            }

            Spacer()

            // Clinical standard picker
            HStack(spacing: 4) {
                Text("Standard:").font(.caption).foregroundStyle(.secondary)
                Picker("Standard", selection: $viewModel.selectedStandard) {
                    ForEach(ClinicalStandard.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .frame(width: 140)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
