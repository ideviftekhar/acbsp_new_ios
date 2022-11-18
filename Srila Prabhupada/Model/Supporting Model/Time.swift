//
//  Time.swift
//  Srila Prabhupada
//
//  Created by IE03 on 13/09/22.
//

import Foundation

struct Time: Hashable, Codable {

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.totalSeconds == rhs.totalSeconds
    }

    let hour: Int
    let minute: Int
    let second: Int

    var totalSeconds: Int {
        return hour*60*60 + minute*60 + second
    }

    var displayString: String {
        if hour <= 0 {
            return String(format: "%02i:%02i", minute, second)
        } else {
            return String(format: "%02i:%02i:%02i", hour, minute, second)
        }
    }

    var displayTopUnit: String {
        if hour > 0 {
            return String(format: "%ih", hour)
        } else if minute > 0 {
            return String(format: "%im", minute)
        } else if second > 0 {
            return String(format: "%is", second)
        } else {
            return String(format: "0m")
        }
    }

    var displayHourMinute: String {
        return String(format: "%01ih %01im", hour, minute)
    }

    var displayStringH: String {
        if hour > 0 {
            return String(format: "%ih %im %is", hour, minute, second)
        } else if minute > 0 {
            return String(format: "%im %is", minute, second)
        } else if second > 0 {
            return String(format: "%is", second)
        } else {
            return String(format: "0m")
        }
    }

    init(totalSeconds: Int) {

        hour = totalSeconds / 3600
        minute = (totalSeconds % 3600) / 60
        second = (totalSeconds % 3600) % 60
    }
}
