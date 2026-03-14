// BPWidget.swift
// InnuirBPWidget
//
// WidgetKit extension providing glanceable Blood Pressure widgets.
// Supports all widget families:
//   - .systemSmall   → Latest reading + stage badge
//   - .systemMedium  → Latest reading + 7-day mini chart
//   - .systemLarge   → Latest reading + 30-day chart + stage breakdown
//   - .accessoryCircular  → Latest systolic value (Lock Screen / Watch)
//   - .accessoryRectangular → Sys/Dia + date (Lock Screen)
//   - .accessoryInline   → "125/78 mmHg" (Lock Screen inline)
//
// Tapping any widget deep-links to BPDetailView in the main app.

import WidgetKit
import SwiftUI
import SwiftData
import Charts

// MARK: - Timeline Entry

struct BPWidgetEntry: TimelineEntry {
    let date: Date
    let latestReading: BPReadingSnapshot?
    let recentReadings: [BPReadingSnapshot]
    let dominantStage: String
    let dominantStageColor: Color
}

// MARK: - Lightweight snapshot (no SwiftData in widget extension)

struct BPReadingSnapshot: Codable {
    let systolic: Double
    let diastolic: Double
    let timestamp: Date

    var systolicInt: Int { Int(systolic) }
    var diastolicInt: Int { Int(diastolic) }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: timestamp)
    }
}

// MARK: - Timeline Provider

struct BPWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> BPWidgetEntry {
        BPWidgetEntry(
            date: Date(),
            latestReading: BPReadingSnapshot(systolic: 125, diastolic: 78, timestamp: Date()),
            recentReadings: Self.sampleReadings(),
            dominantStage: "Elevated",
            dominantStageColor: .yellow
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BPWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BPWidgetEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Load from shared UserDefaults (App Group)

    private func loadEntry() -> BPWidgetEntry {
        guard
            let defaults = UserDefaults(suiteName: "group.com.innuir.bp"),
            let data = defaults.data(forKey: "bp_readings"),
            let readings = try? JSONDecoder().decode([BPReadingSnapshot].self, from: data)
        else {
            return BPWidgetEntry(
                date: Date(),
                latestReading: nil,
                recentReadings: [],
                dominantStage: "No data",
                dominantStageColor: .gray
            )
        }

        let sorted = readings.sorted { $0.timestamp > $1.timestamp }
        let latest = sorted.first
        let recent = Array(sorted.prefix(30))

        // Classify latest reading using AHA thresholds
        let (stage, color) = classifyAHA(latest)

        return BPWidgetEntry(
            date: Date(),
            latestReading: latest,
            recentReadings: recent,
            dominantStage: stage,
            dominantStageColor: color
        )
    }

    private func classifyAHA(_ reading: BPReadingSnapshot?) -> (String, Color) {
        guard let r = reading else { return ("No data", .gray) }
        let s = r.systolic, d = r.diastolic
        if s >= 180 || d >= 120 { return ("Crisis", .red) }
        if s >= 140 || d >= 90  { return ("Stage 2", .red) }
        if s >= 130 || d >= 80  { return ("Stage 1", .orange) }
        if s >= 120             { return ("Elevated", .yellow) }
        return ("Normal", .green)
    }

    private static func sampleReadings() -> [BPReadingSnapshot] {
        (0..<14).map { i in
            BPReadingSnapshot(
                systolic: Double.random(in: 118...138),
                diastolic: Double.random(in: 74...90),
                timestamp: Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            )
        }
    }
}

// MARK: - Widget Configuration

struct BPWidget: Widget {
    let kind = "InnuirBPWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BPWidgetProvider()) { entry in
            BPWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Blood Pressure")
        .description("See your latest blood pressure reading at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Entry View Router

struct BPWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BPWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            BPWidgetSmall(entry: entry)
        case .systemMedium:
            BPWidgetMedium(entry: entry)
        case .systemLarge:
            BPWidgetLarge(entry: entry)
        case .accessoryCircular:
            BPWidgetAccessoryCircular(entry: entry)
        case .accessoryRectangular:
            BPWidgetAccessoryRectangular(entry: entry)
        case .accessoryInline:
            BPWidgetAccessoryInline(entry: entry)
        default:
            BPWidgetSmall(entry: entry)
        }
    }
}

