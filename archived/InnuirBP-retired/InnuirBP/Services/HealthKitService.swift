// HealthKitService.swift
// InnuirBP
//
// Handles all interactions with the HealthKit framework.
// This service is READ-ONLY — it imports data from the user's Apple Health
// store but never writes back to it. Innuir stores all data locally.

import Foundation
import HealthKit
import os.log
import SwiftData
import WidgetKit

private let log = Logger(subsystem: "com.innuir.bp", category: "HealthKitSync")

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

    private static let authTimeoutSeconds: Double = 30

    /// Requests read authorization for blood pressure data from HealthKit.
    ///
    /// Uses the older completion-handler overload with `nil` for `toShare`
    /// (read-only access). The Obj-C wrapper catches `NSException` when the
    /// entitlement is missing. A 30-second timeout prevents indefinite hangs
    /// when the HealthKit completion handler never fires (e.g. permission
    /// sheet cannot present on iPad, or the system drops the callback).
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            syncError = makeEntitlementError("HealthKit is not available on this device.")
            return
        }

        let typesToRead: Set<HKObjectType> = [bpCorrelationType, systolicType, diastolicType]

        log.info("requestAuthorization: starting")

        let (success, error) = await withCheckedContinuation { (continuation: CheckedContinuation<(Bool, Error?), Never>) in
            let gate = ContinuationGate(continuation)

            InnuirBPRequestHealthKitAuthorization(store, typesToRead) { success, error in
                log.info("requestAuthorization: HealthKit completion fired, success=\(success)")
                gate.resume(returning: (success, error as Error?))
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + Self.authTimeoutSeconds) {
                let err = NSError(
                    domain: "InnuirBP.HealthKit", code: -2,
                    userInfo: [NSLocalizedDescriptionKey:
                        "HealthKit authorization timed out after \(Int(Self.authTimeoutSeconds)) seconds. "
                        + "Please open the Health app, then try syncing again."])
                log.warning("requestAuthorization: timed out after \(Self.authTimeoutSeconds)s")
                gate.resume(returning: (false, err))
            }
        }

        if let error {
            log.error("requestAuthorization: failed — \(error.localizedDescription)")
            syncError = error
            isAuthorized = false
        } else {
            log.info("requestAuthorization: succeeded, authorized=\(success)")
            isAuthorized = success
        }
    }

    private func makeEntitlementError(_ message: String?) -> NSError {
        let description = message
            ?? "HealthKit entitlement is missing. Enable HealthKit for the App ID "
            + "in Apple Developer Portal and rebuild."
        return NSError(
            domain: "InnuirBP.HealthKit",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
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
        log.info("syncFromHealthKit: starting, isAuthorized=\(self.isAuthorized)")

        if !isAuthorized {
            await requestAuthorization()
            guard isAuthorized else {
                log.warning("syncFromHealthKit: authorization failed, aborting sync")
                return
            }
        }

        isSyncing = true
        syncError = nil

        let startDate = lastSyncDate ?? Date.distantPast
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        do {
            log.info("syncFromHealthKit: fetching correlations since \(startDate)")
            let correlations = try await fetchCorrelations(predicate: predicate, sortDescriptors: [sortDescriptor])
            log.info("syncFromHealthKit: got \(correlations.count) correlations")

            let newReadings = convertToReadings(correlations: correlations, context: context)

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
            log.info("syncFromHealthKit: saved \(newReadings.count) new readings")

            let allDescriptor = FetchDescriptor<BPReading>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let allReadings = try context.fetch(allDescriptor)
            writeWidgetSnapshot(from: allReadings)

        } catch {
            log.error("syncFromHealthKit: error — \(error.localizedDescription)")
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

    private static let fetchTimeoutSeconds: Double = 30

    /// Fetches `HKCorrelation` objects from the HealthKit store.
    /// Includes a 30-second timeout to prevent indefinite hangs if the
    /// query completion handler never fires.
    private func fetchCorrelations(
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]
    ) async throws -> [HKCorrelation] {
        try await withCheckedThrowingContinuation { continuation in
            let gate = ThrowingContinuationGate(continuation)

            let query = HKCorrelationQuery(
                type: bpCorrelationType,
                predicate: predicate,
                samplePredicates: nil
            ) { _, correlations, error in
                if let error {
                    gate.resume(throwing: error)
                } else {
                    gate.resume(returning: correlations ?? [])
                }
            }
            store.execute(query)

            DispatchQueue.global().asyncAfter(deadline: .now() + Self.fetchTimeoutSeconds) {
                let err = NSError(
                    domain: "InnuirBP.HealthKit", code: -3,
                    userInfo: [NSLocalizedDescriptionKey:
                        "HealthKit data fetch timed out after \(Int(Self.fetchTimeoutSeconds)) seconds."])
                log.warning("fetchCorrelations: timed out after \(Self.fetchTimeoutSeconds)s")
                gate.resume(throwing: err)
            }
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

// MARK: - Continuation Gates
// Thread-safe wrappers that ensure a CheckedContinuation is resumed exactly once.
// The first caller wins; subsequent calls are no-ops. This prevents double-resume
// crashes when a timeout races against the actual HealthKit completion handler.

private final class ContinuationGate<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Never>?

    init(_ continuation: CheckedContinuation<T, Never>) {
        self.continuation = continuation
    }

    func resume(returning value: T) {
        lock.lock()
        let c = continuation
        continuation = nil
        lock.unlock()
        c?.resume(returning: value)
    }
}

private final class ThrowingContinuationGate<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, any Error>?

    init(_ continuation: CheckedContinuation<T, any Error>) {
        self.continuation = continuation
    }

    func resume(returning value: T) {
        lock.lock()
        let c = continuation
        continuation = nil
        lock.unlock()
        c?.resume(returning: value)
    }

    func resume(throwing error: any Error) {
        lock.lock()
        let c = continuation
        continuation = nil
        lock.unlock()
        c?.resume(throwing: error)
    }
}
