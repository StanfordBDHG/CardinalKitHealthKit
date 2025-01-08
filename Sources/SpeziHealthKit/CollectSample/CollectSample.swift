//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import Spezi


/// Collects a specified `HKSampleType`  in the ``HealthKit`` module.
///
/// This structure define what and how the ``HealthKit`` samples are collected. By default, all samples of the provided `HKSampleType` will be collected. The collection starts on calling ``HealthKit/triggerDataSourceCollection()`` if you configure the `deliverySetting` as    ``HealthKitDeliverySetting/manual(safeAnchor:)`` or automatic once the application is launched when you configure anything else than manual, i.e.  ``HealthKitDeliverySetting/anchorQuery(_:saveAnchor:)`` or ``HealthKitDeliverySetting/background(_:saveAnchor:)``.
///
/// Your can filter the HealthKit samples to collect by specifying the `predicate`. For example, you can define an  `NSPredicate` to only collect the data collected at a time within the given start and end date. Below is an example to create a `NSPredicate` restricting the data collected in the previous month.
/// ```swift
/// private var predicateOneMonth: NSPredicate {
///     // Define the start and end time for the predicate. In this example,
///     // we want to collect the samples in the previous month.
///     let calendar = Calendar(identifier: .gregorian)
///     let today = calendar.startOfDay(for: Date())
///     // We want the end date to be tomorrow so that we can collect all the samples today.
///     guard let endDate = calendar.date(byAdding: .day, value: 1, to: today) else {
///         fatalError("*** Unable to calculate the end time ***")
///     }
///     // Define the start date to one month before.
///     guard let startDate = calendar.date(byAdding: .month, value: -1, to: today) else {
///         fatalError("*** Unable to calculate the start time ***")
///     }
///     // Initialize the NSPredicate with our start and end dates.
///     return HKQuery.predicateForSamples(withStart: startDate, end: endDate)
/// }
/// ```
///
/// Then, you just need to configure `predicate` with the  `predicateOneMonth` you defined as above during your initialization of ``CollectSample`` to only collect data samples in the previous month.
///
/// ```swift
/// CollectSample(
///     HKQuantityType(.stepCount),
///     predicate: predicateOneMonth,
///     deliverySetting: .background(.automatic)
/// )
/// ```
public struct CollectSample: HealthKitDataSourceDescription {
    private let collectSamples: CollectSamples
    
    
    public var sampleTypes: Set<HKSampleType> {
        collectSamples.sampleTypes
    }
    
    
    /// - Parameters:
    ///   - sampleType: The `HKSampleType` that should be collected
    ///   - predicate: A custom predicate that should be passed to the HealthKit query.
    ///                The default predicate collects all samples that have been collected from the first time that the user
    ///                provided the application authorization to collect the samples.
    ///   - deliverySetting: The ``HealthKitDeliverySetting`` that should be used to collect the sample type. `.manual` is the default argument used.
    public init<S: HKSampleType>(
        _ sampleType: S,
        predicate: NSPredicate? = nil,
        deliverySetting: HealthKitDeliverySetting = .manual()
    ) {
        self.collectSamples = CollectSamples([sampleType], predicate: predicate, deliverySetting: deliverySetting)
    }
    
    
    public func dataSources(
        healthStore: HKHealthStore,
        standard: any Standard
    ) -> [any HealthKitDataSource] {
        collectSamples.dataSources(healthStore: healthStore, standard: standard)
    }
}
