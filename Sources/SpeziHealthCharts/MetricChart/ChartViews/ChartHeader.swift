//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct ChartHeader: View {
    @Binding var range: ChartRange
    
    
    var body: some View {
        Picker("Date", selection: $range) {
            Text("D").tag(ChartRange.day)
            Text("W").tag(ChartRange.week)
            Text("M").tag(ChartRange.month)
            Text("6M").tag(ChartRange.sixMonths)
            Text("Y").tag(ChartRange.year)
        }
            .pickerStyle(.segmented)
    }
}
