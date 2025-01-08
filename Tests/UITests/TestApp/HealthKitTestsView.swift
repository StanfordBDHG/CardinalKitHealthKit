//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziHealthKit
import SpeziViews
import SwiftUI


struct HealthKitTestsView: View {
    @Environment(HealthKit.self) var healthKitModule
    @Environment(HealthKitStore.self) var healthKitStore
    var toShareSampleTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!
    ]
    var toReadSampleTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.electrocardiogramType(),
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .pushCount)!
    ]
    let HKStore = HKHealthStore()
    
    var body: some View {
        List {
            AsyncButton("Ask for authorization") {
                try? await healthKitModule.askForAuthorization()
            }
                .disabled(healthKitModule.authorized)
            AsyncButton("Inject Step Count Data") {
                await injectStepCountData()   
            }
            AsyncButton("Trigger data source collection") {
                await healthKitModule.triggerDataSourceCollection()
            }
            Section( String(healthKitStore.samples.count) + " Collected Samples Since App Launch") {
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
        }
    }
    
    func injectStepCountData() async {
        try? await HKStore.requestAuthorization(toShare: toShareSampleTypes, read: [])
        
        // Generate sample data
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("Step count quantity type not available.")
            return
        }
//        let HKStore = HKHealthStore()
//        
//        try? await HKStore.requestAuthorization(toShare: toShareSampleTypes, read: [])
        
        // Subtract 5 minutes from the current date
        guard let startDate = Calendar.current.date(byAdding: .minute, value: -5, to: Date()) else {
            fatalError("Error: Could not calculate start date")
        }

        // Add 2 minutes to the start date
        guard let endDate = Calendar.current.date(byAdding: .minute, value: 2, to: startDate) else {
            fatalError("Error: Could not calculate end date")
        }
        
        for num in 1...500 {
            let quantity = HKQuantity(unit: .count(), doubleValue: Double(num)) // Simulated step count
            let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: startDate, end: endDate)
            try await HKStore.save(sample) {success, error in
                if let error = error {
                    print("Error saving step count: \(error.localizedDescription)")
                } else {
                    print("Step count saved successfully.")
                }
            }
        }
    }
}


#if DEBUG
#Preview {
    List {
        AsyncButton("Ask for authorization") {
        }
        AsyncButton("Trigger data source collection") {
        }
        Section("Collected Samples Since App Launch") {
        }
    }
    
}

#endif
