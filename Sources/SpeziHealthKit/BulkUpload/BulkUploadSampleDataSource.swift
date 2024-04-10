//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
// Created by Bryant Jimenez and Matthew Joerke

import HealthKit
import OSLog
import Spezi
import SwiftUI


final class BulkUploadSampleDataSource: HealthKitDataSource {
    let healthStore: HKHealthStore
    let standard: any BulkUploadConstraint
    
    let sampleType: HKSampleType
    let predicate: NSPredicate?
    let deliverySetting: HealthKitDeliverySetting
    let bulkSize: Int
    var active = false
    
    
    private lazy var anchorUserDefaultsKey = UserDefaults.Keys.bulkUploadAnchorPrefix.appending(sampleType.identifier)
    private lazy var anchor: HKQueryAnchor? = loadAnchor() {
        didSet {
            saveAnchor()
        }
    }
    
    
    // We disable the SwiftLint as we order the parameters in a logical order and
    // therefore don't put the predicate at the end here.
    // swiftlint:disable function_default_parameter_at_end
    required init(
        healthStore: HKHealthStore,
        standard: any BulkUploadConstraint,
        sampleType: HKSampleType,
        predicate: NSPredicate,
        deliverySetting: HealthKitDeliverySetting,
        bulkSize: Int
    ) {
        self.healthStore = healthStore
        self.standard = standard
        self.sampleType = sampleType
        self.deliverySetting = deliverySetting
        self.bulkSize = bulkSize
        self.predicate = predicate
    }
    // swiftlint:enable function_default_parameter_at_end
    
    func askedForAuthorization() async {
        guard askedForAuthorization(for: sampleType) && !deliverySetting.isManual && !active else {
            return
        }
        
        await triggerManualDataSourceCollection()
    }
    
    func startAutomaticDataCollection() async {
        guard askedForAuthorization(for: sampleType) else {
            return
        }
        
        switch deliverySetting {
        case let .anchorQuery(startSetting, _) where startSetting == .automatic:
            await triggerManualDataSourceCollection()
        default:
            break
        }
    }
    
    func triggerManualDataSourceCollection() async {
        guard !active else {
            return
        }
        
        do {
            active = true
            try await anchoredBulkUploadQuery()
        } catch {
            Logger.healthKit.error("Could not Process HealthKit data collection: \(error.localizedDescription)")
        }
    }
    
    
    private func anchoredBulkUploadQuery() async throws {
        try await healthStore.requestAuthorization(toShare: [], read: [sampleType])
        var totalSamples: Int = 0

        // Initial query to fetch the total count of samples
        let countQuery = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: HKObjectQueryNoLimit,
                                       sortDescriptors: nil) { (query, results, error) in
            guard let samples = results else {
                print("Could not retrieve samples of current sample type")
                print(self.sampleType)
                return
            }
            // Here you can store the total count
            totalSamples = samples.count
            print("inside countQuery")
            print(totalSamples)
        }
        healthStore.execute(countQuery)
        
        
        // create an anchor descriptor that reads a data batch of the defined bulkSize
        var anchorDescriptor = HKAnchoredObjectQueryDescriptor(
            predicates: [
                .sample(type: sampleType, predicate: predicate)
            ],
            anchor: anchor,
            limit: bulkSize
        )
        
        // run query at least once
        var result = try await anchorDescriptor.result(for: healthStore)
        
        // continue reading bulkSize batches of data until theres no new data
        repeat {
            await standard.processBulk(samplesAdded: result.addedSamples, samplesDeleted: result.deletedObjects)
            
            // advance the anchor
            anchor = result.newAnchor
            
            anchorDescriptor = HKAnchoredObjectQueryDescriptor(
                predicates: [
                    .sample(type: sampleType, predicate: predicate)
                ],
                anchor: anchor,
                limit: bulkSize
            )
            result = try await anchorDescriptor.result(for: healthStore)
        } while (!result.addedSamples.isEmpty) || (!result.deletedObjects.isEmpty)
    }
    
    private func saveAnchor() {
        if deliverySetting.saveAnchor {
            guard let anchor,
                  let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true) else {
                return
            }
            
            UserDefaults.standard.set(data, forKey: anchorUserDefaultsKey)
        }
    }
    
    private func loadAnchor() -> HKQueryAnchor? {
        guard deliverySetting.saveAnchor,
              let userDefaultsData = UserDefaults.standard.data(forKey: anchorUserDefaultsKey),
              let loadedAnchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: userDefaultsData) else {
            return nil
        }
        
        return loadedAnchor
    }
}
