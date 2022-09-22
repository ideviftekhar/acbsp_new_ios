//
//  Date+Extension.swift
//  Srila Prabhupada
//
//  Created by IE on 9/22/22.
//

import Foundation

extension Date {

    static let gregorianCalenar = Calendar(identifier: .gregorian)

    var startOfWeek: Date? {

        guard let sunday = Self.gregorianCalenar.date(from: Self.gregorianCalenar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return Self.gregorianCalenar.date(byAdding: .day, value: 1, to: sunday)
    }

    var endOfWeek: Date? {
        guard let sunday = Self.gregorianCalenar.date(from: Self.gregorianCalenar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return Self.gregorianCalenar.date(byAdding: .day, value: 7, to: sunday)
    }
}
