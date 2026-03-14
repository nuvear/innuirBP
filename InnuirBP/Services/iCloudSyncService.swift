// iCloudSyncService.swift
// InnuirBP
//
// Configures the SwiftData ModelContainer for automatic iCloud sync
// using CloudKit's private database. All data remains in the user's
// private iCloud account — Innuir has no access to it.

import Foundation
import SwiftData

// MARK: - iCloud Sync Service

/// Provides the configured `ModelContainer` for the entire application.
///
/// SwiftData's built-in CloudKit integration automatically syncs the
/// user's `BPReading` data across all their Apple devices (iPhone, iPad, Mac)
/// via their private iCloud account. No data is ever sent to Innuir's servers.
///
/// **Requirements in Xcode:**
/// - Enable the "iCloud" capability in the main app target.
/// - Enable the "CloudKit" checkbox and create a container ID (e.g., `iCloud.com.innuir.bp`).
/// - Enable the "Background Modes" capability and check "Remote notifications".
enum iCloudSyncService {

    // MARK: - Model Container

    /// Creates and returns the shared `ModelContainer` with iCloud sync enabled.
    ///
    /// This container should be created once at app launch and passed into the
    /// SwiftUI environment via `.modelContainer()`.
    static func makeModelContainer() -> ModelContainer {
        let schema = Schema([BPReading.self])

        // Configure for iCloud sync using the app's CloudKit container identifier.
        // Replace "iCloud.com.innuir.bp" with the actual container ID from Xcode.
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.innuir.bp")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If the container cannot be created, fall back to local-only storage.
            // This should not happen in production; log the error for diagnostics.
            assertionFailure("Failed to create ModelContainer with iCloud sync: \(error). Falling back to local storage.")

            let localConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            return try! ModelContainer(for: schema, configurations: [localConfiguration])
        }
    }
}
