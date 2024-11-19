//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import HealthKit


/// This functionality will be moved to the `HealthKitDataProvider` implementation.
actor MeasurementCache {
    enum CacheError: LocalizedError {
        case entryNotFound
        case entryExpired
        
        var errorDescription: String? {
            switch self {
            case .entryNotFound:
                String(localized: "No entries found for given key.")
            case .entryExpired:
                String(localized: "Entry found in cache has expired.")
            }
        }
    }
    
    struct CacheKey: Hashable {
        let type: HKQuantityType
        let range: ClosedRange<Date>
    }
    
    struct CacheValue {
        let measurements: [HKQuantitySample]
        let timestamp: Date
    }
    
    private var cache: [CacheKey: CacheValue] = [:]
    
    private let maxEntries = 10
    private let ageLimit: TimeInterval = 24 * 60 * 60  // Time limit is one day.
    
    
    func store(_ measurements: [HKQuantitySample], for type: HKQuantityType, range dateRange: ChartRange) {
        let key = CacheKey(type: type, range: dateRange.domain)
        self.cache[key] = CacheValue(measurements: measurements, timestamp: Date())
        
        if self.cache.count > self.maxEntries {
            self.cleanUpOldEntries()
        }
    }
    
    
    func fetch(for type: HKQuantityType, range: ClosedRange<Date>) throws -> [HKQuantitySample] {
        let key = CacheKey(type: type, range: range)
        
        guard let entry = self.cache[key] else {
            // No entry matching the key is in the cache.
            throw CacheError.entryNotFound
        }
        
        guard Date().timeIntervalSince(entry.timestamp) > self.ageLimit else {
            // Entry has been cached for too long -- it has expired.
            cache.removeValue(forKey: key)
            throw CacheError.entryExpired
        }
        
        return entry.measurements
    }
    
    
    private func cleanUpOldEntries() {
        let now = Date()
        self.cache = self.cache.filter { _, value in
            now.timeIntervalSince(value.timestamp) <= self.ageLimit
        }
    }
}
