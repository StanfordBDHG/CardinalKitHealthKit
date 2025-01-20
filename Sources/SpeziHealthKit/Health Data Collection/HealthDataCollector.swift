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


/// A data collector that continuously, over the lifetime of the application, collects samples and/or other data from the HealthKit database.
///
/// - Tip: The ``CollectSample`` configuration component provides an easy means for adding such data collection to an app.
///     In most cases, it shouldn't be necessary to define and implement a custom data collector.
///
/// Custom `HealthDataCollector`s can be registered with the ``HealthKit-swift.class`` module
/// using ``HealthKit-swift.class/addHealthDataCollector(_:)``.
/// The ``HealthKit-swift.class`` module will establish a strong reference to the collector,
/// which will exist for the entire lifetime of the application.
public protocol HealthDataCollector: AnyObject {
    /// The data collector's sample type
    var sampleType: HKSampleType { get }
    
    /// The data collector's delivery setting.
    ///
    /// This determines when and how the collector is started once it has been registered with the ``HealthKit-swift.class`` module:
    /// - if the collector defines an automatic delivery setting, the collector will be told to start its data collection as soon as it is registered and the user
    ///     was asked to grant access to the collector's ``sampleType``
    /// - if the collector defines a manual delivery setting, it will be started the first time the application calls ``HealthKit-swift.class/triggerDataSourceCollection()``
    var delivery: HealthDataCollectorDeliverySetting { get }
    
    /// Whether the data collector is currently active.
    @MainActor
    var isActive: Bool { get }
    
    /// Called to inform the collector that it should start collecting data.
    ///
    /// Whether this results in a long-lived query being initiated, or a one-shot fetch, depends on the collector's specific ``delivery`` configuration.
    @MainActor
    func startDataCollection() async
}
