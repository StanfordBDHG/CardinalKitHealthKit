//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@preconcurrency import HealthKit
import Spezi


extension HKSample: @retroactive Identifiable {
    /// The `uuid` identifier.
    public var id: UUID {
        uuid
    }
}

extension HKHealthStore {
    @MainActor
    func anchoredSingleObjectQuery(
        for sampleType: HKSampleType,
        using anchor: HKQueryAnchor?,
        withPredicate predicate: NSPredicate?,
        standard: any HealthKitConstraint
    ) async throws -> HKQueryAnchor {
        let anchorDescriptor = anchorDescriptor(sampleType: sampleType, predicate: predicate, anchor: anchor)
        let result = try await anchorDescriptor.result(for: self)
        for deletedObject in result.deletedObjects {
            await standard.remove(sample: deletedObject)
        }
        for addedSample in result.addedSamples {
            await standard.add(sample: addedSample)
        }
        return result.newAnchor
    }
    
    
    func anchorDescriptor(
        sampleType: HKSampleType,
        predicate: NSPredicate?,
        anchor: HKQueryAnchor?
    ) -> HKAnchoredObjectQueryDescriptor<HKSample> {
        HKAnchoredObjectQueryDescriptor(
            predicates: [
                .sample(type: sampleType, predicate: predicate)
            ],
            anchor: anchor
        )
    }
}
