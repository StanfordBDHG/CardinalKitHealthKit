//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension UserDefaults {
    enum Keys {
        static let healthKitRequestedSampleTypes = "Spezi.HealthKit.RequestedSampleTypes"
        static let healthKitAnchorPrefix = "Spezi.HealthKit.Anchors."
        static let healthKitDefaultPredicateDatePrefix = "Spezi.HealthKit.DefaultPredicateDate."
        static let bulkUploadAnchorPrefix = "Spezi.BulkUpload.Anchors."
        static let bulkUploadTotalSamplesPrefix = "Spezi.BulkUpload.Total."
        static let bulkUploadProcessedSamplesPrefix = "Spezi.BulkUpload.Processed."
        static let bulkUploadDefaultPredicateDatePrefix = "Spezi.BulkUpload.DefaultPredicateDate."
    }
}
