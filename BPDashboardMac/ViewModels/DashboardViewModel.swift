import Foundation
import SwiftUI

// MARK: - View State Enums

enum BPTimeRange: String, CaseIterable, Identifiable {
    case week  = "Week"
    case month = "Month"
    case year  = "Year"
    var id: String { rawValue }
}

enum ClinicalStandard: String, CaseIterable, Identifiable {
    case none    = "None"
    case acc_aha = "ACC/AHA"
    case esc_esh = "ESC/ESH"
    case jsh     = "JSH"
    case ish     = "ISH"
    var id: String { rawValue }
}

// MARK: - DashboardViewModel

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var document: BPDataDocument

    // Toolbar state
    @Published var selectedView: BPTimeRange     = .month
    @Published var showSmoothing: Bool           = true
    @Published var selectedStandard: ClinicalStandard = .none

    // ── Derived properties ────────────────────────────────────────────────

    /// Full date range covered by the data (start of first day → end of last day).
    var dateRange: ClosedRange<Date> {
        let cal = Calendar.current
        let timestamps = document.readings.map(\.timestamp).filter { $0 != Date.distantPast }
        guard let first = timestamps.min(), let last = timestamps.max() else {
            let now = Date()
            return now...now
        }
        let start = cal.startOfDay(for: first)
        let end   = cal.startOfDay(for: last)
        return start...end
    }

    /// Every calendar day in the date range as an array of `Date` values.
    var allDays: [Date] {
        let cal = Calendar.current
        var days: [Date] = []
        var current = dateRange.lowerBound
        let end = dateRange.upperBound
        while current <= end {
            days.append(current)
            current = cal.date(byAdding: .day, value: 1, to: current)!
        }
        return days
    }

    /// Readings grouped by the start-of-day of their timestamp.
    var readingsByDay: [Date: [BPReading]] {
        Dictionary(grouping: document.readings.filter { $0.timestamp != Date.distantPast }) { reading in
            Calendar.current.startOfDay(for: reading.timestamp)
        }
    }

    // ── LOWESS Smoothing ──────────────────────────────────────────────────

    /// Smoothed systolic values keyed by day index in `allDays`.
    var smoothedSystolic: [Double] {
        lowess(values: dailyAverages(keyPath: \.systolic), bandwidth: 0.15)
    }

    /// Smoothed diastolic values keyed by day index in `allDays`.
    var smoothedDiastolic: [Double] {
        lowess(values: dailyAverages(keyPath: \.diastolic), bandwidth: 0.15)
    }

    // ── Clinical Standard Goal Bands ─────────────────────────────────────

    struct GoalBand {
        let label: String
        let sysMin: Double
        let sysMax: Double
        let diaMin: Double
        let diaMax: Double
        let color: Color
    }

    var goalBands: [GoalBand] {
        switch selectedStandard {
        case .none:    return []
        case .acc_aha: return accAhaBands
        case .esc_esh: return escEshBands
        case .jsh:     return jshBands
        case .ish:     return ishBands
        }
    }

    // ── Initialiser ──────────────────────────────────────────────────────

    init(document: BPDataDocument) {
        self.document = document
    }

    // ── Private Helpers ───────────────────────────────────────────────────

    private func dailyAverages(keyPath: KeyPath<BPReading, Int>) -> [Double] {
        allDays.map { day in
            guard let readings = readingsByDay[day], !readings.isEmpty else { return Double.nan }
            return Double(readings.map { $0[keyPath: keyPath] }.reduce(0, +)) / Double(readings.count)
        }
    }

    /// Simplified LOWESS (locally weighted linear regression) implementation.
    /// - Parameters:
    ///   - values: Input y-values (NaN for missing days).
    ///   - bandwidth: Fraction of data used for each local fit (0–1). Default 0.15.
    private func lowess(values: [Double], bandwidth: Double = 0.15) -> [Double] {
        let n = values.count
        guard n > 2 else { return values }

        // Filter out NaN indices
        let validIndices = values.indices.filter { !values[$0].isNaN }
        guard validIndices.count > 2 else { return values }

        var smoothed = [Double](repeating: Double.nan, count: n)
        let k = max(2, Int(bandwidth * Double(validIndices.count)))

        for i in validIndices {
            // Find k nearest valid neighbours by x-distance
            let sorted = validIndices.sorted { abs($0 - i) < abs($1 - i) }
            let neighbours = Array(sorted.prefix(k))
            guard let maxDist = neighbours.map({ abs($0 - i) }).max(), maxDist > 0 else {
                smoothed[i] = values[i]
                continue
            }

            // Tricube weights
            var sumW = 0.0, sumWx = 0.0, sumWy = 0.0, sumWxx = 0.0, sumWxy = 0.0
            for j in neighbours {
                let u = Double(abs(j - i)) / Double(maxDist)
                let w = pow(1.0 - pow(u, 3), 3)
                let x = Double(j)
                let y = values[j]
                sumW   += w
                sumWx  += w * x
                sumWy  += w * y
                sumWxx += w * x * x
                sumWxy += w * x * y
            }
            let denom = sumW * sumWxx - sumWx * sumWx
            if abs(denom) < 1e-10 {
                smoothed[i] = sumWy / sumW
            } else {
                let b = (sumW * sumWxy - sumWx * sumWy) / denom
                let a = (sumWy - b * sumWx) / sumW
                smoothed[i] = a + b * Double(i)
            }
        }
        return smoothed
    }

    // ── Clinical Standard Band Definitions ───────────────────────────────

    private var accAhaBands: [GoalBand] { [
        GoalBand(label: "Normal",      sysMin: 0,   sysMax: 120, diaMin: 0,  diaMax: 80,  color: .green.opacity(0.15)),
        GoalBand(label: "Elevated",    sysMin: 120, sysMax: 130, diaMin: 0,  diaMax: 80,  color: .yellow.opacity(0.15)),
        GoalBand(label: "HT Stage I",  sysMin: 130, sysMax: 140, diaMin: 80, diaMax: 90,  color: .orange.opacity(0.20)),
        GoalBand(label: "HT Stage II", sysMin: 140, sysMax: 999, diaMin: 90, diaMax: 999, color: .red.opacity(0.20)),
    ] }

    private var escEshBands: [GoalBand] { [
        GoalBand(label: "Optimal",      sysMin: 0,   sysMax: 120, diaMin: 0,  diaMax: 80,  color: .green.opacity(0.15)),
        GoalBand(label: "Normal",       sysMin: 120, sysMax: 130, diaMin: 80, diaMax: 85,  color: .teal.opacity(0.15)),
        GoalBand(label: "High Normal",  sysMin: 130, sysMax: 140, diaMin: 85, diaMax: 90,  color: .yellow.opacity(0.15)),
        GoalBand(label: "Grade 1 HT",   sysMin: 140, sysMax: 160, diaMin: 90, diaMax: 100, color: .orange.opacity(0.20)),
        GoalBand(label: "Grade 2 HT",   sysMin: 160, sysMax: 180, diaMin: 100,diaMax: 110, color: .red.opacity(0.20)),
        GoalBand(label: "Grade 3 HT",   sysMin: 180, sysMax: 999, diaMin: 110,diaMax: 999, color: .pink.opacity(0.25)),
    ] }

    private var jshBands: [GoalBand] { [
        GoalBand(label: "Normal",       sysMin: 0,   sysMax: 120, diaMin: 0,  diaMax: 80,  color: .green.opacity(0.15)),
        GoalBand(label: "High Normal",  sysMin: 120, sysMax: 130, diaMin: 80, diaMax: 90,  color: .yellow.opacity(0.15)),
        GoalBand(label: "Elevated",     sysMin: 130, sysMax: 140, diaMin: 0,  diaMax: 90,  color: .orange.opacity(0.15)),
        GoalBand(label: "Grade I HT",   sysMin: 140, sysMax: 160, diaMin: 90, diaMax: 100, color: .orange.opacity(0.20)),
        GoalBand(label: "Grade II HT",  sysMin: 160, sysMax: 180, diaMin: 100,diaMax: 110, color: .red.opacity(0.20)),
        GoalBand(label: "Grade III HT", sysMin: 180, sysMax: 999, diaMin: 110,diaMax: 999, color: .pink.opacity(0.25)),
    ] }

    private var ishBands: [GoalBand] { [
        GoalBand(label: "Normal",      sysMin: 0,   sysMax: 130, diaMin: 0,  diaMax: 85,  color: .green.opacity(0.15)),
        GoalBand(label: "High Normal", sysMin: 130, sysMax: 140, diaMin: 85, diaMax: 90,  color: .yellow.opacity(0.15)),
        GoalBand(label: "Grade 1 HT",  sysMin: 140, sysMax: 160, diaMin: 90, diaMax: 100, color: .orange.opacity(0.20)),
        GoalBand(label: "Grade 2 HT",  sysMin: 160, sysMax: 999, diaMin: 100,diaMax: 999, color: .red.opacity(0.20)),
    ] }
}
