import Foundation
import SwiftUI

// MARK: - Main Document Structure
struct BPDataDocument: Codable, Equatable {
    static func == (lhs: BPDataDocument, rhs: BPDataDocument) -> Bool {
        lhs.exportDate == rhs.exportDate && lhs.patient.id == rhs.patient.id
    }
    let schemaVersion: String
    let exportDate: String
    let patient: Patient
    let readings: [BPReading]
    let medications: [Medication]
    let annotations: [Annotation]
}

// MARK: - Patient
struct Patient: Codable, Equatable {
    let id, name, dateOfBirth, gender: String
    let targetSystolic, targetDiastolic: Int
}

// MARK: - BPReading
struct BPReading: Codable, Identifiable, Equatable {
    let id = UUID()
    let date: String
    let time: String
    let session: String
    let systolic: Int
    let diastolic: Int
    let pulse: Int

    /// Parse "yyyy-MM-dd" + "HH:mm" into a Date (local timezone).
    var timestamp: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: "\(date) \(time)") ?? Date.distantPast
    }

    enum CodingKeys: String, CodingKey {
        case date, time, session, systolic, diastolic, pulse
    }
}

// MARK: - Medication
struct Medication: Codable, Identifiable, Equatable {
    let id = UUID()
    let name, dose, frequency, startDate, endDate, color, notes: String

    var start: Date { parseDate(startDate) }
    var end: Date   { parseDate(endDate) }

    var swiftUIColor: Color { Color(hex: color) ?? .blue }

    enum CodingKeys: String, CodingKey {
        case name, dose, frequency, startDate, endDate, color, notes
    }

    private func parseDate(_ s: String) -> Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: s) ?? Date.distantPast
    }
}

// MARK: - Annotation
struct Annotation: Codable, Identifiable, Equatable {
    let id = UUID()
    let date: String
    let tag: String
    let title: String
    let text: String
    let author: String

    var timestamp: Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: date) ?? Date.distantPast
    }

    enum CodingKeys: String, CodingKey {
        case date, tag, title, text, author
    }
}

// MARK: - Color Hex Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: return nil
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
