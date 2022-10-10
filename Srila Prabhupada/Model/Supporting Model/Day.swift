//
//  File.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import Foundation

struct Day: Hashable, Codable, Comparable {
    static func < (lhs: Day, rhs: Day) -> Bool {
        guard lhs.year == rhs.year else {
            return lhs.year < rhs.year
        }

        guard lhs.month == rhs.month else {
            return lhs.month < rhs.month
        }

        guard lhs.day == rhs.day else {
            return lhs.day < rhs.day
        }

        return true
    }

    let day: Int
    let month: Int
    let year: Int

    private let dateComponents: DateComponents

    init(day: Int, month: Int, year: Int) {
        self.day = day
        self.month = month
        self.year = year
        dateComponents = DateComponents(year: year, month: month, day: day)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let value = try? container.decode(String.self, forKey: .day), let valueInt = Int(value) {
            day = valueInt
        } else if let value = try? container.decode(Int.self, forKey: .day) {
            day = value
        } else {
            day = 0
        }

        if let value = try? container.decode(String.self, forKey: .month), let valueInt = Int(value) {
            month = valueInt
        } else if let value = try? container.decode(Int.self, forKey: .month) {
            month = value
        } else {
            month = 0
        }

        if let value = try? container.decode(String.self, forKey: .year), let valueInt = Int(value) {
            year = valueInt
        } else if let value = try? container.decode(Int.self, forKey: .year) {
            year = value
        } else {
            year = 0
        }
        dateComponents = DateComponents(year: year, month: month, day: day)
    }

    var display_yyyy_mm_dd: String {
        "\(year)/\(month)/\(day)"
    }

    var display_dd_MMM_yyyy: String {
        guard let date = dateComponents.date else {
            return "\(day)-\(month)-\(year)"
        }
        return DateFormatter.dd_MMM_yyyy.string(from: date)
    }
}
