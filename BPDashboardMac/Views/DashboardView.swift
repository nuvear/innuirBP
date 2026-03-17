import SwiftUI

struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel

    private let fixedWidth: CGFloat  = 120
    private let colWidth: CGFloat    = 32
    private let chartHeight: CGFloat = 300
    private let rowHeight: CGFloat   = 20
    private let timelineHeight: CGFloat = 32

    var totalScrollWidth: CGFloat {
        CGFloat(viewModel.allDays.count) * colWidth
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Toolbar ────────────────────────────────────────────────────
            ToolbarView(viewModel: viewModel)
                .background(.bar)

            Divider()

            // ── Main Layout ────────────────────────────────────────────────
            HStack(alignment: .top, spacing: 0) {

                // Fixed left panel
                VStack(alignment: .leading, spacing: 0) {
                    // Calendar row labels
                    Group {
                        Text("MONTH").frame(height: rowHeight)
                        Text("WEEK").frame(height: rowHeight)
                        Text("DAY").frame(height: rowHeight)
                        Text("DOW").frame(height: rowHeight)
                    }
                    .font(.caption.bold())
                    .padding(.leading, 8)

                    // Y-axis label (rotated)
                    ZStack {
                        Text("BLOOD PRESSURE (MMHG)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: fixedWidth, height: chartHeight)

                    // Timeline row labels
                    Group {
                        Text("NOTES").frame(height: timelineHeight)
                        Text("MEDS").frame(height: timelineHeight)
                        Text("SYS").frame(height: rowHeight).foregroundStyle(.cyan)
                        Text("DIA").frame(height: rowHeight).foregroundStyle(.brown)
                        Text("PULSE").frame(height: rowHeight).foregroundStyle(.purple)
                    }
                    .font(.caption.bold())
                    .padding(.leading, 8)

                    Spacer()
                }
                .frame(width: fixedWidth)
                .background(.background)

                Divider()

                // Scrollable right panel
                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(spacing: 0) {
                        ScrollableCalendarHeader(viewModel: viewModel)
                        BPChartView(viewModel: viewModel)
                            .frame(width: totalScrollWidth, height: chartHeight)
                        AnnotationTimelineView(viewModel: viewModel)
                        MedicationTimelineView(viewModel: viewModel)
                        DataTableView(viewModel: viewModel)
                    }
                    .frame(width: totalScrollWidth)
                }
            }
        }
        .navigationTitle("BP Dashboard — \(viewModel.document.patient.name)")
    }
}
