// BPChartViewModel.swift
// InnuirBP
//
// The ViewModel for the BP chart. Aggregates raw BPReading objects
// from SwiftData into display-ready data structures for BPChartView.

import Foundation
import SwiftUI
import Observation

// MARK: - Time Range

/// The five time range options for the chart, matching Apple Health exactly.
enum BPTimeRange: String, CaseIterable, Identifiable {
    case day      = "Day"
    case week     = "Week"
    case month    = "Month"
    case sixMonth = "6 Months"
    case year     = "Year"

    var id: String { rawValue }
}

// MARK: - Aggregated Data Point

/// A single data point prepared for rendering in the chart.
/// For Day/Week/Month views, this is one reading.
/// For 6-Month/Year views, this is a monthly average.
struct BPDataPoint: Identifiable {
    let id: UUID
    let date: Date
    let systolic: Double
    let diastolic: Double
    let isAggregate: Bool   // true = monthly average, false = individual reading
}

// MARK: - Chart ViewModel

@Observable
final class BPChartViewModel {

    // MARK: - Published State

    var selectedRange: BPTimeRange = .week {
        didSet { recompute() }
    }

    var selectedGuideline: GuidelineType = .aha {
        didSet { recomputeStages() }
    }

    /// The data points currently visible in the chart.
    var visibleDataPoints: [BPDataPoint] = []

    /// The active guideline document (AHA or ESC).
    var guidelineDocument: ClinicalGuidelineDocument?

    /// Stage counts for the currently visible data.
    var stageCounts: [(stage: ClinicalStage, count: Int)] = []

    /// The currently highlighted (active) stage in the sidebar.
    var activeStageID: String?

    /// The date range label shown in the stats header (e.g., "8–14 Mar 2026").
    var dateRangeLabel: String = ""

    /// The systolic range string (e.g., "120–130").
    var systolicRangeLabel: String = ""

    /// The diastolic range string (e.g., "78–88").
    var diastolicRangeLabel: String = ""

    /// The x-axis domain (min, max) for the chart.
    var xDomain: ClosedRange<Date> = Date()...Date()

    /// The y-axis domain (min, max) for the chart.
    var yDomain: ClosedRange<Double> = 60...180

    // MARK: - Private State

    private var allReadings: [BPReading] = []
    private let calendar = Calendar.current

    // MARK: - Data Loading

    /// Loads a new set of readings and triggers a full recompute.
    func load(readings: [BPReading]) {
        self.allReadings = readings.sorted()
        guidelineDocument = GuidelineLoader.shared.load(selectedGuideline)
        recompute()
    }

    // MARK: - Recompute

    private func recompute() {
        let (start, end) = dateRange(for: selectedRange)
        let filtered = allReadings.filter { $0.timestamp >= start && $0.timestamp <= end }

        // For Year and 6-Month views, aggregate into monthly averages.
        if selectedRange == .year || selectedRange == .sixMonth {
            visibleDataPoints = aggregateByMonth(readings: filtered)
        } else {
            visibleDataPoints = filtered.map {
                BPDataPoint(id: $0.id, date: $0.timestamp, systolic: $0.systolic, diastolic: $0.diastolic, isAggregate: false)
            }
        }

        updateXDomain(start: start, end: end)
        updateYDomain()
        updateLabels(readings: filtered, start: start, end: end)
        recomputeStages()
    }

    private func recomputeStages() {
        guidelineDocument = GuidelineLoader.shared.load(selectedGuideline)
        guard let doc = guidelineDocument else { return }

        let (start, end) = dateRange(for: selectedRange)
        let filtered = allReadings.filter { $0.timestamp >= start && $0.timestamp <= end }

        // Count readings per stage.
        stageCounts = doc.stages.map { stage in
            let count = filtered.filter {
                stage.contains(systolic: $0.systolic, diastolic: $0.diastolic)
            }.count
            return (stage: stage, count: count)
        }

        // Determine the most prevalent stage for the active highlight.
        activeStageID = stageCounts.max(by: { $0.count < $1.count })?.stage.id
    }

