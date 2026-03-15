// BPChartView.swift
// InnuirBP
//
// The core Swift Charts component. Renders the blood pressure chart
// with the exact visual specification derived from the Apple Health
// iPad reference screenshots and the Chart.js prototype.
//
// Visual Specification:
// - Vertical bar segment connecting systolic (filled circle) to diastolic (rotated square/diamond)
// - Gray shaded band for the "normal" zone
// - Pink/red shaded band for the hypertension zone
// - Dashed horizontal threshold lines with right-side word-wrapped labels
// - Centered x-axis tick labels (half-period padding on each side)
// - Y-axis labels on the right side

import SwiftUI
import Charts

// MARK: - BP Chart View

struct BPChartView: View {

    // MARK: - Input

    let dataPoints: [BPDataPoint]
    let guideline: ClinicalGuidelineDocument?
    let timeRange: BPTimeRange
    let xDomain: ClosedRange<Date>
    let yDomain: ClosedRange<Double>

    // MARK: - Interaction State

    @State private var selectedPoint: BPDataPoint?
    @State private var tooltipPosition: CGPoint = .zero

    // MARK: - Body

    var body: some View {
        Chart {
            // ── 1. Clinical Background Bands ──────────────────────────────
            if let doc = guideline {
                ForEach(doc.chartBands, id: \.id) { band in
                    RectangleMark(
                        xStart: .value("Start", xDomain.lowerBound),
                        xEnd: .value("End", xDomain.upperBound),
                        yStart: .value("Min", band.yMin),
                        yEnd: .value("Max", band.yMax)
                    )
                    .foregroundStyle(band.swiftUIColor)
                }
            }

            // ── 2. Threshold Dashed Lines ──────────────────────────────────
            if let doc = guideline {
                ForEach(doc.thresholdLines, id: \.value) { line in
                    RuleMark(y: .value("Threshold", line.value))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(line.swiftUIColor)
                        .annotation(position: .trailing, alignment: .leading) {
                            thresholdLabel(line.label)
                        }
                }
            }

            // ── 3. BP Segment Marks (vertical bar + circle + diamond) ──────
            ForEach(dataPoints) { point in
                // Vertical connecting line
                RuleMark(
                    x: .value("Date", point.date),
                    yStart: .value("Diastolic", point.diastolic),
                    yEnd: .value("Systolic", point.systolic)
                )
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .foregroundStyle(segmentColor(for: point))

                // Systolic — filled circle
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Systolic", point.systolic)
                )
                .symbol(.circle)
                .symbolSize(28)
                .foregroundStyle(segmentColor(for: point))

                // Diastolic — rotated square (diamond)
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Diastolic", point.diastolic)
                )
                .symbol(.diamond)
                .symbolSize(24)
                .foregroundStyle(segmentColor(for: point))
            }

