import Foundation

// MARK: - Main Document Structure
struct BPDataDocument: Codable {
    let schemaVersion: String
    let exportDate: String
    let patient: Patient
    let readings: [BPReading]
    let medications: [Medication]
    let annotations: [Annotation]
}

// MARK: - Patient
struct Patient: Codable {
    let id, name, dateOfBirth, gender: String
    let targetSystolic, targetDiastolic: Int
}

// MARK: - BPReading
struct BPReading: Codable, Identifiable {
    let id = UUID()
    let date, time, session: String
    let systolic, diastolic, pulse: Int

    var timestamp: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: "\(date)T\(time)Z") ?? Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case date, time, session, systolic, diastolic, pulse
    }
}

// MARK: - Medication
struct Medication: Codable, Identifiable {
    let id = UUID()
    let name, dose, frequency, startDate, endDate, color, notes: String
    
    enum CodingKeys: String, CodingKey {
        case name, dose, frequency, startDate, endDate, color, notes
    }
}

// MARK: - Annotation
struct Annotation: Codable, Identifiable {
    let id = UUID()
    let date, tag, title, text, author: String
    
    enum CodingKeys: String, CodingKey {
        case date, tag, title, text, author
    }
}
