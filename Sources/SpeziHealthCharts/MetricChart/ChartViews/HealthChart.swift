//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI
import HealthKit


public struct HealthChart: View {
    @State private var privateRange: ChartRange
    private var privateRangeBinding: Binding<ChartRange>?
    
    var range: Binding<ChartRange> {
        Binding(
            get: {
                privateRangeBinding?.wrappedValue ?? privateRange
            }, set: { newValue in
                if let privateRangeBinding {
                    privateRangeBinding.wrappedValue = newValue
                } else {
                    privateRange = newValue
                }
            }
        )
    }
    
    private let quantityType: HKQuantityType
    private let dataProvider: any DataProvider
    private let sampleUnits: HKUnit
    
    
    public var body: some View {
        InternalHealthChart(quantityType, range: range, unit: sampleUnits, provider: dataProvider)
    }
    
    
    public init(
        _ type: HKQuantityType,
        in initialRange: ChartRange = .month,
        unit: HKUnit,
        provider: any DataProvider = HealthKitDataProvider()
    ) {
        assert(type.is(compatibleWith: unit), "Provided HKUnits must be compatible with the target HKQuantityType.")
        
        self.quantityType = type
        self.privateRange = initialRange
        self.dataProvider = provider
        self.sampleUnits = unit
    }
    
    public init(
        _ type: HKQuantityType,
        range: Binding<ChartRange>,
        unit: HKUnit,
        provider: any DataProvider = HealthKitDataProvider()
    ) {
        assert(type.is(compatibleWith: unit), "Provided HKUnits must be compatible with the target HKQuantityType.")
        
        self.privateRange = range.wrappedValue
        self.privateRangeBinding = range
        self.quantityType = type
        self.sampleUnits = unit
        self.dataProvider = provider
    }
    
    public init(
        _ samples: [HKQuantitySample],
        type: HKQuantityType,
        range: ChartRange,
        unit: HKUnit
    ) {
        assert(type.is(compatibleWith: unit), "Provided HKUnits must be compatible with the target HKQuantityType.")
        
        self.privateRange = range
        self.quantityType = type
        self.sampleUnits = unit
        self.dataProvider = FixedSamplesDataProvider(samples: samples)
    }
}
