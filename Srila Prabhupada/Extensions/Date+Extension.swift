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

    var startOfDay: Date {
        Self.gregorianCalendar.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Self.gregorianCalendar.date(byAdding: components, to: startOfDay) ?? self
    }

    var startOfWeek: Date? {

        guard let sunday = Self.gregorianCalendar.date(from: Self.gregorianCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return Self.gregorianCalendar.date(byAdding: .day, value: 1, to: sunday)
    }

    var endOfWeek: Date? {
        guard let sunday = Self.gregorianCalendar.date(from: Self.gregorianCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return Self.gregorianCalendar.date(byAdding: .day, value: 7, to: sunday)
    }

    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: startOfDay)
        return Calendar.current.date(from: components) ?? self
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    func adding(_ component: Calendar.Component, value: Int) -> Date? {
        return Self.gregorianCalendar.date(byAdding: component, value: value, to: self)
    }
}
