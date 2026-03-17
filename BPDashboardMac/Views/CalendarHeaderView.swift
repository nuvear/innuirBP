
import SwiftUI

// MARK: - Fixed Left Panel Header (Row Labels)
struct FixedCalendarHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MONTH").frame(height: 20).font(.caption.bold()).padding(.horizontal, 8)
            Text("WEEK").frame(height: 20).font(.caption.bold()).padding(.horizontal, 8)
            Text("DAY").frame(height: 20).font(.caption.bold()).padding(.horizontal, 8)
            Text("DOW").frame(height: 20).font(.caption.bold()).padding(.horizontal, 8)
        }
    }
}

// MARK: - Fixed Left Panel Y-Axis
struct YAxisView: View {
    let yMin: Double = 50
    let yMax: Double = 200
    let chartHeight: CGFloat = 300
    
    var body: some View {
        Canvas { context, size in
            let tickValues: [Double] = [60, 80, 100, 120, 140, 160, 180, 200]
            for tick in tickValues {
                let y = chartHeight - CGFloat((tick - yMin) / (yMax - yMin)) * chartHeight
                let text = Text("\(Int(tick))").font(.caption).foregroundColor(.secondary)
                context.draw(text, at: CGPoint(x: size.width - 4, y: y), anchor: .trailing)
            }
        }
        .frame(height: 300)
    }
}

// MARK: - Fixed Left Panel Timeline Labels
struct FixedTimelineLabels: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NOTES").frame(height: 32).font(.caption.bold()).padding(.horizontal, 8)
            Text("MEDS").frame(height: 32).font(.caption.bold()).padding(.horizontal, 8)
            Text("SYS").frame(height: 20).font(.caption.bold()).foregroundColor(.cyan).padding(.horizontal, 8)
            Text("DIA").frame(height: 20).font(.caption.bold()).foregroundColor(.brown).padding(.horizontal, 8)
            Text("PULSE").frame(height: 20).font(.caption.bold()).foregroundColor(.purple).padding(.horizontal, 8)
        }
    }
}

// MARK: - Scrollable Calendar Header (Date Columns)
struct ScrollableCalendarHeader: View {
    @ObservedObject var viewModel: DashboardViewModel
    private let dayColumnWidth: CGFloat = 32
    
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
                    .frame(width: CGFloat(span) * dayColumnWidth, height: 20, alignment: .leading)
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
                    .frame(width: CGFloat(span) * dayColumnWidth, height: 20, alignment: .leading)
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
                    .frame(width: dayColumnWidth, height: 20)
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
                    .frame(width: dayColumnWidth, height: 20)
                    .opacity(isWeekend ? 0.4 : 1.0)
                    .border(Color.gray.opacity(0.2), width: 0.5)
            }
        }
    }
    
    // MARK: - Span Calculations
    
    /// Groups consecutive days that share the same month into (firstDate, count) tuples.
    private var monthSpans: [(Date, Int)] {
        spans(groupBy: { Calendar.current.component(.month, from: $0) })
    }
    
    /// Groups consecutive days that share the same ISO week number into (firstDate, count) tuples.
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
                if let start = currentStart {
                    result.append((start, count))
                }
                currentKey = k
                currentStart = day
                count = 1
            }
        }
        if let start = currentStart {
            result.append((start, count))
        }
        return result
    }
}
