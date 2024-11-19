//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Charts
import HealthKit
import SwiftUI


struct ChartPlot: View {
    let samples: [HKQuantitySample]
    let range: ChartRange
    let unit: HKUnit
    
    
    var body: some View {
        Chart(samples, id: \.self) { sample in
            BarMark(
                x: .value("Date", sample.startDate, unit: range.granularity),
                y: .value("Value", sample.quantity.doubleValue(for: unit))
            )
        }
            .chartXScale(domain: range.domain)
    }
}
