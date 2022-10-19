//
//  Date+Extension.swift
//  Srila Prabhupada
//
//  Created by IE on 9/22/22.
//

import Foundation

extension Date {

    static let gregorianCalendar = Calendar(identifier: .gregorian)

    func components(_ components: Calendar.Component...) -> DateComponents {
        return Self.gregorianCalendar.dateComponents(Set(components), from: self)
    }

    func component(_ component: Calendar.Component) -> Int {
        return Self.gregorianCalendar.component(component, from: self)
    }

    var startOfWeek: Date? {

        guard let sunday = Self.gregorianCalendar.date(from: Self.gregorianCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return Self.gregorianCalendar.date(byAdding: .day, value: 1, to: sunday)
    }

    var endOfWeek: Date? {
        guard let sunday = Self.gregorianCalendar.date(from: Self.gregorianCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return Self.gregorianCalendar.date(byAdding: .day, value: 7, to: sunday)
    }
}
