//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


public struct HealthChartStyle: Sendable {
    let frameSize: CGFloat
    
    
    public init(idealHeight: CGFloat = 200.0) {
        frameSize = idealHeight
    }
    
    
    public static let `default` = HealthChartStyle()
}

