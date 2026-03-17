import SwiftUI
import Charts

struct BPChartView: View {
    let readings: [BPReading]
    // Add other necessary properties like guidelines, date range etc.

    var body: some View {
        Chart(readings) { reading in
            PointMark(
                x: .value("Time", reading.timestamp),
                y: .value("Systolic", reading.systolic)
            )
            .foregroundStyle(.blue)
            
            PointMark(
                x: .value("Time", reading.timestamp),
                y: .value("Diastolic", reading.diastolic)
            )
            .foregroundStyle(.green)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}
