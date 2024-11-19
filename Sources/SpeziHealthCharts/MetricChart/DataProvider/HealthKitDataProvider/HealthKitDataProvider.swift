//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import HealthKit


public final class HealthKitDataProvider: DataProvider {
    private let healthStore = HKHealthStore()
    
    
    /// Queries an internal instance of a `HealthStore` for all past `HKQuantity`s of type `measurementType`, and stores the result in an `NSCache`.
    /// Returns an array of `HKQuantitySamples` whose timestamps fall in the given `ChartRange.domain`.
    ///
    /// If a previous query has already fetched the given type at the given granularity, returns that result from the cache.
    /// Passes a query to `HealthStore` that aggregates the resulting measurement by averaging over the given granularity.
    ///
    /// NOTE: `HKStatisticsCollectionQuery` can only be used with `HKQuantitySample`s. For `HKCorrelationSample`s, we'll need to aggregate/process
    /// the data ourselves. See https://developer.apple.com/documentation/healthkit/hkstatisticscollectionquery.
    public func fetchData(for measurementType: HKQuantityType, in chartRange: ChartRange) async throws -> [HKQuantitySample] {
        // If the `HKQuantityType` is a cumulative datatype, we cannot take the discrete average.
        let measurementTypeIsCumulative = measurementType.aggregationStyle == .cumulative
        
        // Create date interval components based on granularity.
        let intervalComponents = self.determineIntervalComponents(for: chartRange.granularity)
        
        // Only query for the samples in the given `ChartRange`.
        let dateRange = HKQuery.predicateForSamples(withStart: chartRange.domain.lowerBound, end: chartRange.domain.upperBound)
        let samplesInRange = HKSamplePredicate.quantitySample(type: measurementType, predicate: dateRange)
        
        let query = HKStatisticsCollectionQueryDescriptor(
            predicate: samplesInRange,
            options: measurementTypeIsCumulative ? .cumulativeSum : .discreteAverage,
            anchorDate: chartRange.domain.lowerBound,  // Start the intervals at the lower bound of the chart range.
            intervalComponents: intervalComponents
        )
        
        let statistics = try await query.result(for: self.healthStore)
        
        return self.convertStatisticsToSamples(statistics, type: measurementType, in: chartRange.domain)
    }
    
    private func determineIntervalComponents(for granularity: Calendar.Component) -> DateComponents {
        var components = DateComponents()
        switch granularity {
        case .hour:
            components.hour = 1
        case .day:
            components.day = 1
        case .weekOfYear:
            components.weekOfYear = 1
        case .month:
            components.month = 1
        case .year:
            components.year = 1
        default:
            components.day = 1  // Default to daily if unsupported granularity
        }
        return components
    }
    
    private func convertStatisticsToSamples(
        _ collection: HKStatisticsCollection,
        type: HKQuantityType,
        in domain: ClosedRange<Date>
    ) -> [HKQuantitySample] {
        let measurementTypeIsCumulative = type.aggregationStyle == .cumulative
        
        var samples: [HKQuantitySample] = []
        collection.enumerateStatistics(from: domain.lowerBound, to: domain.upperBound) { statistics, _ in
            guard let quantity = measurementTypeIsCumulative ? statistics.sumQuantity() : statistics.averageQuantity() else {
                return
            }
            
            // Initialize a new `HKQuantitySample` representing the average or cumulative sum of the samples from
            // `statistics.startDate` to `statistics.endDate`.
            let newSample = HKQuantitySample(
                type: type,
                quantity: quantity,
                start: statistics.startDate,
                end: statistics.endDate
            )
            
            samples.append(newSample)
        }
        
        return samples
    }
    
    
    public init() {}
}
