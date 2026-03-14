// InnuirBPApp.swift
// InnuirBP
//
// Main entry point for the Innuir Blood Pressure app.
// Sets up:
//   - SwiftData ModelContainer (with CloudKit sync)
//   - HealthKitService as an EnvironmentObject
//   - Root navigation (AppNavigation)

import SwiftUI
import SwiftData

@main
struct InnuirBPApp: App {

    // MARK: - Services

    @StateObject private var healthKitService = HealthKitService()

    // MARK: - SwiftData Container

    private let modelContainer: ModelContainer = {
        do {
            return try iCloudSyncService.makeModelContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            AppNavigation()
                .environmentObject(healthKitService)
                .task {
                    // Request HealthKit authorization on first launch
                    await healthKitService.requestAuthorization()
                }
        }
        .modelContainer(modelContainer)
    }
}
