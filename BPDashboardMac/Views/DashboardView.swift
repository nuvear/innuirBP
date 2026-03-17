import SwiftUI

struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel
    @State private var scrollPosition: CGPoint = .zero

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(viewModel: viewModel)
                .background(.bar)

            Divider()

            HStack(alignment: .top, spacing: 0) {
                FixedLeftPanel(viewModel: viewModel)
                Divider()
                ScrollableRightPanel(viewModel: viewModel, scrollPosition: $scrollPosition)
            }
        }
        .navigationTitle("BP Dashboard — \(viewModel.document.patient.name)")
    }
}

// MARK: - Fixed Left Panel
struct FixedLeftPanel: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MONTH").frame(height: GridConstants.monthRowHeight)
            Text("WEEK").frame(height: GridConstants.weekRowHeight)
            Text("DAY").frame(height: GridConstants.dayRowHeight)
            Text("DOW").frame(height: GridConstants.dowRowHeight)
            YAxisView(viewModel: viewModel).frame(height: GridConstants.chartRowHeight)
            Text("NOTES").frame(height: GridConstants.notesRowHeight)
            Text("MEDS").frame(height: GridConstants.medsRowHeight)
            Text("SYS").frame(height: GridConstants.sysRowHeight).foregroundStyle(.cyan)
            Text("DIA").frame(height: GridConstants.diaRowHeight).foregroundStyle(.brown)
            Text("PULSE").frame(height: GridConstants.pulseRowHeight).foregroundStyle(.purple)
            Spacer()
        }
        .font(.caption.bold())
        .padding(.leading, 8)
        .frame(width: GridConstants.fixedWidth)
        .background(.background.shadow(.inner(radius: 1, x: -1)))
    }
}

// MARK: - Scrollable Right Panel
struct ScrollableRightPanel: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var scrollPosition: CGPoint

    var totalWidth: CGFloat {
        CGFloat(viewModel.allDays.count) * GridConstants.colWidth
    }

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            VStack(spacing: 0) {
                CalendarHeaderGrid(viewModel: viewModel)
                BPChartGrid(viewModel: viewModel)
                AnnotationGrid(viewModel: viewModel)
                MedicationGrid(viewModel: viewModel)
                DataGrid(viewModel: viewModel)
            }
            .frame(width: totalWidth)
            .background(GeometryReader { geo in
                Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("scroll")).origin)
            })
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            self.scrollPosition = value
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}
