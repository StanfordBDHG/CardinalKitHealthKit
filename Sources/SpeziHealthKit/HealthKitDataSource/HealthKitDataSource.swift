//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import Spezi
import SwiftUI


/// Requirement for every HealthKit Data Source.
public protocol HealthKitDataSource {
    /// Called after the used was asked for authorization.
    func askedForAuthorization()
    /// Called to trigger the manual data collection.
    func triggerManualDataSourceCollection() async
    /// Called to start the automatic data collection.
    func startAutomaticDataCollection()
}


extension HealthKitDataSource {
    func askedForAuthorization(for sampleType: HKSampleType) -> Bool {
        let requestedSampleTypes = Set(UserDefaults.standard.stringArray(forKey: UserDefaults.Keys.healthKitRequestedSampleTypes) ?? [])
        return requestedSampleTypes.contains(sampleType.identifier)
    }
}
