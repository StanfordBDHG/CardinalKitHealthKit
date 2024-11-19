//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import HealthKit


/// A provider that interfaces to a fixed array of samples.
public final class FixedSamplesDataProvider: DataProvider {
    private let samples: [HKQuantitySample]
    
    
    /// Returns the samples contained in the `FixedSamplesDataProvider` that fall completely in the given `chartRange`
    /// and whose `HKQuantityType` matches the provided `measurementType`.
    public func fetchData(for measurementType: HKQuantityType, in chartRange: ChartRange) async throws -> [HKQuantitySample] {
        samples.filter {
            $0.quantityType == measurementType &&
            chartRange.domain.contains($0.startDate) &&  // Both start and end date must lie in the `chartRange`.
            chartRange.domain.contains($0.endDate)
        }
    }
    
    
    public init(samples: [HKQuantitySample]) {
        self.samples = samples
    }
    
    
    public static let testProvider = FixedSamplesDataProvider(
        samples: [
            HKQuantitySample(
                type: HKQuantityType(.bodyMass),
                quantity: HKQuantity(unit: .pound(), doubleValue: 150),
                start: .now,
                end: .now.addingTimeInterval(60)
            )
        ]
    )
}