            // ── 4. Selected Point Crosshair ────────────────────────────────
            if let sel = selectedPoint {
                RuleMark(x: .value("Selected", sel.date))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Color.primary.opacity(0.2))
            }
        }
        // ── X-Axis Configuration ───────────────────────────────────────────
        .chartXAxis {
            AxisMarks(values: xAxisValues()) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(.systemGray5))
                AxisTick(stroke: StrokeStyle(lineWidth: 0))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(xAxisLabel(for: date))
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
            }
        }
        // ── Y-Axis Configuration ───────────────────────────────────────────
        .chartYAxis {
            AxisMarks(position: .trailing, values: yAxisValues()) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(.systemGray5))
                AxisTick(stroke: StrokeStyle(lineWidth: 0))
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text("\(Int(val))")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
            }
        }
        // ── Domain ─────────────────────────────────────────────────────────
        .chartXScale(domain: xDomain)
        .chartYScale(domain: yDomain)
        // ── Interaction ────────────────────────────────────────────────────
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plotFrame = proxy.plotFrame else { return }
                                let x = value.location.x - geo[plotFrame].origin.x
                                if let date = proxy.value(atX: x, as: Date.self) {
                                    selectedPoint = closestPoint(to: date)
                                    tooltipPosition = value.location
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.3)) {
                                    selectedPoint = nil
                                }
                            }
                    )
            }
        }
        // ── Tooltip Overlay ────────────────────────────────────────────────
        .overlay(alignment: .topLeading) {
            if let sel = selectedPoint {
                BPTooltipView(point: sel, timeRange: timeRange)
                    .offset(x: max(8, min(tooltipPosition.x - 60, 200)),
                            y: 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeInOut(duration: 0.15), value: sel.id)
            }
        }
    }

    // MARK: - Axis Helpers

    private func xAxisValues() -> [Date] {
        let calendar = Calendar.current
        switch timeRange {
        case .day:
            // Ticks at 0h, 4h, 8h, 12h, 16h, 20h
            let start = calendar.startOfDay(for: Date())
            return (0..<6).compactMap { calendar.date(byAdding: .hour, value: $0 * 4, to: start) }
        case .week:
            // Ticks at noon of each day
            let today = calendar.startOfDay(for: Date())
            return (-6...0).compactMap {
                let day = calendar.date(byAdding: .day, value: $0, to: today)!
                return calendar.date(byAdding: .hour, value: 12, to: day)
            }
        case .month:
            // Ticks every 5 days
            let today = calendar.startOfDay(for: Date())
            return stride(from: -30, through: 0, by: 5).compactMap {
                calendar.date(byAdding: .day, value: $0, to: today)
            }
        case .sixMonth:
            // Ticks at the 15th of each of the last 6 months
            let today = Date()
            return (0..<6).reversed().compactMap {
                let month = calendar.date(byAdding: .month, value: -$0, to: today)!
                var comps = calendar.dateComponents([.year, .month], from: month)
                comps.day = 15
                return calendar.date(from: comps)
            }
        case .year:
            // Ticks at the 15th of each of the last 12 months
            let today = Date()
            return (0..<12).reversed().compactMap {
                let month = calendar.date(byAdding: .month, value: -$0, to: today)!
                var comps = calendar.dateComponents([.year, .month], from: month)
                comps.day = 15
                return calendar.date(from: comps)
            }
        }
    }

    private func xAxisLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        switch timeRange {
        case .day:
            formatter.dateFormat = "h a"   // "8 AM", "12 PM"
            return formatter.string(from: date)
        case .week:
            formatter.dateFormat = "EEE"   // "Mon", "Tue"
            return String(formatter.string(from: date).prefix(3))
        case .month:
            formatter.dateFormat = "d"     // "1", "15"
            return formatter.string(from: date)
        case .sixMonth:
            formatter.dateFormat = "MMM"   // "Oct", "Nov"
            return formatter.string(from: date)
        case .year:
            formatter.dateFormat = "MMMMM" // Single letter: "J", "F", "M"
            return formatter.string(from: date)
        }
    }

    private func yAxisValues() -> [Double] {
        let min = Int(yDomain.lowerBound)
        let max = Int(yDomain.upperBound)
        return stride(from: min, through: max, by: 20).map { Double($0) }
    }

    // MARK: - Color Logic

    private func segmentColor(for point: BPDataPoint) -> Color {
        // A reading is red if it falls in the hypertension zone per the active guideline.
        guard let doc = guideline else { return Color(.systemRed) }
        let isHypertensive = doc.stages.first(where: {
            $0.id.contains("stage") || $0.id.contains("grade") || $0.id.contains("hypertension")
        })?.contains(systolic: point.systolic, diastolic: point.diastolic) ?? false

        return isHypertensive ? Color(.systemRed) : Color(.label)
    }

    // MARK: - Tooltip Helpers

    private func closestPoint(to date: Date) -> BPDataPoint? {
        dataPoints.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    // MARK: - Threshold Label

    @ViewBuilder
    private func thresholdLabel(_ text: String) -> some View {
        // Word-wrap "Below 120" → two lines, "And" stays single line.
        let parts = text.split(separator: " ", maxSplits: 1)
        VStack(alignment: .leading, spacing: 0) {
            if parts.count == 2 {
                Text(parts[0])
                Text(parts[1])
            } else {
                Text(text)
            }
        }
        .font(.system(size: 11, weight: .regular))
        .foregroundStyle(Color(.secondaryLabel))
        .padding(.leading, 4)
    }
}

// MARK: - Tooltip View

struct BPTooltipView: View {
    let point: BPDataPoint
    let timeRange: BPTimeRange

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        var label = formatter.string(from: point.date)
        if timeRange == .day {
            let timeFmt = DateFormatter()
            timeFmt.dateFormat = "h:mm a"
            label += " · \(timeFmt.string(from: point.date))"
        }
        return label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(dateLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(.secondaryLabel))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(point.systolic))/\(Int(point.diastolic))")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundStyle(Color(.label))
                Text("mmHg")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(.secondaryLabel))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        )
    }
}
