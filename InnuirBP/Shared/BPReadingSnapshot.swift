// BPReadingSnapshot.swift
// InnuirBP
//
// Lightweight Codable snapshot for widget data sharing.
// Used by both the main app (to write) and the widget extension (to read).
// Must be in a file included in BOTH targets.

import Foundation

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
