import SwiftUI

struct MedicationGrid: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(Color.clear).frame(height: GridConstants.medsRowHeight)

            ForEach(viewModel.document.medications) { med in
                let startIdx = max(0, dayIndex(for: med.start))
                let endIdx   = min(viewModel.allDays.count - 1, dayIndex(for: med.end))
                guard endIdx >= startIdx else { continue }
                let barWidth = CGFloat(endIdx - startIdx + 1) * GridConstants.colWidth

                ZStack(alignment: .leading) {
                    Capsule().fill(med.swiftUIColor).frame(width: barWidth, height: 22)
                    Text("\(med.name) \(med.dose)")
                        .font(.caption.bold()).foregroundStyle(.white).lineLimit(1)
                        .padding(.leading, 10).frame(width: barWidth, alignment: .leading)
                }
                .offset(x: CGFloat(startIdx) * GridConstants.colWidth)
            }
        }
    }

    private func dayIndex(for date: Date) -> Int {
        let cal = Calendar.current
        let comps = cal.dateComponents([.day], from: viewModel.dateRange.lowerBound, to: date)
        return comps.day ?? 0
    }
}
