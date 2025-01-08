//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import Spezi


/// A common protocol that data sources collecting HealthKit data for the ``HealthKit`` module conform to.
public protocol HealthKitDataSourceDescription {
    /// The sample types that should be collected.
    var sampleTypes: Set<HKSampleType> { get }
    
    
    /// The ``HealthKitDataSourceDescription/dataSources(healthStore:standard:)`` method creates ``HealthKitDataSource``
    /// when the HealthKit module is instantiated.
    /// - Parameters:
    ///   - healthStore: The `HKHealthStore` instance that the queries should be performed on.
    ///   - standard: The `Standard` instance that is used in the software system.
    func dataSources(healthStore: HKHealthStore, standard: any Standard) -> [HealthKitDataSource]
}
