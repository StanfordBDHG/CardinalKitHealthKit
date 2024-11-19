//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


public struct HealthChartInteractions: OptionSet, Sendable {
    public let rawValue: Int
    
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    
    public static let swipe: HealthChartInteractions = HealthChartInteractions(rawValue: 1 << 0)
    public static let tap: HealthChartInteractions = HealthChartInteractions(rawValue: 1 << 1)
    
    public static let all: HealthChartInteractions = [.tap, .swipe]
}
