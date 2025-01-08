//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
// Created by Matthew Joerke and Bryant Jimenez

import HealthKit
import Spezi
import OSLog

/// Collects batches of `HKSampleType`s  in the ``HealthKit`` module for upload.
public struct BulkUpload: HealthKitDataSourceDescription {
    public let sampleTypes: Set<HKSampleType>
    let predicate: NSPredicate
    let deliverySetting: HealthKitDeliverySetting
    let bulkSize: Int
    
    /// - Parameters:
    ///   - sampleTypes: The set of `HKSampleType`s that should be collected
    ///   - predicate: A custom predicate that should be passed to the HealthKit query.
    ///                The default predicate collects all samples that have been collected from the first time that the user
    ///                provided the application authorization to collect the samples.
    ///   - deliverySetting: The ``HealthKitDeliverySetting`` that should be used to collect the sample type. `.manual` is the default argument used.
    public init(
        _ sampleTypes: Set<HKSampleType>,
        predicate: NSPredicate,
        bulkSize: Int = 100,
        deliveryStartSetting: HealthKitDeliveryStartSetting = .manual
    ) {
        self.sampleTypes = sampleTypes
        self.predicate = predicate
        self.bulkSize = bulkSize
        self.deliverySetting = HealthKitDeliverySetting.anchorQuery(deliveryStartSetting, saveAnchor: true)
        Logger.healthKit.info("Initialized BulkUpload data source")
    }
    
    public func dataSources(healthStore: HKHealthStore, standard: any Standard) -> [any HealthKitDataSource] {
        // Ensure the 'standard' actually conforms to 'BulkUploadConstraint' to use specific processBulk function.
        guard let bulkUploadConstraint = standard as? any BulkUploadConstraint else {
            preconditionFailure(
                """
                The `Standard` defined in the `Configuration` does not conform to \(String(describing: (any HealthKitConstraint).self)).
                
                Ensure that you define an appropriate standard in your configuration in your `SpeziAppDelegate` subclass ...
                ```
                var configuration: Configuration {
                    Configuration(standard: \(String(describing: standard))()) {
                        // ...
                    }
                }
                ```
                
                ... and that your standard conforms to \(String(describing: (any HealthKitConstraint).self)):
                
                ```swift
                actor \(String(describing: standard)): Standard, \(String(describing: (any HealthKitConstraint).self)) {
                    // ...
                }
                ```
                """
            )
        }
        
        return sampleTypes.map { sampleType in
            BulkUploadSampleDataSource(
                healthStore: healthStore,
                standard: bulkUploadConstraint,
                sampleType: sampleType,
                predicate: predicate,
                deliverySetting: deliverySetting,
                bulkSize: bulkSize
            )
        }
    }
}
