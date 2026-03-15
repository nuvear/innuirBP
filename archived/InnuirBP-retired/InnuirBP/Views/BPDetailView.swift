// BPDetailView.swift
// InnuirBP
//
// The main Blood Pressure detail screen — the primary chart view.
// Layout is based on the Apple Health iPad reference screenshots (2.jpg, 3.jpg):
//
// ┌─────────────────────────────────────────────────────────────────┐
// │  < Back         Blood Pressure                              + i │
// │                                                                 │
// │     [Day] [Week] [Month] [6 Months] [Year]                     │
// │                                                                 │
// │  ● SYSTOLIC          ◆ DIASTOLIC                               │
// │  120–130             78–88  mmHg                               │
// │  8–14 Mar 2026                                                  │
// │                                                                 │
// │  ┌──────────────────────────────────────────────────────────┐  │
// │  │                  Swift Charts BP Chart                   │  │
// │  └──────────────────────────────────────────────────────────┘  │
// │                                                                 │
// │  [Hypertension - Stage 1          1 day] [Show All BP Ranges]  │
// │                                                                 │
// │  Blood Pressure Log                              Options >      │
// │  ┌──────────────────────────────────────────────────────────┐  │
// │  │  Measurements Taken: 2   Days Left: 23                   │  │
// │  │  Calendar grid...                                        │  │
// │  └──────────────────────────────────────────────────────────┘  │
// └─────────────────────────────────────────────────────────────────┘

import SwiftUI
import SwiftData
import Charts

struct BPDetailView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BPReading.timestamp, order: .forward) private var readings: [BPReading]

    // MARK: - State

    @State private var viewModel = BPChartViewModel()
    @State private var showManualEntry = false
    @State private var showGuidelineInfo = false
    @State private var showAllRanges = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Segmented Time Range Control ───────────────────────────
                BPSegmentedControl(
                    options: BPTimeRange.allCases,
                    selected: Binding(
                        get: { viewModel.selectedRange },
                        set: { viewModel.selectedRange = $0 }
                    )
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)

                // ── Stats Header ───────────────────────────────────────────
                BPStatsHeaderView(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // ── Chart ──────────────────────────────────────────────────
                BPChartView(
                    dataPoints: viewModel.visibleDataPoints,
                    guideline: viewModel.guidelineDocument,
                    timeRange: viewModel.selectedRange,
                    xDomain: viewModel.xDomain,
                    yDomain: viewModel.yDomain
                )
                .frame(height: 280)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                // ── Stage Summary Bar ──────────────────────────────────────
                BPStageSummaryBar(viewModel: viewModel, showAllRanges: $showAllRanges)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)

                // ── Blood Pressure Log ─────────────────────────────────────
                BPLogSection(readings: readings)
                    .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Blood Pressure")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // AHA / ESC guideline toggle
                    BPSegmentedControl(
                        options: GuidelineType.allCases,
                        selected: Binding(
                            get: { viewModel.selectedGuideline },
                            set: { viewModel.selectedGuideline = $0 }
                        )
                    )
                    .frame(width: 100)

                    // Info button
                    Button {
                        showGuidelineInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 17))
                            .foregroundStyle(Color(.secondaryLabel))
                    }

                    // Add reading button
                    Button {
                        showManualEntry = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
        }
        .sheet(isPresented: $showManualEntry) {
            ManualEntryView()
        }
        .sheet(isPresented: $showGuidelineInfo) {
            GuidelineInfoView(guideline: viewModel.guidelineDocument)
        }
        .sheet(isPresented: $showAllRanges) {
            AllBPRangesView(
                viewModel: viewModel,
                guideline: viewModel.guidelineDocument
            )
        }
        .onAppear {
            viewModel.load(readings: readings)
        }
        .onChange(of: readings) { _, newReadings in
            viewModel.load(readings: newReadings)
        }
    }
}

// MARK: - Stats Header

struct BPStatsHeaderView: View {
    let viewModel: BPChartViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 40) {
                // Systolic
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(.systemRed))
                            .frame(width: 8, height: 8)
                        Text("SYSTOLIC")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(.secondaryLabel))
                            .tracking(0.07)
                    }
                    Text(viewModel.systolicRangeLabel)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color(.label))
                }

                // Diastolic
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        // Diamond indicator
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 7))
                            .foregroundStyle(Color(.systemRed))
                        Text("DIASTOLIC")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(.secondaryLabel))
                            .tracking(0.07)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(viewModel.diastolicRangeLabel)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(Color(.label))
                        Text("mmHg")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
            }

            // Date range
            Text(viewModel.dateRangeLabel)
                .font(.system(size: 13))
                .foregroundStyle(Color(.secondaryLabel))
        }
    }
}

// MARK: - Stage Summary Bar

struct BPStageSummaryBar: View {
    let viewModel: BPChartViewModel
    @Binding var showAllRanges: Bool

    private var dominantStage: (stage: ClinicalStage, count: Int)? {
        viewModel.stageCounts.max(by: { $0.count < $1.count })
    }

    var body: some View {
        HStack {
            if let dominant = dominantStage, dominant.count > 0 {
                Text(dominant.stage.name)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(.label))
                Spacer()
                Text(countLabel(dominant.count))
                    .font(.system(size: 15))
                    .foregroundStyle(Color(.secondaryLabel))
            }

            Spacer()

            Button("Show All Blood Pressure Ranges") {
                showAllRanges = true
            }
            .font(.system(size: 15))
            .foregroundStyle(Color(.systemBlue))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }

    private func countLabel(_ count: Int) -> String {
        switch viewModel.selectedRange {
        case .day:      return count == 1 ? "1 reading" : "\(count) readings"
        case .week:     return count == 1 ? "1 day" : "\(count) days"
        case .month:    return count == 1 ? "1 week" : "\(count) weeks"
        case .sixMonth, .year: return count == 1 ? "1 month" : "\(count) months"
        }
    }
}

// MARK: - Guideline Info View

struct GuidelineInfoView: View {
    let guideline: ClinicalGuidelineDocument?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let doc = guideline {
                        Text(doc.description)
                            .font(.system(size: 15))
                            .foregroundStyle(Color(.secondaryLabel))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        ForEach(doc.stages) { stage in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(stage.name)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(Color(.label))
                                Text(stage.description)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                            .padding(.horizontal, 20)
                        }

                        Text(doc.source)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(.tertiaryLabel))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Blood Pressure Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - All BP Ranges View

struct AllBPRangesView: View {
    let viewModel: BPChartViewModel
    let guideline: ClinicalGuidelineDocument?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let doc = guideline {
                    ForEach(doc.stages) { stage in
                        let count = viewModel.stageCounts.first(where: { $0.stage.id == stage.id })?.count ?? 0
                        HStack {
                            Circle()
                                .fill(stage.swiftUIColor)
                                .frame(width: 10, height: 10)
                            Text(stage.name)
                                .font(.system(size: 15))
                            Spacer()
                            Text("\(count)")
                                .font(.system(size: 15))
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                    }
                }
            }
            .navigationTitle("Blood Pressure Ranges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
