import SwiftUI

@main
struct BPDashboardMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var document: BPDataDocument?

    var body: some View {
        VStack {
            if let doc = document {
                DashboardView(document: doc)
            } else {
                Button("Open BP Data File") {
                    openFile()
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK {
            if let url = panel.url {
                self.document = JSONLoader.loadBPData(from: url)
            }
        }
    }
}
