import SwiftUI
import Charts

struct BPChartView: View {
    @ObservedObject var viewModel: DashboardViewModel

    private let chartHeight: CGFloat = 300
    private let yMin: Double = 50
    private let yMax: Double = 200

    var body: some View {
        Chart {
            // ── 1. Goal Bands (Clinical Standard Overlay) ─────────────────
            ForEach(viewModel.goalBands, id: \.label) { band in
                RectangleMark(
                    xStart: .value("Start", viewModel.dateRange.lowerBound),
                    xEnd:   .value("End",   viewModel.dateRange.upperBound),
                    yStart: .value("SysMin", band.sysMin),
                    yEnd:   .value("SysMax", min(band.sysMax, yMax))
                )
                .foregroundStyle(band.color)
            }

            // ── 2. Target lines ───────────────────────────────────────────
            RuleMark(y: .value("Target SBP", Double(viewModel.document.patient.targetSystolic)))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 3]))
                .foregroundStyle(.cyan.opacity(0.7))
                .annotation(position: .trailing, alignment: .leading) {
                    Text("Target SBP").font(.caption2).foregroundStyle(.cyan)
                }

            RuleMark(y: .value("Target DBP", Double(viewModel.document.patient.targetDiastolic)))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 3]))
                .foregroundStyle(.brown.opacity(0.7))
                .annotation(position: .trailing, alignment: .leading) {
                    Text("Target DBP").font(.caption2).foregroundStyle(.brown)
                }

            // ── 3. LOWESS Trend Lines ─────────────────────────────────────
            if viewModel.showSmoothing {
                ForEach(Array(zip(viewModel.allDays, viewModel.smoothedSystolic).enumerated()), id: \.0) { _, pair in
                    let (day, value) = pair
                    if !value.isNaN {
                        LineMark(
                            x: .value("Date", day),
                            y: .value("Sys Trend", value)
                        )
                        .foregroundStyle(.cyan)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)
                        .accessibilityLabel("Systolic trend")
                    }
                }

                ForEach(Array(zip(viewModel.allDays, viewModel.smoothedDiastolic).enumerated()), id: \.0) { _, pair in
                    let (day, value) = pair
                    if !value.isNaN {
                        LineMark(
                            x: .value("Date", day),
                            y: .value("Dia Trend", value)
                        )
                        .foregroundStyle(.brown)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)
                        .accessibilityLabel("Diastolic trend")
                    }
                }
            }

            // ── 4. Individual Reading Scatter Dots ────────────────────────
            ForEach(viewModel.document.readings.filter { $0.timestamp != Date.distantPast }) { reading in
                // Systolic dot
                PointMark(
                    x: .value("Date", reading.timestamp),
                    y: .value("Systolic", Double(reading.systolic))
                )
                .symbolSize(28)
                .foregroundStyle(.cyan.opacity(0.55))

                // Diastolic dot
                PointMark(
                    x: .value("Date", reading.timestamp),
                    y: .value("Diastolic", Double(reading.diastolic))
                )
                .symbolSize(20)
                .foregroundStyle(.brown.opacity(0.55))

                // Pulse dot (smaller, purple)
                PointMark(
                    x: .value("Date", reading.timestamp),
                    y: .value("Pulse", Double(reading.pulse))
                )
                .symbolSize(12)
                .foregroundStyle(.purple.opacity(0.40))
            }
        }
        .chartXAxis(.hidden)   // Calendar header above handles x-axis labels
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: 20)) { value in
                AxisGridLine().foregroundStyle(.gray.opacity(0.2))
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYScale(domain: yMin...yMax)
        .frame(height: chartHeight)
    }
}
