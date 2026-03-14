// ClinicalGuideline.swift
// InnuirBP
//
// Decodable structs that map directly to the aha_hypertension.json and
// esc_hypertension.json resource files. The chart reads all clinical
// thresholds, band definitions, and labels from these structs — no
// hardcoded clinical values exist anywhere else in the codebase.

import Foundation
import SwiftUI

// MARK: - Guideline Type

/// Identifies which clinical guideline standard is active.
enum GuidelineType: String, CaseIterable, Identifiable {
    case aha = "AHA"
    case esc = "ESC"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .aha: return "AHA"
        case .esc: return "ESC"
        }
    }

    var resourceFileName: String {
        switch self {
        case .aha: return "aha_hypertension"
        case .esc: return "esc_hypertension"
        }
    }
}

// MARK: - Top-Level Guideline Document

/// The root object decoded from a guideline JSON file.
struct ClinicalGuidelineDocument: Decodable {
    let guideline: String
    let version: String
    let source: String
    let description: String
    let stages: [ClinicalStage]
    let chartBands: [ChartBand]
    let thresholdLines: [ThresholdLine]
}

// MARK: - Clinical Stage

/// A single classification stage within a guideline (e.g., "Hypertension Stage 1").
struct ClinicalStage: Decodable, Identifiable {
    let id: String
    let name: String
    let shortName: String
    let systolicMin: Double?
    let systolicMax: Double?
    let diastolicMin: Double?
    let diastolicMax: Double?
    let color: String       // Hex color string, e.g. "#FF3B30"
    let description: String

    /// The SwiftUI `Color` derived from the hex string in the JSON.
    var swiftUIColor: Color {
        Color(hex: color) ?? .red
    }

    /// Returns `true` if the given reading falls within this stage's thresholds.
    func contains(systolic: Double, diastolic: Double) -> Bool {
        let sysMin = systolicMin ?? 0
        let sysMax = systolicMax ?? Double.infinity
        let diaMin = diastolicMin ?? 0
        let diaMax = diastolicMax ?? Double.infinity

        return (systolic >= sysMin && systolic < sysMax) ||
               (diastolic >= diaMin && diastolic < diaMax)
    }
}

// MARK: - Chart Band

/// A shaded background band on the chart (e.g., the gray "normal" zone).
struct ChartBand: Decodable {
    let id: String
    let yMin: Double
    let yMax: Double
    let color: String       // Hex color with alpha, e.g. "#00000010"
    let label: String?

    var swiftUIColor: Color {
        Color(hex: color) ?? Color.gray.opacity(0.1)
    }
}

// MARK: - Threshold Line

/// A dashed horizontal reference line on the chart (e.g., the 130 mmHg line).
struct ThresholdLine: Decodable {
    let value: Double
    let label: String
    let color: String

    var swiftUIColor: Color {
        Color(hex: color) ?? .gray
    }
}

// MARK: - Guideline Loader

/// A service that loads and caches clinical guideline documents from the app bundle.
final class GuidelineLoader {

    static let shared = GuidelineLoader()
    private var cache: [GuidelineType: ClinicalGuidelineDocument] = [:]
    private init() {}

    /// Loads the guideline document for the given type, using a cache for performance.
    func load(_ type: GuidelineType) -> ClinicalGuidelineDocument? {
        if let cached = cache[type] { return cached }

        guard let url = Bundle.main.url(forResource: type.resourceFileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let document = try? JSONDecoder().decode(ClinicalGuidelineDocument.self, from: data)
        else {
            assertionFailure("Failed to load guideline: \(type.resourceFileName).json")
            return nil
        }

        cache[type] = document
        return document
    }

    /// Returns the clinical stage that a given reading falls into.
    func classify(systolic: Double, diastolic: Double, guideline: GuidelineType) -> ClinicalStage? {
        guard let document = load(guideline) else { return nil }
        // Stages are ordered from most severe to least; return the first match.
        return document.stages.first { $0.contains(systolic: systolic, diastolic: diastolic) }
    }
}

// MARK: - Color Extension

extension Color {
    /// Initialises a SwiftUI Color from a hex string (e.g., "#FF3B30" or "#FF3B3080").
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        let r, g, b, a: Double

        switch length {
        case 6:
            r = Double((rgb >> 16) & 0xFF) / 255
            g = Double((rgb >> 8) & 0xFF) / 255
            b = Double(rgb & 0xFF) / 255
            a = 1.0
        case 8:
            r = Double((rgb >> 24) & 0xFF) / 255
            g = Double((rgb >> 16) & 0xFF) / 255
            b = Double((rgb >> 8) & 0xFF) / 255
            a = Double(rgb & 0xFF) / 255
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
