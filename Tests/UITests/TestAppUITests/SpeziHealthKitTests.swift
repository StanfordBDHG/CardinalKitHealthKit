//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import HealthKit
import SpeziHealthKit
import XCTest
import XCTestExtensions
import XCTHealthKit


final class HealthKitTests: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        MainActor.assumeIsolated {
            // After each test, we want the app to get fully reset.
            let app = XCUIApplication(launchArguments: ["--collectedSamplesOnly"])
            app.terminate()
            app.delete(app: "TestApp")
        }
    }
    
    
    @MainActor
    func testTest() throws {
        throw XCTSkip()
        let app = XCUIApplication(launchArguments: ["--collectedSamplesOnly"])
        
        app.launch()
//        XCTAssert(app.textViews["DatePicker Testing Section".uppercased()].waitForExistence(timeout: 5))
//        let datePickers = app.datePickers.allElementsBoundByIndex
//        XCTAssertEqual(datePickers.count, 3)
//        datePickers[1].enterDate(DateComponents(year: 2024, month: 6, day: 2), assumingDatePickerStyle: .compact, in: app)
//        datePickers[2].enterTime(DateComponents(hour: 20, minute: 15), assumingDatePickerStyle: .compact, in: app)
        
        try launchAndAddSamples(healthApp: .healthApp(), [
//            .init(sampleType: .steps, date: nil, enterSampleValueHandler: .enterSimpleNumericValue(520, inTextField: "Steps")),
            .steps(value: 1, date: .init(year: 1998, month: 06, day: 02, hour: 20, minute: 15))
        ])
        
        app.activate()
    }
    
    
    @MainActor
    func testCollectSamples() throws {
        let app = XCUIApplication(launchArguments: ["--collectedSamplesOnly"])
        app.launch()
        
        if app.alerts["“TestApp” Would Like to Send You Notifications"].waitForExistence(timeout: 5) {
            app.alerts["“TestApp” Would Like to Send You Notifications"].buttons["Allow"].tap()
        }
        
        app.buttons["Ask for authorization"].tap()
        try app.handleHealthKitAuthorization()
        
        // At the beginning, we expect nothing to be collected
        assertCollectedSamplesSinceLaunch(in: app, [:])
        // Add a heart rate sample
        try addSample(.heartRate, in: app)
        // Since the CollectSample for heart rate is .manual, it stil shouldn't be there
        assertCollectedSamplesSinceLaunch(in: app, [:])
        // We trigger manual data collection, which should make the sample show up
        triggerDataCollection(in: app)
        assertCollectedSamplesSinceLaunch(in: app, [
            .heartRate: 1
        ])
        
        // Add an active energy burned sample
        try addSample(.activeEnergyBurned, in: app)
        // Since we have a continuous automatic query for these, it should show up immediately.
        assertCollectedSamplesSinceLaunch(in: app, [
            .heartRate: 1,
            .activeEnergyBurned: 1
        ])
        
        // Add a step count sample
        try addSample(.stepCount, in: app)
        // These are collected via an automatic background query, and should therefore also directly show up
        assertCollectedSamplesSinceLaunch(in: app, [
            .heartRate: 1,
            .activeEnergyBurned: 1,
            .stepCount: 1
        ])
        
        // Add a height sample. These aren't collected at all, and should never show up
        try addSample(.height, in: app)
        assertCollectedSamplesSinceLaunch(in: app, [
            .heartRate: 1,
            .activeEnergyBurned: 1,
            .stepCount: 1
        ])
        
        // Add another active energy burned sample. As before, this should show up immediately
        try addSample(.activeEnergyBurned, in: app)
        assertCollectedSamplesSinceLaunch(in: app, [
            .heartRate: 1,
            .activeEnergyBurned: 2,
            .stepCount: 1
        ])
        
        // i'm gonna do it again
        try addSample(.activeEnergyBurned, in: app)
        assertCollectedSamplesSinceLaunch(in: app, [
            .heartRate: 1,
            .activeEnergyBurned: 3,
            .stepCount: 1
        ])
    }
    
    
    @MainActor
    private func addSample(_ sampleType: SampleType<HKQuantitySample>, in app: XCUIApplication) throws {
        app.navigationBars.images["plus"].tap()
        XCTAssert(app.buttons["Add Sample: \(sampleType.displayTitle)"].waitForExistence(timeout: 2))
        app.buttons["Add Sample: \(sampleType.displayTitle)"].tap()
    }
    
    
    @MainActor
    private func triggerDataCollection(in app: XCUIApplication) {
        XCTAssertTrue(app.buttons["Trigger data source collection"].exists)
        app.buttons["Trigger data source collection"].tap()
        XCTAssertTrue(app.buttons["Triggering data source collection"].waitForNonExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Trigger data source collection"].waitForExistence(timeout: 2))
    }
    
    
    typealias NumSamplesByType = [SampleType<HKQuantitySample>: Int]
    
    @MainActor
    private func assertCollectedSamplesSinceLaunch(
        in app: XCUIApplication,
        _ expectedNumSamplesBySampleType: NumSamplesByType,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        func imp(try: Int) {
            print("APP \(app.debugDescription)")
            let staticTexts = app.staticTexts.count > 0 ? app.staticTexts.allElementsBoundByIndex.map(\.label) : []
            print("imp(try: \(`try`)) ALL STATIC TEXTS: \(staticTexts)")
            guard `try` > 0 else {
                XCTFail("Unable to check (staticTexts: \(staticTexts))", file: file, line: line)
                return
            }
            guard staticTexts.count > 0 else {
                sleep(2)
                return imp(try: `try` - 1)
            }
            let actual = staticTexts
                .filter { $0.wholeMatch(of: /HK[a-zA-Z]*/) != nil }
                .grouped(by: \.self)
                .mapValues(\.count)
            let expected = Dictionary(uniqueKeysWithValues: expectedNumSamplesBySampleType.map { ($0.hkSampleType.identifier, $1) })
            if expected != actual, `try` > 1 {
                // try again
                sleep(2)
                return imp(try: `try` - 1)
            } else {
                XCTAssertEqual(actual, expected, file: file, line: line)
            }
        }
        imp(try: 5)
    }
    
    
    @MainActor
    func testRepeatedHealthKitAuthorization() throws {
        throw XCTSkip()
        let app = XCUIApplication(launchArguments: ["--collectedSamplesOnly"])
//        let app = XCUIApplication()
//        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
        app.launch()
        
//        app.activate()
        XCTAssert(app.buttons["Ask for authorization"].waitForExistence(timeout: 2))
        XCTAssert(app.buttons["Ask for authorization"].isEnabled)
        app.buttons["Ask for authorization"].tap()
        
        try app.handleHealthKitAuthorization()
        
        // Wait for button to become disabled
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                !app.buttons["Ask for authorization"].isEnabled
            },
            object: .none
        )
        wait(for: [expectation], timeout: 2)
        
        XCTAssert(!app.buttons["Ask for authorization"].isEnabled)
    }
}


extension XCUIApplication {
    convenience init(launchArguments: [String]) {
        self.init()
        self.launchArguments.append(contentsOf: launchArguments)
    }
}
