//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@preconcurrency import HealthKit
import OSLog
import Spezi
import SwiftUI


final class HealthKitSampleCollector<Sample: _HKSampleWithSampleType>: HealthDataCollector {
    // This needs to be unowned since the HealthKit module will establish a strong reference to the data source.
    private unowned let healthKit: HealthKit
    private let standard: any HealthKitConstraint
    
    let sampleType: SampleType<Sample>
//    var hkSampleType: HKSampleType { sampleType.hkSampleType }
    private let predicate: NSPredicate?
    let deliverySetting: HealthDataCollectorDeliverySetting
    @MainActor private(set) var isActive = false
    
    @MainActor private lazy var anchor: HKQueryAnchor? = loadAnchor() {
        didSet {
            saveAnchor()
        }
    }
    
    private var healthStore: HKHealthStore { healthKit.healthStore }
    

    required init(
        healthKit: HealthKit,
        standard: any HealthKitConstraint,
        sampleType: SampleType<Sample>,
        predicate: NSPredicate? = nil, // swiftlint:disable:this function_default_parameter_at_end
        deliverySetting: HealthDataCollectorDeliverySetting
    ) {
        self.healthKit = healthKit
        self.standard = standard
        self.sampleType = sampleType
        self.deliverySetting = deliverySetting

        if let predicate {
            self.predicate = predicate
        } else {
            self.predicate = HKQuery.predicateForSamples(
                withStart: Self.loadDefaultQueryDate(for: sampleType.hkSampleType),
                end: nil,
                options: .strictEndDate
            )
        }
    }
    
    
    private static func loadDefaultQueryDate(for sampleType: HKSampleType) -> Date {
        let defaultPredicateDateUserDefaultsKey = UserDefaults.Keys.healthKitDefaultPredicateDatePrefix.appending(sampleType.identifier)
        guard let date = UserDefaults.standard.object(forKey: defaultPredicateDateUserDefaultsKey) as? Date else {
            // We start date collection at the previous full minute mark to make the
            // data collection deterministic to manually entered data in HealthKit.
            var components = Calendar.current.dateComponents(in: .current, from: .now)
            components.setValue(0, for: .second)
            components.setValue(0, for: .nanosecond)
            let defaultQueryDate = components.date ?? .now
            UserDefaults.standard.set(defaultQueryDate, forKey: defaultPredicateDateUserDefaultsKey)
            return defaultQueryDate
        }
        return date
    }
    

    func startDataCollection() async {
        guard !isActive else {
            return
        }
        do {
            if deliverySetting.continueInBackground {
                // set up a background query
                try await healthStore.startBackgroundDelivery(for: [sampleType.hkSampleType]) { result in
                    guard case let .success((sampleTypes, completionHandler)) = result else {
                        return
                    }
                    guard sampleTypes.contains(self.sampleType.hkSampleType) else {
                        self.healthKit.logger.warning("Received Observation query types (\(sampleTypes)) are not corresponding to the CollectSample type \(self.sampleType.hkSampleType)")
                        completionHandler()
                        return
                    }
                    do {
                        try await self.anchoredSingleObjectQuery()
                        self.healthKit.logger.debug("Successfully processed background update for \(self.sampleType.hkSampleType)")
                    } catch {
                        self.healthKit.logger.error("Could not query samples in a background update for \(self.sampleType.hkSampleType): \(error)")
                    }
                    // Provide feedback to HealthKit that the data has been processed: https://developer.apple.com/documentation/healthkit/hkobserverquerycompletionhandler
                    completionHandler()
                }
                isActive = true
            } else {
                // set up a non-background query
                healthKit.logger.notice("Starting anchor query")
                try await anchoredContinuousObjectQuery()
                isActive = true
            }
        } catch {
            healthKit.logger.error("Could not Process HealthKit data collection: \(error.localizedDescription)")
        }
    }


    @MainActor
    private func anchoredSingleObjectQuery() async throws {
        let resultsAnchor = try await healthStore.anchoredSingleObjectQuery(
            for: self.sampleType.hkSampleType,
            using: self.anchor,
            withPredicate: predicate,
            standard: self.standard
        )
        self.anchor = resultsAnchor
    }

    
    @MainActor
    private func anchoredContinuousObjectQuery() async throws {
        let anchorDescriptor = healthStore.anchorDescriptor(
            sampleType: sampleType.hkSampleType,
            predicate: predicate,
            anchor: anchor
        )
        let updateQueue = anchorDescriptor.results(for: healthStore)
        Task {
            for try await results in updateQueue {
                for deletedObject in results.deletedObjects {
                    await standard.remove(sample: deletedObject)
                }
                for addedSample in results.addedSamples {
                    await standard.add(sample: addedSample)
                }
                self.anchor = results.newAnchor
            }
        }
    }

    
    @MainActor
    private func saveAnchor() {
        healthKit.queryAnchors[sampleType] = anchor
    }
    
    @MainActor
    private func loadAnchor() -> HKQueryAnchor? {
        healthKit.queryAnchors[sampleType]
    }
}
