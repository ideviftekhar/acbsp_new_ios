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

    static var lastWeekDates: [String] {

        guard let endOfWeek = Date().startOfWeek else {
            return []
        }
        var startOfWeek = Date().startOfWeek
        startOfWeek = Date.gregorianCalendar.date(byAdding: .day, value: -7, to: startOfWeek!)
        var weekDates: [String] = []

        while let day = startOfWeek, day < endOfWeek {
            let dateString = DateFormatter.d_M_yyyy.string(from: day)
            weekDates.append(dateString)
            startOfWeek = Date.gregorianCalendar.date(byAdding: .day, value: 1, to: day)
        }
        return weekDates

    }

    static var currentWeekDates: [String] {

        guard let endOfWeek = Date().endOfWeek else {
            return []
        }

        var startOfWeek = Date().startOfWeek

        var weekDates: [String] = []

        while let day = startOfWeek, day <= endOfWeek {
            let dateString = DateFormatter.d_M_yyyy.string(from: day)
            weekDates.append(dateString)
            startOfWeek = Date.gregorianCalendar.date(byAdding: .day, value: 1, to: day)
        }
        return weekDates
    }

    static var lastSevenDaysDates: [String] {

        let endOfWeek = Date()

        var startOfWeek: Date? = endOfWeek.adding(.day, value: -6)

        var weekDates: [String] = []

        while let day = startOfWeek, day <= endOfWeek {
            let dateString = DateFormatter.d_M_yyyy.string(from: day)
            weekDates.append(dateString)
            startOfWeek = Date.gregorianCalendar.date(byAdding: .day, value: 1, to: day)
        }
        return weekDates
    }
}
