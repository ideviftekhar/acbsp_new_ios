//
//  StatsType.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 11/2/22.
//

import Foundation

public enum StatsType: String, CaseIterable {

    case today = "Today"
    case oneWeek = "1 Week"
    case oneMonth = "1 Month"
    case oneYear = "1 Year"
    case thisWeek = "This Week"
    case lastWeek = "Last Week"
    case lastMonth = "Last Month"
    case all = "All Time"
    case custom = "Custom"

    var range: (startDate: Date, endDate: Date)? {
        switch self {
        case .today:
            let today = Date()
            return (today.startOfDay, today.endOfDay)
        case .oneWeek:
            let today = Date()
            if let lastWeekDate = today.adding(.day, value: -6) {
                return (lastWeekDate.startOfDay, today.endOfDay)
            }
        case .oneMonth:
            let today = Date()
            if let lastMonthDate = today.adding(.month, value: -1)?.adding(.day, value: 1) {
                return (lastMonthDate.startOfDay, today.endOfDay)
            }
        case .oneYear:
            let today = Date()
            if let lastYearDate = today.adding(.year, value: -1)?.adding(.day, value: 1) {
                return (lastYearDate.startOfDay, today.endOfDay)
            }
        case .thisWeek:
            let thisWeekDate = Date()
            if let startOfWeek = thisWeekDate.startOfWeek, let endOfWeek = thisWeekDate.endOfWeek {
                return (startOfWeek.startOfDay, endOfWeek.endOfDay)
            }
        case .lastWeek:
            let today = Date()
            if let lastWeekDate = today.adding(.weekOfYear, value: -1),
                  let startOfWeek = lastWeekDate.startOfWeek,
                  let endOfWeek = lastWeekDate.endOfWeek {
                return (startOfWeek.startOfDay, endOfWeek.endOfDay)
            }
        case .lastMonth:
            let today = Date()
            if let lastMonthDate = today.adding(.month, value: -1) {
                return (lastMonthDate.startOfDay, today.endOfDay)
            }
        case .all:
            let today = Date()
            return (Date(timeIntervalSince1970: 0).startOfDay, today.endOfDay)
        case .custom:
            return nil
        }
        return nil
    }

    var groupIdentifier: Int {
        switch self {
        case .today:
            return 1
        case .oneWeek, .oneMonth, .oneYear:
            return 2
        case .thisWeek, .lastWeek, .lastMonth:
            return 3
        case .all, .custom:
            return 4
        }
    }
}
