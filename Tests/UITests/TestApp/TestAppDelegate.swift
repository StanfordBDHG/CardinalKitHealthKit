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
                    HKQuantityType.electrocardiogramType(),
                    deliverySetting: .background(.manual)
                )
                CollectSample(
                    HKQuantityType(.pushCount),
                    deliverySetting: .anchorQuery(.manual)
                )
                CollectSample( //
                    HKQuantityType(.restingHeartRate),
                    deliverySetting: .manual()
                )
                BulkUpload(
                    Set([HKQuantityType(.stepCount)]),
                    predicate: HKQuery.predicateForSamples(
                        withStart: Calendar.current.date(byAdding: .month, value: -1, to: .now),
                        end: Date(),
                        options: .strictEndDate
                    ),
                    bulkSize: 100,
                    deliveryStartSetting: .manual
                )
                BulkUpload(
                    Set([HKQuantityType(.activeEnergyBurned)]),
                    predicate: HKQuery.predicateForSamples(
                        withStart: Calendar.current.date(byAdding: .month, value: -1, to: .now),
                        end: Date(),
                        options: .strictEndDate
                    ),
                    bulkSize: 2,
                    deliveryStartSetting: .automatic
                )
            }
        }
    }
}
