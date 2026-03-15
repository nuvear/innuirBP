// BPReading.swift
// InnuirBP
//
// The core persistent data model for a single blood pressure reading.
// Uses SwiftData for on-device storage with automatic iCloud (CloudKit) sync.

import Foundation
import SwiftData

// MARK: - Data Source

/// Indicates the origin of a blood pressure reading.
enum BPDataSource: String, Codable {
    /// The reading was imported from the user's HealthKit store.
    case healthKit = "healthKit"
    /// The reading was entered manually by the user within the Innuir app.
    case manual = "manual"
}

// MARK: - BPReading Model

/// A single blood pressure reading, stored persistently via SwiftData.
///
/// This model is the single source of truth for all BP data in the app.
/// Data from HealthKit is imported and stored here; manual entries are
/// created directly. All data is stored on-device and synced privately
/// across the user's Apple devices via iCloud (CloudKit).
@Model
final class BPReading {

    // MARK: Stored Properties

    /// A stable, unique identifier for this reading.
    var id: UUID

    /// The systolic blood pressure value, measured in mmHg.
    var systolic: Double

    /// The diastolic blood pressure value, measured in mmHg.
    var diastolic: Double

    /// The exact date and time at which the reading was recorded.
    var timestamp: Date

    /// The origin of this reading (HealthKit or manual entry).
    var source: BPDataSource

    /// The HealthKit UUID for this reading, used to prevent duplicate imports.
    /// This is `nil` for manually entered readings.
    var healthKitUUID: String?

    /// The date this record was created in the Innuir app.
    var createdAt: Date

    // MARK: Initialiser

    init(
        id: UUID = UUID(),
        systolic: Double,
        diastolic: Double,
        timestamp: Date,
        source: BPDataSource,
        healthKitUUID: String? = nil
    ) {
        self.id = id
        self.systolic = systolic
        self.diastolic = diastolic
        self.timestamp = timestamp
        self.source = source
        self.healthKitUUID = healthKitUUID
        self.createdAt = Date()
    }
}

// MARK: - Computed Properties

extension BPReading {

    /// The pulse pressure (systolic minus diastolic), in mmHg.
    var pulsePressure: Double {
        systolic - diastolic
    }

    /// A formatted string representation of the reading (e.g., "125/78").
    var formattedValue: String {
        "\(Int(systolic))/\(Int(diastolic))"
    }
}

// MARK: - Sorting

extension BPReading: Comparable {
    static func < (lhs: BPReading, rhs: BPReading) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
}
