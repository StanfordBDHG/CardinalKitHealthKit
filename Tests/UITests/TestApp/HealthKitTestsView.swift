//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziHealthKit
import SpeziHealthCharts
import SpeziViews
import SwiftUI


struct HealthKitTestsView: View {
    @Environment(HealthKit.self) var healthKitModule
    @Environment(HealthKitStore.self) var healthKitStore

    @State private var showHealthChart = false
    @State private var chartRange: ChartRange = .month
    
    
    var body: some View {
        List {
            AsyncButton("Ask for authorization") {
                try? await healthKitModule.askForAuthorization()
            }
                .disabled(healthKitModule.authorized)
            AsyncButton("Trigger data source collection") {
                await healthKitModule.triggerDataSourceCollection()
            }
            Section("Collected Samples Since App Launch") {
                ForEach(healthKitStore.samples, id: \.self) { element in
                    Text(element.sampleType.identifier)
                }
            }
            if !HealthKitStore.collectedSamplesOnly {
                Section("Background Persistance Log") {
                    ForEach(healthKitStore.backgroundPersistance, id: \.self) { element in
                        Text(element)
                            .multilineTextAlignment(.leading)
                            .lineLimit(10)
                    }
                }
            }
            Button("Show HealthChart") { showHealthChart.toggle() }
        }
            .sheet(isPresented: $showHealthChart) {
                HealthChart(HKQuantityType(.bodyMass), unit: .pound(), provider: FixedSamplesDataProvider.testProvider)
                    .healthChartInteractions(disabled: .swipe)
                    .padding()
            }
    }
}


#Preview {
    HealthKitTestsView()
        .previewWith(standard: HealthKitTestAppStandard()) {
            HealthKit()
        }
}
