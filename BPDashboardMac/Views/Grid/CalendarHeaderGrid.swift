import SwiftUI

struct CalendarHeaderGrid: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            monthRow
            weekRow
            dayRow
            dowRow
        }
    }

    private var monthRow: some View {
        HStack(spacing: 0) {
            ForEach(monthSpans, id: \.0) { (date, span) in
                let formatter: DateFormatter = {
                    let f = DateFormatter()
                    f.dateFormat = "MMM yy"
                    return f
                }()
                Text(formatter.string(from: date).uppercased())
                    .font(.caption.bold())
                    .frame(width: CGFloat(span) * GridConstants.colWidth, height: GridConstants.monthRowHeight, alignment: .leading)
                    .padding(.leading, 4)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            }
        }
    }

    private var weekRow: some View {
        HStack(spacing: 0) {
            ForEach(weekSpans, id: \.0) { (date, span) in
                let weekNum = Calendar.current.component(.weekOfYear, from: date)
                Text("W\(weekNum)")
                    .font(.caption)
                    .frame(width: CGFloat(span) * GridConstants.colWidth, height: GridConstants.weekRowHeight, alignment: .leading)
                    .padding(.leading, 4)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            }
        }
    }

    private var dayRow: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.allDays, id: \.self) { day in
                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.caption)
                    .frame(width: GridConstants.colWidth, height: GridConstants.dayRowHeight)
                    .border(Color.gray.opacity(0.2), width: 0.5)
            }
        }
    }

    private var dowRow: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.allDays, id: \.self) { day in
                let formatter: DateFormatter = {
                    let f = DateFormatter()
                    f.dateFormat = "EEE"
                    return f
                }()
                let isWeekend = Calendar.current.isDateInWeekend(day)
                Text(String(formatter.string(from: day).prefix(2)).uppercased())
                    .font(.caption2)
                    .frame(width: GridConstants.colWidth, height: GridConstants.dowRowHeight)
                    .opacity(isWeekend ? 0.4 : 1.0)
                    .border(Color.gray.opacity(0.2), width: 0.5)
            }
        }
    }

    private var monthSpans: [(Date, Int)] {
        spans(groupBy: { Calendar.current.component(.month, from: $0) })
    }

    private var weekSpans: [(Date, Int)] {
        spans(groupBy: { Calendar.current.component(.weekOfYear, from: $0) })
    }

    private func spans(groupBy key: (Date) -> Int) -> [(Date, Int)] {
        var result: [(Date, Int)] = []
        var currentKey: Int? = nil
        var currentStart: Date? = nil
        var count = 0
        for day in viewModel.allDays {
            let k = key(day)
            if k == currentKey {
                count += 1
            } else {
                if let start = currentStart { result.append((start, count)) }
                currentKey = k
                currentStart = day
                count = 1
            }
        }
        if let start = currentStart { result.append((start, count)) }
        return result
    }
}
