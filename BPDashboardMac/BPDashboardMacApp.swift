import SwiftUI
import UniformTypeIdentifiers

@main
struct BPDashboardMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open BP Data File…") {
                    NotificationCenter.default.post(name: .openBPFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let openBPFile = Notification.Name("openBPFile")
}

// MARK: - Content View (Welcome / Dashboard Router)
struct ContentView: View {
    @State private var document: BPDataDocument?
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        Group {
            if let doc = document {
                DashboardView(viewModel: DashboardViewModel(document: doc))
            } else {
                WelcomeView(onOpenFile: openFile)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openBPFile)) { _ in
            openFile()
        }
        .alert("Failed to Load File", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "The selected file could not be parsed. Please check that it is a valid bp_data.json file.")
        }
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.json]
        panel.title = "Open BP Data File"
        panel.message = "Select a bp_data.json file to visualise"
        panel.prompt = "Open"
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        if let doc = JSONLoader.loadBPData(from: url) {
            self.document = doc
        } else {
            self.errorMessage = "Could not parse \(url.lastPathComponent). Ensure it matches the bp_data schema (schemaVersion: \"1.0\")."
            self.showError = true
        }
    }
}

// MARK: - Welcome Screen
struct WelcomeView: View {
    let onOpenFile: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
            
            VStack(spacing: 8) {
                Text("BP Dashboard")
                    .font(.largeTitle.bold())
                Text("Evidence-based blood pressure visualisation")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            Button(action: onOpenFile) {
                Label("Open BP Data File…", systemImage: "folder.badge.plus")
                    .font(.title3)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut("o", modifiers: .command)
            
            VStack(spacing: 4) {
                Text("Accepts JSON files in bp_data schema v1.0")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("Sample file: BPDashboardMac/SampleData/bp_data_2026.json")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
