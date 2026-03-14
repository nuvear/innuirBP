// HealthKitService.swift
// InnuirBP
//
// Handles all interactions with the HealthKit framework.
// This service is READ-ONLY — it imports data from the user's Apple Health
// store but never writes back to it. Innuir stores all data locally.

import Foundation
import HealthKit
import SwiftData

// MARK: - HealthKit Service

/// A singleton service that manages HealthKit authorization and data fetching.
///
/// The flow is:
/// 1. Request read authorization for blood pressure data.
/// 2. Fetch all `HKCorrelation` blood pressure samples since the last sync date.
/// 3. Convert them to `BPReading` model objects and insert into SwiftData.
/// 4. Persist the last sync date so future syncs are incremental.
@MainActor
final class HealthKitService: ObservableObject {

    // MARK: - Singleton

    static let shared = HealthKitService()
    private let store = HKHealthStore()

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
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToRead: Set<HKObjectType> = [bpCorrelationType, systolicType, diastolicType]

        do {
            try await store.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
        } catch {
            syncError = error
            isAuthorized = false
        }
    }

    // MARK: - Data Sync

    /// Fetches new blood pressure readings from HealthKit since the last sync date
    /// and inserts them into the provided SwiftData model context.
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

        } catch {
            syncError = error
        }

        isSyncing = false
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
