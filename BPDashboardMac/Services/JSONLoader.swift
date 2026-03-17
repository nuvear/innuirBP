import Foundation

class JSONLoader {
    static func loadBPData(from url: URL) -> BPDataDocument? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let document = try decoder.decode(BPDataDocument.self, from: data)
            return document
        } catch {
            print("Error loading or parsing JSON: \(error)")
            return nil
        }
    }
}
