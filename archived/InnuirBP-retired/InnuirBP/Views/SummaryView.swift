// SummaryView.swift
// InnuirBP
//
// The Summary screen — the first screen the user sees.
// Matches the Apple Health iPad reference screenshot (1.jpg):
//
// ┌─────────────────────────────────────────────────────────────────┐
// │  [Avatar RR]  Rajkumar                                          │
// │               Profile >                                         │
// │               Last sync: Yesterday at 11:51 PM                  │
// │                                                                 │
// │  Pinned                                          Edit           │
// │  ┌────────────────────────────────────┐                         │
// │  │  ❤ Blood Pressure    12 Mar  >    │                         │
// │  │                                   │                         │
// │  │  125/78 mmHg                      │                         │
// │  └────────────────────────────────────┘                         │
// │                                                                 │
// │  [❤ Show All Health Data              >]                        │
// │                                                                 │
// │  Trends                                                         │
// │  [≈ Show All Health Trends            >]                        │
// │                                                                 │
// │  Highlights                                                     │
// │  [Tile 1]  [Tile 2]  [Tile 3]                                   │
// └─────────────────────────────────────────────────────────────────┘

import SwiftUI
import SwiftData

struct SummaryView: View {

    // MARK: - Environment & Data

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BPReading.timestamp, order: .reverse) private var readings: [BPReading]
    @EnvironmentObject private var healthKitService: HealthKitService

    // MARK: - Navigation & Alerts

    @State private var navigateToBPDetail = false
    @State private var showSyncError = false

    // MARK: - Computed

    private var latestReading: BPReading? { readings.first }

    private var lastSyncLabel: String {
        guard let date = healthKitService.lastSyncDate else { return "Never synced" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last sync: \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Profile Header ─────────────────────────────────────────
                ProfileHeaderView(lastSyncLabel: lastSyncLabel)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                // ── Pinned Section ─────────────────────────────────────────
                HStack {
                    Text("Pinned")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(.label))
                    Spacer()
                    Button("Edit") {}
                        .font(.system(size: 15))
                        .foregroundStyle(Color(.systemBlue))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // BP Pinned Tile
                NavigationLink(destination: BPDetailView()) {
                    BPPinnedTile(reading: latestReading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Show All Health Data row
                NavigationLink(destination: EmptyView()) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Color(.systemRed))
                        Text("Show All Health Data")
                            .font(.system(size: 17))
                            .foregroundStyle(Color(.label))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                // ── Trends Section ─────────────────────────────────────────
                Text("Trends")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(.label))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                NavigationLink(destination: EmptyView()) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(Color(.systemBlue))
                        Text("Show All Health Trends")
                            .font(.system(size: 17))
                            .foregroundStyle(Color(.label))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                // ── Highlights Section ─────────────────────────────────────
                Text("Highlights")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(.label))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Placeholder highlight tiles (to be populated with real data)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        HighlightTilePlaceholder(
                            icon: "figure.walk",
                            color: .orange,
                            title: "Workouts",
                            bodyText: "You walked 5.4 kilometres during your most recent workout."
                        )
                        HighlightTilePlaceholder(
                            icon: "flame.fill",
                            color: .orange,
                            title: "Active Energy",
                            bodyText: "The last 7 days you burned an average of 210 kilocalories a day."
                        )
                        HighlightTilePlaceholder(
                            icon: "heart.fill",
                            color: .red,
                            title: "Heart Rate: Workout",
                            bodyText: "Your heart rate range during your recent walk was 104–133 beats per minute."
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await healthKitService.syncFromHealthKit(context: modelContext)
                        if healthKitService.syncError != nil {
                            showSyncError = true
                        }
                    }
                } label: {
                    if healthKitService.isSyncing {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .alert(
            "Sync Failed",
            isPresented: $showSyncError,
            presenting: healthKitService.syncError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

// MARK: - Profile Header

struct ProfileHeaderView: View {
    let lastSyncLabel: String

    // In a real app, these would come from the user's profile model.
    private let initials = "RR"
    private let name = "Rajkumar"

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(Color(.systemPurple).opacity(0.3))
                    .frame(width: 60, height: 60)
                Text(initials)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(.systemPurple))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(.label))

                Button("Profile >") {}
                    .font(.system(size: 15))
                    .foregroundStyle(Color(.systemBlue))

                Text(lastSyncLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(.top, 2)
            }
        }
    }
}

// MARK: - BP Pinned Tile

struct BPPinnedTile: View {
    let reading: BPReading?

    private var dateLabel: String {
        guard let reading else { return "No data" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: reading.timestamp)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color(.systemRed))
                    .font(.system(size: 13))
                Text("Blood Pressure")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.systemRed))
                Spacer()
                Text(dateLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.secondaryLabel))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }

            if let reading {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(reading.systolic))/\(Int(reading.diastolic))")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color(.label))
                    Text("mmHg")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(.secondaryLabel))
                }
            } else {
                Text("No readings yet")
                    .font(.system(size: 17))
                    .foregroundStyle(Color(.secondaryLabel))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Highlight Tile Placeholder

struct HighlightTilePlaceholder: View {
    let icon: String
    let color: Color
    let title: String
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            Text(bodyText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(.label))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 260, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
}
