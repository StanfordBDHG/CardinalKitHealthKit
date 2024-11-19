//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


extension EnvironmentValues {
    @Entry var healthChartStyle: HealthChartStyle = .default
}


extension View {
    // TODO: Add argument here to control how we combine styles (e.g. .override, .combine, etc.)
    public func style(_ newValue: HealthChartStyle) -> some View {
        environment(\.healthChartStyle, newValue)
    }
}
