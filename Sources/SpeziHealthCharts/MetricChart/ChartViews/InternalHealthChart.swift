//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Charts
import HealthKit
import SpeziViews
import SwiftUI


struct InternalHealthChart: View {
    @Binding private var range: ChartRange
    @State private var samples: [HKQuantitySample] = []
    
    @State private var viewState: ViewState = .idle
    
    
    @Environment(\.disabledChartInteractions) private var disabledInteractions
    @Environment(\.healthChartStyle) private var chartStyle
    
    
    private let quantityType: HKQuantityType
    private let dataProvider: any DataProvider
    private let unit: HKUnit
    
    
    var body: some View {
        Group {
            if viewState == .idle {
                VStack {
                    ChartHeader(range: $range)
                    ChartPlot(samples: samples, range: range, unit: unit)
                }
            } else {
                ProgressView("Fetching Data...")
            }
        }
            .applyHealthChartStyle(chartStyle)
            .onChange(of: range) { _, newRange in
                Task { @MainActor in
                    do {
                        self.samples = try await self.dataProvider.fetchData(for: quantityType, in: newRange)
                    } catch {
                        self.viewState = .error(
                            AnyLocalizedError(
                                error: error,
                                defaultErrorDescription: "Failed to fetch samples."
                            )
                        )
                    }
                }
            }
            .task {
                do {
                    self.samples = try await self.dataProvider.fetchData(for: quantityType, in: range)
                } catch {
                    self.viewState = .error(
                        AnyLocalizedError(
                            error: error,
                            defaultErrorDescription: "Failed to fetch samples."
                        )
                    )
                }
            }
            .viewStateAlert(state: $viewState)
    }
    
    
    init(
        _ type: HKQuantityType,
        range: Binding<ChartRange>,
        unit: HKUnit,
        provider: any DataProvider = HealthKitDataProvider()
    ) {
        self._range = range
        self.quantityType = type
        self.dataProvider = provider
        self.unit = unit
    }
}
