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
import OSLog

@Observable
final class BulkUploadSampleDataSource: HealthKitDataSource {
    let healthStore: HKHealthStore
    let standard: any BulkUploadConstraint
    
    let sampleType: HKSampleType
    let predicate: NSPredicate?
    let deliverySetting: HealthKitDeliverySetting
    let bulkSize: Int
    var active = false
    var totalSamples: Int = 0
    var processedSamples: Int = 0 {
        didSet {
            saveProcessedSamples()
        }
    }
    
    // lazy variables cannot be observable
    @ObservationIgnored private lazy var anchorUserDefaultsKey = UserDefaults.Keys.bulkUploadAnchorPrefix.appending(sampleType.identifier)
    @ObservationIgnored private lazy var totalSamplesKey = UserDefaults.Keys.bulkUploadTotalSamplesPrefix.appending(sampleType.identifier)
    @ObservationIgnored private lazy var processedSamplesKey = UserDefaults.Keys.bulkUploadProcessedSamplesPrefix.appending(sampleType.identifier)
    @ObservationIgnored private lazy var anchor: HKQueryAnchor? = loadAnchor() {
        didSet {
            saveAnchor()
        }
    }
    
    public var progress: Progress {
        let progress = Progress(totalUnitCount: Int64(totalSamples))
        progress.completedUnitCount = Int64(processedSamples)
        return progress
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
        Logger.healthKit.debug("BulkUpload(\(self.sampleType)): askedForAuthorization()")
        guard askedForAuthorization(for: sampleType) && !deliverySetting.isManual && !active else {
            return
        }
        
        Task.detached {
            await self.triggerManualDataSourceCollection()
        }
    }
    
    func startAutomaticDataCollection() async {
        Logger.healthKit.debug("BulkUpload(\(self.sampleType)): startAutomaticDataCollection()")
        guard askedForAuthorization(for: sampleType) else {
            return
        }
        
        switch deliverySetting {
        case let .anchorQuery(startSetting, _) where startSetting == .automatic:
            await self.triggerManualDataSourceCollection()
        default:
            break
        }
    }
    
    func triggerManualDataSourceCollection() async {
        Logger.healthKit.debug("BulkUpload(\(self.sampleType)): triggerManualDataSourceCollection()")
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
        
        await loadTotalSamplesOnce()
        self.processedSamples = loadProcessedSamples()
        Logger.healthKit.debug("BulkUpload(\(self.sampleType)): beginning/resuming anchoredBulkUploadQuery with progress: \(self.processedSamples)/\(self.totalSamples)")
        
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
            self.processedSamples += result.addedSamples.count + result.deletedObjects.count
            Logger.healthKit.debug("BulkUpload(\(self.sampleType)): processed \(self.processedSamples)/\(self.totalSamples)")
            
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
        Logger.healthKit.debug("BulkUpload(\(self.sampleType)): saving anchor...")
        if deliverySetting.saveAnchor {
            guard let anchor,
                  let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true) else {
                Logger.healthKit.warning("Failed to save anchor")
                return
            }
            
            UserDefaults.standard.set(data, forKey: anchorUserDefaultsKey)
        }
        Logger.healthKit.debug("BulkUpload(\(self.sampleType): saved anchor")
    }
    
    private func loadAnchor() -> HKQueryAnchor? {
        Logger.healthKit.debug("BulkUpload(\(self.sampleType)): loading anchor...")
        guard deliverySetting.saveAnchor,
              let userDefaultsData = UserDefaults.standard.data(forKey: anchorUserDefaultsKey),
              let loadedAnchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: userDefaultsData) else {
            Logger.healthKit.warning("Failed to load anchor")
            return nil
        }
        Logger.healthKit.debug("BulkUpload(\(self.sampleType)): loaded anchor")
        return loadedAnchor
    }
    
    private func loadTotalSamplesOnce() async {
        let cachedTotal = UserDefaults.standard.integer(forKey: totalSamplesKey)
        if cachedTotal != 0 { // user defaults to 0 if key is missing
            self.totalSamples = cachedTotal
        } else {
            Logger.healthKit.debug("Executing HKQuery for \(self.sampleType) to compute initial bulk upload count...")
            do {
                let descriptor = HKSampleQueryDescriptor(
                    predicates: [
                        .sample(type: sampleType, predicate: predicate)
                    ],
                    sortDescriptors: []
                )
                let results = try await descriptor.result(for: healthStore)
                let count = results.count
                UserDefaults.standard.set(count, forKey: totalSamplesKey)
                self.totalSamples = count
                Logger.healthKit.debug("Fetched total count for \(self.sampleType): \(self.totalSamples)")
            } catch {
                Logger.healthKit.error("Error computing total size of bulk upload: could not retrieve samples of current sample type: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveProcessedSamples() {
        UserDefaults.standard.set(processedSamples, forKey: processedSamplesKey)
    }
    
    private func loadProcessedSamples() -> Int {
        return UserDefaults.standard.integer(forKey: processedSamplesKey)
    }
}
