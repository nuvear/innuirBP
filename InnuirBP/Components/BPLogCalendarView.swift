// BPLogCalendarView.swift
// InnuirBP
//
// The "Blood Pressure Log" section shown below the chart in BPDetailView.
// Displays a calendar grid with checkmarks on days that have readings,
// and summary stats (Measurements Taken, Days Left in the month).
// Matches the Apple Health iPad reference screenshot (2.jpg).

import SwiftUI
import SwiftData

// MARK: - BP Log Section

struct BPLogSection: View {
    let readings: [BPReading]

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Blood Pressure Log")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(.label))
                Spacer()
                Button("Options") {}
                    .font(.system(size: 15))
                    .foregroundStyle(Color(.systemBlue))
            }

            // Calendar card
            VStack(alignment: .leading, spacing: 12) {
                // Stats row
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Measurements Taken:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(.label))
                        + Text(" \(measurementsTaken)")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(.label))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Days Left:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(.label))
                        + Text(" \(daysLeftInMonth)")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(.label))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Divider()
                    .padding(.horizontal, 16)

                // Calendar grid
                BPCalendarGrid(
                    month: displayedMonth,
                    readings: readings,
                    onPreviousMonth: {
                        if let prev = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
                            displayedMonth = Calendar.current.startOfMonth(for: prev)
                        }
                    },
                    onNextMonth: {
                        if let next = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
                            displayedMonth = Calendar.current.startOfMonth(for: next)
                        }
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
    }

    private var measurementsTaken: Int {
        let calendar = Calendar.current
        let start = calendar.startOfMonth(for: displayedMonth)
        let end = calendar.endOfMonth(for: displayedMonth)
        return readings.filter { $0.timestamp >= start && $0.timestamp <= end }.count
    }

    private var daysLeftInMonth: Int {
        let calendar = Calendar.current
        let end = calendar.endOfMonth(for: Date())
        let today = calendar.startOfDay(for: Date())
        return max(0, calendar.dateComponents([.day], from: today, to: end).day ?? 0)
    }
}

// MARK: - Calendar Grid

struct BPCalendarGrid: View {
    let month: Date
    let readings: [BPReading]
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let dayHeaders = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 0) {
            // Month header with navigation
            HStack {
                Button(action: onPreviousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(.systemBlue))
                }
                Spacer()
                Text(monthLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(.secondaryLabel))
                Spacer()
                Button(action: onNextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        // Disable the forward button when already on the current month.
                        .foregroundStyle(isCurrentMonth ? Color(.systemGray3) : Color(.systemBlue))
                }
                .disabled(isCurrentMonth)
            }
            .padding(.bottom, 8)

            // Day-of-week headers
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(dayHeaders, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(.secondaryLabel))
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 6)
                }
            }

            // Date cells
            LazyVGrid(columns: columns, spacing: 4) {
                // Leading empty cells for the first week
                ForEach(0..<leadingEmptyCells, id: \.self) { _ in
                    Color.clear.frame(height: 36)
                }

                // Day cells
                ForEach(daysInMonth, id: \.self) { date in
                    BPCalendarDayCell(
                        date: date,
                        hasReading: hasReading(on: date),
                        isToday: calendar.isDateInToday(date)
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    /// Returns `true` when the displayed month is the current calendar month,
    /// preventing the user from navigating into the future.
    private var isCurrentMonth: Bool {
        calendar.isDate(month, equalTo: Date(), toGranularity: .month)
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: month)
    }

    private var leadingEmptyCells: Int {
        let firstDay = calendar.startOfMonth(for: month)
        let weekday = calendar.component(.weekday, from: firstDay)
        return weekday - 1 // Sunday = 1, so offset = weekday - 1
    }

    private var daysInMonth: [Date] {
        let start = calendar.startOfMonth(for: month)
        let range = calendar.range(of: .day, in: .month, for: month)!
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: start)
        }
    }

    private func hasReading(on date: Date) -> Bool {
        readings.contains { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }
}

// MARK: - Calendar Day Cell

struct BPCalendarDayCell: View {
    let date: Date
    let hasReading: Bool
    let isToday: Bool

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        ZStack {
            if isToday {
                Circle()
                    .stroke(Color(.systemPurple), lineWidth: 1.5)
                    .frame(width: 32, height: 32)
            }

            if hasReading {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(.systemPurple))
            } else {
                Text(dayNumber)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(.label))
            }
        }
        .frame(height: 36)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Calendar Extensions

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)!
    }

    func endOfMonth(for date: Date) -> Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return self.date(byAdding: components, to: startOfMonth(for: date))!
    }
}
