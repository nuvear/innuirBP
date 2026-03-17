import SwiftUI

struct MedicationTimelineView: View {
    let medications: [Medication]
    // This will need the date range and positioning logic

    var body: some View {
        HStack {
            ForEach(medications) { medication in
                Text("\(medication.name) \(medication.dose)")
                    .padding()
                    .background(Color(hex: medication.color) ?? .blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}

// Helper to convert hex color string to SwiftUI Color
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
