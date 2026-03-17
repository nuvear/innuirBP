import SwiftUI

struct DataGrid: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(viewModel.allDays, id: \.self) {
                    let avg = sysAvg(for: $0)
                    Text(avg == nil ? "—" : "\(avg!)")
                        .foregroundStyle(sysColor(avg))
                        .frame(width: GridConstants.colWidth, height: GridConstants.sysRowHeight)
                }
            }
            HStack(spacing: 0) {
                ForEach(viewModel.allDays, id: \.self) {
                    let avg = diaAvg(for: $0)
                    Text(avg == nil ? "—" : "\(avg!)")
                        .foregroundStyle(diaColor(avg))
                        .frame(width: GridConstants.colWidth, height: GridConstants.diaRowHeight)
                }
            }
            HStack(spacing: 0) {
                ForEach(viewModel.allDays, id: \.self) {
                    let avg = pulseAvg(for: $0)
                    Text(avg == nil ? "—" : "\(avg!)")
                        .foregroundStyle(.purple)
                        .frame(width: GridConstants.colWidth, height: GridConstants.pulseRowHeight)
                }
            }
        }
        .font(.system(size: 9, design: .monospaced))
    }

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

    private func sysColor(_ avg: Int?) -> Color {
        guard let v = avg else { return .secondary }
        return v > viewModel.document.patient.targetSystolic ? .red : .cyan
    }

    private func diaColor(_ avg: Int?) -> Color {
        guard let v = avg else { return .secondary }
        return v > viewModel.document.patient.targetDiastolic ? .orange : .brown
    }
}
