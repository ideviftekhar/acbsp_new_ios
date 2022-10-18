//
//  TopLectureType.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/17/22.
//

import Foundation


enum TopLectureType: String, Codable, CaseIterable {
    case thisWeek   = "This Week"
    case thisMonth  = "This Month"
    case lastWeek   = "Last Week"
    case lastMonth  = "Last Month"

    init?(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .thisWeek
        case 1:
            self = .thisMonth
        case 2:
            self = .lastWeek
        case 3:
            self = .lastMonth
        default:
            self = .thisWeek
        }
    }
}
