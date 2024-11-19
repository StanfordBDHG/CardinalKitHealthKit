//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import HealthKit

// TODO: Give 


/// A class conforming to `DataProvider` multiplexes to fetch the data from a specific data store in the form of `HKQuantitySample`s.
///
/// Implementation of `.fetchData()` should query all data of that type once, cache the data, and aggregate it according to the provided granularity.
/// The aggregation is preferrably done by the data store (i.e. `HealthStore`), with only the final data array being stored on device.
///
/// Then, only data points within the `ChartRange` will be shown in the `HealthChart`.
///
/// Default implementation fetches `HealthKitDataProvider` fetches data from a HealthKit `HealthStore`.
public protocol DataProvider: Sendable {
    // TODO: Pass `ChartRange` instead of interval, query all health data at once aggregated by `DateRange` granularity.
    func fetchData(for measurementType: HKQuantityType, in chartRange: ChartRange) async throws -> [HKQuantitySample]
}
