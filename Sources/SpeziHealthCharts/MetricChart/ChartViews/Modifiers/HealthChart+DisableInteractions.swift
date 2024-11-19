//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


extension EnvironmentValues {
    @Entry var disabledChartInteractions: HealthChartInteractions = []
}


extension View {
    public func healthChartInteractions(disabled disabledValues: HealthChartInteractions) -> some View {
        // TODO: Handle reduction - get current value from environment, combine with new value, and inject back into environment.
        environment(\.disabledChartInteractions, disabledValues)
    }
}