// MARK: - System Small Widget

struct BPWidgetSmall: View {
    let entry: BPWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .font(.system(size: 12))
                Text("Blood Pressure")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let r = entry.latestReading {
                Text("\(r.systolicInt)/\(r.diastolicInt)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("mmHg")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            } else {
                Text("No data")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Stage badge
            Text(entry.dominantStage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(entry.dominantStageColor)
                )

            if let r = entry.latestReading {
                Text(r.formattedDate)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .widgetURL(URL(string: "innuirbp://detail"))
    }
}

// MARK: - System Medium Widget

struct BPWidgetMedium: View {
    let entry: BPWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: latest reading
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .font(.system(size: 12))
                    Text("Blood Pressure")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let r = entry.latestReading {
                    Text("\(r.systolicInt)/\(r.diastolicInt)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("mmHg")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text(r.formattedDate)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Text(entry.dominantStage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(entry.dominantStageColor))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: 7-day mini chart
            BPMiniChart(readings: Array(entry.recentReadings.prefix(7)))
                .frame(maxWidth: .infinity)
        }
        .padding(14)
        .widgetURL(URL(string: "innuirbp://detail"))
    }
}

// MARK: - System Large Widget

struct BPWidgetLarge: View {
    let entry: BPWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text("Blood Pressure")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let r = entry.latestReading {
                    Text(r.formattedDate)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            if let r = entry.latestReading {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(r.systolicInt)/\(r.diastolicInt)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("mmHg")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }

            Text(entry.dominantStage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(entry.dominantStageColor))

            // 30-day chart
            BPMiniChart(readings: Array(entry.recentReadings.prefix(30)))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(14)
        .widgetURL(URL(string: "innuirbp://detail"))
    }
}

// MARK: - Accessory Circular (Lock Screen / Watch)

struct BPWidgetAccessoryCircular: View {
    let entry: BPWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                if let r = entry.latestReading {
                    Text("\(r.systolicInt)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("\(r.diastolicInt)")
                        .font(.system(size: 12, weight: .regular))
                }
            }
        }
        .widgetURL(URL(string: "innuirbp://detail"))
    }
}

// MARK: - Accessory Rectangular (Lock Screen)

struct BPWidgetAccessoryRectangular: View {
    let entry: BPWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Blood Pressure", systemImage: "heart.fill")
                .font(.system(size: 11, weight: .semibold))
            if let r = entry.latestReading {
                Text("\(r.systolicInt)/\(r.diastolicInt) mmHg")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(r.formattedDate)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else {
                Text("No data")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetURL(URL(string: "innuirbp://detail"))
    }
}

// MARK: - Accessory Inline (Lock Screen single line)

struct BPWidgetAccessoryInline: View {
    let entry: BPWidgetEntry

    var body: some View {
        if let r = entry.latestReading {
            Label("\(r.systolicInt)/\(r.diastolicInt) mmHg", systemImage: "heart.fill")
        } else {
            Label("No BP data", systemImage: "heart.fill")
        }
    }
}

// MARK: - Mini Chart (shared by Medium + Large)

struct BPMiniChart: View {
    let readings: [BPReadingSnapshot]

    var body: some View {
        Chart {
            ForEach(readings.indices, id: \.self) { i in
                let r = readings[i]
                // Systolic dot
                PointMark(
                    x: .value("Date", r.timestamp),
                    y: .value("Systolic", r.systolic)
                )
                .foregroundStyle(Color.red.opacity(0.8))
                .symbolSize(20)

                // Diastolic dot
                PointMark(
                    x: .value("Date", r.timestamp),
                    y: .value("Diastolic", r.diastolic)
                )
                .foregroundStyle(Color.red.opacity(0.5))
                .symbolSize(12)

                // Connecting line
                RuleMark(
                    x: .value("Date", r.timestamp),
                    yStart: .value("Diastolic", r.diastolic),
                    yEnd: .value("Systolic", r.systolic)
                )
                .foregroundStyle(Color.red.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 55...170)
    }
}

// MARK: - Widget Bundle

@main
struct InnuirBPWidgetBundle: WidgetBundle {
    var body: some Widget {
        BPWidget()
    }
}
