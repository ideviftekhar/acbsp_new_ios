//
//  Time.swift
//  Srila Prabhupada
//
//  Created by IE03 on 13/09/22.
//

import Foundation

struct Time: Hashable {

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

    init(totalSeconds: Int) {

        hour = totalSeconds / 3600
        minute = (totalSeconds % 3600) / 60
        second = (totalSeconds % 3600) % 60
    }
}
