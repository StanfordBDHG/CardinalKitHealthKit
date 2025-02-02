//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import OSLog
import Spezi


extension HKHealthStore {
    final class BackgroundObserverQueryInvalidator: @unchecked Sendable {
        private let healthStore: HKHealthStore
        private weak var query: HKQuery?
        
        init(healthStore: HKHealthStore, query: HKQuery) {
            self.healthStore = healthStore
            self.query = query
        }
        
        func invalidate() {
            if let query {
                healthStore.stop(query)
            }
        }
    }
    
    private static let activeObservationsLock = NSLock()
    private static nonisolated(unsafe) var activeObservations: [HKObjectType: Int] = [:]
    
    @MainActor @discardableResult
    func startBackgroundDelivery(
        for sampleTypes: Set<HKSampleType>,
        withPredicate predicate: NSPredicate? = nil,
        updateHandler: @escaping @MainActor @Sendable (
            Result<(sampleTypes: Set<HKSampleType>, completionHandler: HKObserverQueryCompletionHandler), any Error>
        ) async -> Void
    ) async throws -> BackgroundObserverQueryInvalidator {
        let queryDescriptors: [HKQueryDescriptor] = sampleTypes.map {
            HKQueryDescriptor(sampleType: $0, predicate: predicate)
        }
        let observerQuery = HKObserverQuery(queryDescriptors: queryDescriptors) { query, sampleTypes, completionHandler, error in
            // From https://developer.apple.com/documentation/healthkit/hkobserverquery/executing_observer_queries
            // "Whenever a matching sample is added to or deleted from the HealthKit store,
            // the system calls the query’s update handler on the same background queue (but not necessarily the same thread)."
            // So, the observerQuery has to be @Sendable!
            
            // Sadly necessary to enable capture of the `completionHandler` within the `Task`s below (isolation error)
            nonisolated(unsafe) let completionHandler = completionHandler
            if let error {
                Logger.healthKit.error(
                    """
                    Failed HealthKit background delivery for observer query \(query) on sample types \(String(describing: sampleTypes)) with error: \(error)
                    """
                )
                Task { @MainActor in
                    await updateHandler(.failure(error))
                    completionHandler()
                }
                return
            }
            guard let sampleTypes else {
                // invalid observer query update (both error and sampleTypes were nil).
                // There's nothing we can do here, so we just ignore it.
                return
            }
            Task { @MainActor in
                await updateHandler(.success((sampleTypes, completionHandler)))
            }
        }
        self.execute(observerQuery)
        try await enableBackgroundDelivery(for: sampleTypes)
        return .init(healthStore: self, query: observerQuery)
    }
    
    
    func enableBackgroundDelivery(for objectTypes: Set<HKObjectType>) async throws {
        var enabledObjectTypes: Set<HKObjectType> = []
        do {
            for objectType in objectTypes {
                try await self.enableBackgroundDelivery(for: objectType, frequency: .immediate)
                enabledObjectTypes.insert(objectType)
                Self.activeObservationsLock.withLock {
                    Self.activeObservations[objectType, default: 0] += 1
                }
            }
        } catch {
            Logger.healthKit.error("Could not enable HealthKit Backgound access for \(objectTypes): \(error.localizedDescription)")
            // Revert all changes as enable background delivery for the object types failed.
            disableBackgroundDelivery(for: enabledObjectTypes)
        }
    }
    
    
    func disableBackgroundDelivery(
        for objectTypes: Set<HKObjectType>
    ) {
        Self.activeObservationsLock.withLock {
            for objectType in objectTypes {
                if let activeObservation = HKHealthStore.activeObservations[objectType] {
                    let newActiveObservation = activeObservation - 1
                    if newActiveObservation <= 0 {
                        Self.activeObservations[objectType] = nil
                        Task { @MainActor in
                            try await self.disableBackgroundDelivery(for: objectType)
                        }
                    } else {
                        Self.activeObservations[objectType] = newActiveObservation
                    }
                }
            }
        }
    }
}
