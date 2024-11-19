//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// A `ChartRange` is the date domain of the x-axis of a `HealthChart`.
public struct ChartRange: Sendable, Equatable, Hashable {
    public var domain: ClosedRange<Date>
    public var granularity: Calendar.Component  // Granularity ranges from `.hour` to `.month`
    
    
    public init(start: Date, end: Date, granularity: Calendar.Component) {
        self.domain = start...end
        self.granularity = granularity
    }
    
    public init(_ domain: ClosedRange<Date>, granularity: Calendar.Component) {
        self.domain = domain
        self.granularity = granularity
    }
    
    
    /// The last 24 hours relative to the current time, with a granularity of `.hour`.
    public static let day: ChartRange = {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end
        
        return ChartRange(start: start, end: end, granularity: .hour).rounded()
    }()
    
    /// The last 7 days relative to the current time, with a granularity of `.day`.
    public static let week: ChartRange = {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -7, to: end) ?? end
        
        return ChartRange(start: start, end: end, granularity: .day).rounded()
    }()
    
    /// The last month relative to the current time, with a granularity of `.day`.
    public static let month: ChartRange = {
        let end = Date()
        let start = Calendar.current.date(byAdding: .month, value: -1, to: end) ?? end
        
        return ChartRange(start: start, end: end, granularity: .day).rounded()
    }()
    
    /// The last six months relative to the current time, with a granularity of `.weekOfYear`.
    public static let sixMonths: ChartRange = {
        let end = Date()
        let start = Calendar.current.date(byAdding: .month, value: -6, to: end) ?? end
        
        return ChartRange(start: start, end: end, granularity: .weekOfYear).rounded()
    }()
    
    /// The last year relative to the current time, with a granularity of `.month`.
    public static let year: ChartRange = {
        let end = Date()
        let start = Calendar.current.date(byAdding: .year, value: -1, to: end) ?? end
        
        return ChartRange(start: start, end: end, granularity: .month).rounded()
    }()
}


// TODO: Look at this and match the functionality to what we see in the Health App.
extension ChartRange {
    /// Rounds the domain boundaries to complete units of the specified granularity.
    /// For example, if granularity is `.hour`, the domain will be extended to the nearest hour.
    private func roundedDomain(calendar: Calendar) -> ClosedRange<Date> {
        let components: Set<Calendar.Component> = {
            switch self.granularity {
            case .hour:
                return [.year, .month, .day, .hour]
            case .day:
                return [.year, .month, .day]
            case .weekOfYear, .weekOfMonth:
                return [.yearForWeekOfYear, .weekOfYear]
            case .month:
                return [.year, .month]
            case .year:
                return [.year]
            default:
                return []
            }
        }()
        
        let startComponents = calendar.dateComponents(components, from: self.domain.lowerBound)
        let endComponents = calendar.dateComponents(components, from: self.domain.upperBound)
        
        let roundedStart = calendar.date(from: startComponents) ?? self.domain.lowerBound
        
        // For the upper bound, we want to go to the end of the component.
        let endComponentStart = calendar.date(from: endComponents) ?? self.domain.upperBound
        let roundedEnd = calendar.date(byAdding: self.granularity, value: 1, to: endComponentStart) ?? self.domain.upperBound
        
        return roundedStart...roundedEnd
    }
    
    /// Creates a new `ChartRange` with domain boundaries rounded to complete granularity units.
    public func rounded(using calendar: Calendar = .current) -> ChartRange {
        ChartRange(self.roundedDomain(calendar: calendar), granularity: self.granularity)
    }
}
