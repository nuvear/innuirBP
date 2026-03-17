import Foundation

class JSONLoader {
    /// Load and decode a BPDataDocument from a local JSON file URL.
    static func loadBPData(from url: URL) -> BPDataDocument? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let document = try decoder.decode(BPDataDocument.self, from: data)
            print("JSONLoader: loaded \(document.readings.count) readings for \(document.patient.name)")
            return document
        } catch {
            print("JSONLoader error: \(error)")
            return nil
        }
    }
}
