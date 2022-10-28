//
//  LectureSortType.swift
//  Srila Prabhupada
//
//  Created by IE03 on 13/09/22.
//

import Foundation

enum LectureSortType: String, CaseIterable {
    case `default` = "Default"
    case durationLowToHigh = "Duration: Low to High"
    case durationHighToLow = "Duration: High to Low"
    case dateOldestFirst = "Recording Date: Oldest First"
    case dateLatestFirst = "Recording Date: Latest First"
    case aToZ = "Alphabetically: A -> Z"
    case zToA = "Alphabetically: Z -> A"

    func sort(_ lectures: [Lecture]) -> [Lecture] {
        switch self {
        case .default:
            return LectureSortType.dateOldestFirst.sort(lectures)
        case .durationLowToHigh:
            return lectures.sorted { obj1, obj2 in
                obj1.length < obj2.length
            }
        case .durationHighToLow:
            return lectures.sorted { obj1, obj2 in
                obj1.length > obj2.length
            }
        case .dateOldestFirst:
            return lectures.sorted { obj1, obj2 in
                if obj1.dateOfRecording == obj2.dateOfRecording {
                    return obj1.creationTimestamp < obj2.creationTimestamp
                } else {
                    return obj1.dateOfRecording < obj2.dateOfRecording
                }
            }
        case .dateLatestFirst:
            return lectures.sorted { obj1, obj2 in
                if obj1.dateOfRecording == obj2.dateOfRecording {
                    return obj1.creationTimestamp > obj2.creationTimestamp
                } else {
                    return obj1.dateOfRecording > obj2.dateOfRecording
                }
            }
        case .aToZ:
            return lectures.sorted { obj1, obj2 in
                obj1.titleDisplay.caseInsensitiveCompare(obj2.titleDisplay) == .orderedAscending
            }
        case .zToA:
            return lectures.sorted { obj1, obj2 in
                obj1.titleDisplay.caseInsensitiveCompare(obj2.titleDisplay) == .orderedDescending
            }
        }
    }
}
