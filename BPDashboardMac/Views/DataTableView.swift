import SwiftUI

struct DataTableView: View {
    @ObservedObject var viewModel: DashboardViewModel

    private let colWidth: CGFloat  = 32
    private let rowHeight: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            // SYS row
            HStack(spacing: 0) {
                ForEach(viewModel.allDays, id: \.self) { day in
                    let avg = sysAvg(for: day)
                    Text(avg == nil ? "—" : "\(avg!)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(sysColor(avg))
                        .frame(width: colWidth, height: rowHeight)
                        .background(sysBackground(avg))
                }
            }

            // DIA row
            HStack(spacing: 0) {
                ForEach(viewModel.allDays, id: \.self) { day in
                    let avg = diaAvg(for: day)
                    Text(avg == nil ? "—" : "\(avg!)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(diaColor(avg))
                        .frame(width: colWidth, height: rowHeight)
                        .background(diaBackground(avg))
                }
            }

            // PULSE row
            HStack(spacing: 0) {
                ForEach(viewModel.allDays, id: \.self) { day in
                    let avg = pulseAvg(for: day)
                    Text(avg == nil ? "—" : "\(avg!)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.purple)
                        .frame(width: colWidth, height: rowHeight)
                }
            }
        }
    }

    // MARK: - Averages

    private func sysAvg(for day: Date) -> Int? {
        guard let r = viewModel.readingsByDay[day], !r.isEmpty else { return nil }
        return r.map(\.systolic).reduce(0, +) / r.count
    }

    private func diaAvg(for day: Date) -> Int? {
        guard let r = viewModel.readingsByDay[day], !r.isEmpty else { return nil }
        return r.map(\.diastolic).reduce(0, +) / r.count
    }

    private func pulseAvg(for day: Date) -> Int? {
        guard let r = viewModel.readingsByDay[day], !r.isEmpty else { return nil }
        return r.map(\.pulse).reduce(0, +) / r.count
    }

    // MARK: - Colours

    private func sysColor(_ avg: Int?) -> Color {
        guard let v = avg else { return .secondary }
        return v > viewModel.document.patient.targetSystolic ? .red : .cyan
    }

    private func diaColor(_ avg: Int?) -> Color {
        guard let v = avg else { return .secondary }
        return v > viewModel.document.patient.targetDiastolic ? .orange : .brown
    }

    private func sysBackground(_ avg: Int?) -> Color {
        guard let v = avg, v > viewModel.document.patient.targetSystolic else { return .clear }
        return .red.opacity(0.08)
    }

    private func diaBackground(_ avg: Int?) -> Color {
        guard let v = avg, v > viewModel.document.patient.targetDiastolic else { return .clear }
        return .orange.opacity(0.08)
    }
}
