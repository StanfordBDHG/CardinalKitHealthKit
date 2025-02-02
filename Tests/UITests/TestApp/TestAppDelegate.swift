//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziHealthKit


class TestAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: HealthKitTestAppStandard()) {
            HealthKit {
                CollectSample(
                    .electrocardiogram,
                    start: .manual,
                    continueInBackground: true
                )
                CollectSample(
                    .stepCount,
                    start: .automatic,
                    continueInBackground: true
                )
                CollectSample(
                    .pushCount,
                    start: .manual
                )
                CollectSample(
                    .activeEnergyBurned
                )
                CollectSample(.heartRate, start: .automatic)
                CollectSample(.heartRate, start: .automatic)
                
                RequestReadAccess(
                    quantity: [.bloodOxygen],
                    correlation: [.bloodPressure],
                    characteristic: [.activityMoveMode, .biologicalSex, .bloodType, .dateOfBirth, .fitzpatrickSkinType, .wheelchairUse]
                )
                
                RequestWriteAccess(
                    quantity: [.heartRate, .bloodOxygen, .stepCount, .height, .activeEnergyBurned]
                )
            }
        }
    }
}
