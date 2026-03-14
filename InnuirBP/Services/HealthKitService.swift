// HealthKitService.swift
// InnuirBP
//
// Handles all interactions with the HealthKit framework.
// This service is READ-ONLY — it imports data from the user's Apple Health
// store but never writes back to it. Innuir stores all data locally.

import Foundation
import HealthKit
import SwiftData
import WidgetKit

// MARK: - HealthKit Service

/// A singleton service that manages HealthKit authorization and data fetching.
///
/// The flow is:
/// 1. Request read authorization for blood pressure data.
/// 2. Fetch all `HKCorrelation` blood pressure samples since the last sync date.
/// 3. Convert them to `BPReading` model objects and insert into SwiftData.
/// 4. Persist the last sync date so future syncs are incremental.
/// 5. Write a lightweight JSON snapshot to the App Group UserDefaults so the
///    WidgetKit extension can display up-to-date data without SwiftData access.
@MainActor
final class HealthKitService: ObservableObject {

    // MARK: - Singleton

    static let shared = HealthKitService()
    private let store = HKHealthStore()

    // MARK: - App Group identifier (must match Xcode entitlements)

    static let appGroupID = "group.com.innuir.bp"
    static let widgetSnapshotKey = "bp_readings"

    // MARK: - Published State

    @Published var isAuthorized: Bool = false
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date? {
        didSet {
            if let date = lastSyncDate {
                UserDefaults.standard.set(date, forKey: "innuir.bp.lastSyncDate")
            }
        }
    }
    @Published var syncError: Error?

    // MARK: - HealthKit Types

    private let bpCorrelationType = HKCorrelationType(.bloodPressure)
    private let systolicType = HKQuantityType(.bloodPressureSystolic)
    private let diastolicType = HKQuantityType(.bloodPressureDiastolic)

    // MARK: - Initialiser

    private init() {
        self.lastSyncDate = UserDefaults.standard.object(forKey: "innuir.bp.lastSyncDate") as? Date
    }

    // MARK: - Authorization

    /// Requests read authorization for blood pressure data from HealthKit.
    ///
    /// **Why the completion-handler overload?**
    /// The modern `async throws` overload —
    /// `requestAuthorization(toShare: Set<HKSampleType>, read:)` — has
    /// **non-optional** parameters. Passing an empty `Set` for `toShare`
    /// causes HealthKit to call `_throwIfAuthorizationDisallowedForSharing`,
    /// which throws an `NSException` (not a Swift `Error`) and crashes the app.
    ///
    /// The older completion-handler overload —
    /// `requestAuthorization(toShare: Set<HKSampleType>?, read:completion:)` —
    /// accepts `nil` for `toShare`, which explicitly signals "no write access
    /// requested" and bypasses the sharing-authorization guard entirely.
    ///
    /// This is the correct pattern for a read-only HealthKit integration.
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToRead: Set<HKObjectType> = [bpCorrelationType, systolicType, diastolicType]

        // Use the completion-handler overload so we can pass nil for toShare.
        // The async overload requires a non-optional Set and crashes with [].
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            store.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
                guard let self else { continuation.resume(); return }
                if let error {
                    self.syncError = error
                    self.isAuthorized = false
                } else {
                    self.isAuthorized = success
                }
                continuation.resume()
            }
        }
    }

    // MARK: - Data Sync

    /// Fetches new blood pressure readings from HealthKit since the last sync date
    /// and inserts them into the provided SwiftData model context.
    ///
    /// After inserting new readings, this method also writes a lightweight JSON
    /// snapshot of the 30 most recent readings to the shared App Group UserDefaults,
    /// so the WidgetKit extension can display up-to-date data without needing
    /// direct SwiftData access.
    ///
    /// - Parameter context: The SwiftData `ModelContext` to insert new readings into.
    func syncFromHealthKit(context: ModelContext) async {
        guard isAuthorized else {
            await requestAuthorization()
            guard isAuthorized else { return }
        }

        isSyncing = true
        syncError = nil

        // Build a predicate to fetch only new data since the last sync.
        let startDate = lastSyncDate ?? Date.distantPast
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        do {
            let correlations = try await fetchCorrelations(predicate: predicate, sortDescriptors: [sortDescriptor])
            let newReadings = convertToReadings(correlations: correlations, context: context)

            // Insert only readings that don't already exist (de-duplication by HealthKit UUID).
            for reading in newReadings {
                let hkID = reading.healthKitUUID
                let descriptor = FetchDescriptor<BPReading>(
                    predicate: #Predicate { $0.healthKitUUID == hkID }
                )
                let existing = try context.fetch(descriptor)
                if existing.isEmpty {
                    context.insert(reading)
                }
            }

            try context.save()
            lastSyncDate = endDate

            // After saving, refresh the widget snapshot with all current readings.
            let allDescriptor = FetchDescriptor<BPReading>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let allReadings = try context.fetch(allDescriptor)
            writeWidgetSnapshot(from: allReadings)

        } catch {
            syncError = error
        }

        isSyncing = false
    }

    // MARK: - Widget Snapshot

    /// Writes a JSON snapshot of the 30 most recent readings to the shared
    /// App Group UserDefaults so the WidgetKit extension can read them.
    ///
    /// This must be called after any data mutation (sync or manual entry).
    ///
    /// - Parameter readings: All readings, sorted by timestamp descending.
    func writeWidgetSnapshot(from readings: [BPReading]) {
        let snapshots = readings.prefix(30).map {
            BPReadingSnapshot(
                systolic: $0.systolic,
                diastolic: $0.diastolic,
                timestamp: $0.timestamp
            )
        }

        guard
            let data = try? JSONEncoder().encode(Array(snapshots)),
            let defaults = UserDefaults(suiteName: Self.appGroupID)
        else { return }

        defaults.set(data, forKey: Self.widgetSnapshotKey)

        // Notify WidgetKit to reload all timelines immediately.
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Private Helpers

    /// Fetches `HKCorrelation` objects from the HealthKit store using an async wrapper.
    private func fetchCorrelations(
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]
    ) async throws -> [HKCorrelation] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKCorrelationQuery(
                type: bpCorrelationType,
                predicate: predicate,
                samplePredicates: nil
            ) { _, correlations, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: correlations ?? [])
                }
            }
            store.execute(query)
        }
    }

    /// Converts a list of `HKCorrelation` objects into `BPReading` model objects.
    private func convertToReadings(correlations: [HKCorrelation], context: ModelContext) -> [BPReading] {
        correlations.compactMap { correlation in
            guard
                let systolicSample = correlation.objects(for: systolicType).first as? HKQuantitySample,
                let diastolicSample = correlation.objects(for: diastolicType).first as? HKQuantitySample
            else { return nil }

            let systolic = systolicSample.quantity.doubleValue(for: .millimeterOfMercury())
            let diastolic = diastolicSample.quantity.doubleValue(for: .millimeterOfMercury())

            return BPReading(
                systolic: systolic,
                diastolic: diastolic,
                timestamp: correlation.startDate,
                source: .healthKit,
                healthKitUUID: correlation.uuid.uuidString
            )
        }
    }
}
