//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziHealthKit
import SwiftUI


struct StatisticsQueryView: View {
    @Environment(HealthKit.self) private var healthKit
    
    @HealthKitQuery(.heartRate, timeRange: .currentWeek)
    private var heartRateSamples
    
    @HealthKitStatisticsQuery(.stepCount, aggregatedBy: [.sum], over: .day, timeRange: .currentWeek)
    private var dailyStepCountStats
    
    var body: some View {
        Form {
            Section {
                HealthChart {
                    HealthChartEntry($heartRateSamples, drawingConfig: .init(mode: .line, color: .red))
//                    HealthChartEntry($dailyStepCountStats, aggregationOption: .sum, drawingConfig: .init(mode: .bar, color: .orange))
                }
                .frame(height: 300)
            }
            ForEach(dailyStepCountStats.reversed()) { statistics in
                if let numSteps = statistics.sumQuantity()?.doubleValue(for: .count()) {
                    HStack {
                        Text("Steps on \((statistics.startDate...statistics.endDate).middle.formatted(.iso8601))")
                        Spacer()
                        Text("\(Int(numSteps))").monospaced()
                    }
                }
            }
        }
        .navigationTitle("Statistics Query")
    }
}


extension ClosedRange where Bound == Date {
    var middle: Date {
        lowerBound.addingTimeInterval(lowerBound.distance(to: upperBound) / 2)
    }
}
