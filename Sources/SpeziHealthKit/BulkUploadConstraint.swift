//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
// Created by Bryant Jimenez and Matthew Joerke

import HealthKit
import Spezi


/// A Constraint which your `Standard` instance must conform to when using the Spezi HealthKit BulkUpload module.
///
///
/// Make sure that your standard in your Spezi Application conforms to the ``BulkUploadConstraint``
/// protocol to upload HealthKit data in configurable bulk sizes.
/// The ``BulkUploadConstraint/processBulk(samplesAdded:samplesDeleted:)`` function is triggered once for every collected batch of HealthKit samples returned by the anchor query.
/// ```swift
/// actor ExampleStandard: Standard, BulkUploadConstraint {
///    // Add the collected batch of HKSamples to your application, as well as any backoff mechanisms (e.g. wait a specific amount after each upload).
///    func add_bulk(sample: HKSample) async {
///        ...
///    }
/// }
/// ```
///
public protocol BulkUploadConstraint: Standard {
    /// Notifies the `Standard` about the addition of a batch of HealthKit ``HKSample`` samples instance.
    /// - Parameter samplesAdded: The batch of `HKSample`s that should be added.
    /// - Parameter objectsDeleted: The batch of `HKSample`s that were deleted from the HealthStore. Included if needed to account for rate limiting
    /// when uploading to a cloud provider.
    func processBulk(samplesAdded: [HKSample], samplesDeleted: [HKDeletedObject]) async
}