    // MARK: - Date Range Calculation

    private func dateRange(for range: BPTimeRange) -> (Date, Date) {
        let now = Date()
        let end = calendar.startOfDay(for: now).addingTimeInterval(86400) // end of today
        let start: Date

        switch range {
        case .day:
            start = calendar.startOfDay(for: now)
        case .week:
            start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))!
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: calendar.startOfDay(for: now))!
        case .sixMonth:
            start = calendar.date(byAdding: .month, value: -6, to: calendar.startOfDay(for: now))!
        case .year:
            start = calendar.date(byAdding: .year, value: -1, to: calendar.startOfDay(for: now))!
        }
        return (start, end)
    }

    // MARK: - Aggregation

    private func aggregateByMonth(readings: [BPReading]) -> [BPDataPoint] {
        let grouped = Dictionary(grouping: readings) {
            calendar.dateComponents([.year, .month], from: $0.timestamp)
        }

        return grouped.compactMap { (components, readings) -> BPDataPoint? in
            guard !readings.isEmpty,
                  let date = calendar.date(from: components) else { return nil }
            let avgSys = readings.map(\.systolic).reduce(0, +) / Double(readings.count)
            let avgDia = readings.map(\.diastolic).reduce(0, +) / Double(readings.count)
            // Pin to the 15th of the month for centered x-axis positioning.
            let centeredDate = calendar.date(byAdding: .day, value: 14, to: date) ?? date
            return BPDataPoint(id: UUID(), date: centeredDate, systolic: avgSys, diastolic: avgDia, isAggregate: true)
        }.sorted { $0.date < $1.date }
    }

    // MARK: - Domain Calculation

    private func updateXDomain(start: Date, end: Date) {
        // Add half-period padding on each side so data points appear centered
        // under their x-axis labels, matching Apple Health's visual alignment.
        let halfPeriod: TimeInterval
        switch selectedRange {
        case .day:      halfPeriod = 2 * 3600
        case .week:     halfPeriod = 12 * 3600
        case .month:    halfPeriod = 12 * 3600
        case .sixMonth: halfPeriod = 15 * 86400
        case .year:     halfPeriod = 15 * 86400
        }
        xDomain = (start - halfPeriod)...(end + halfPeriod)
    }

    private func updateYDomain() {
        let allSys = visibleDataPoints.map(\.systolic)
        let allDia = visibleDataPoints.map(\.diastolic)
        let minVal = min(allDia.min() ?? 60, 60)
        let maxVal = max(allSys.max() ?? 180, 160)
        // Round to nearest 10 with 10-unit padding.
        let yMin = max(60, (floor(minVal / 10) * 10) - 10)
        let yMax = (ceil(maxVal / 10) * 10) + 10
        yDomain = yMin...yMax
    }

    // MARK: - Label Computation

    private func updateLabels(readings: [BPReading], start: Date, end: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"

        let sysValues = readings.map(\.systolic)
        let diaValues = readings.map(\.diastolic)

        if readings.isEmpty {
            systolicRangeLabel = "--"
            diastolicRangeLabel = "--"
            dateRangeLabel = formatter.string(from: start)
        } else {
            let sysMin = Int(sysValues.min()!)
            let sysMax = Int(sysValues.max()!)
            let diaMin = Int(diaValues.min()!)
            let diaMax = Int(diaValues.max()!)

            systolicRangeLabel = sysMin == sysMax ? "\(sysMin)" : "\(sysMin)–\(sysMax)"
            diastolicRangeLabel = diaMin == diaMax ? "\(diaMin)" : "\(diaMin)–\(diaMax)"

            let startStr = formatter.string(from: readings.first!.timestamp)
            let endStr = formatter.string(from: readings.last!.timestamp)
            dateRangeLabel = startStr == endStr ? startStr : "\(startStr) – \(endStr)"
        }
    }
}
