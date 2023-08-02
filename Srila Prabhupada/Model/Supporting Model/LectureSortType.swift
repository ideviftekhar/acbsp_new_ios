//
//  LectureSortType.swift
//  Srila Prabhupada
//
//  Created by IE03 on 13/09/22.
//

import Foundation
import UIKit

enum LectureSortType: String, CaseIterable {
    case `default` = "Default"
    case durationLowToHigh = "Duration: Low to High"
    case durationHighToLow = "Duration: High to Low"
    case progressLowToHigh = "Progress: Low to High"
    case progressHighToLow = "Progress: High to Low"
    case dateOldestFirst = "Recording: Oldest First"
    case dateLatestFirst = "Recording: Latest First"
    case aToZ = "Alphabetically: A -> Z"
    case zToA = "Alphabetically: Z -> A"

    var image: UIImage? {
        switch self {
        case .`default`:
            return UIImage(systemName: "arrow.up.arrow.down")
        case .durationLowToHigh:
            return UIImage(systemName: "clock")
        case .durationHighToLow:
            return UIImage(systemName: "clock")?.flipHorizontally()?.withRenderingMode(.alwaysTemplate)
        case .progressLowToHigh:
            return UIImage(systemName: "chart.bar")
        case .progressHighToLow:
            return UIImage(systemName: "chart.bar")?.flipHorizontally()?.withRenderingMode(.alwaysTemplate)
        case .dateOldestFirst:
            return UIImage(systemName: "calendar.badge.clock")?.flipHorizontally()?.withRenderingMode(.alwaysTemplate)
        case .dateLatestFirst:
            return UIImage(systemName: "calendar.badge.clock")
        case .aToZ:
            return UIImage(systemName: "a.square")
        case .zToA:
            return UIImage(systemName: "z.square")
        }
    }

    var imageSelected: UIImage? {
        switch self {
        case .`default`:
            return UIImage(systemName: "arrow.up.arrow.down.circle")
        case .durationLowToHigh:
            return UIImage(systemName: "clock.fill")
        case .durationHighToLow:
           return UIImage(systemName: "clock.fill")?.flipHorizontally()?.withRenderingMode(.alwaysTemplate)
        case .progressLowToHigh:
            return UIImage(systemName: "chart.bar.fill")
        case .progressHighToLow:
            return UIImage(systemName: "chart.bar.fill")?.flipHorizontally()?.withRenderingMode(.alwaysTemplate)
        case .dateOldestFirst:
            return UIImage(systemName: "calendar.circle.fill")?.flipHorizontally()?.withRenderingMode(.alwaysTemplate)
        case .dateLatestFirst:
            return UIImage(systemName: "calendar.circle.fill")
        case .aToZ:
            return UIImage(systemName: "a.circle.fill")
        case .zToA:
            return UIImage(systemName: "z.circle.fill")
        }
    }

    var groupIdentifier: Int {
        switch self {
        case .`default`:
            return 1
        case .durationLowToHigh, .durationHighToLow:
            return 2
        case .progressLowToHigh, .progressHighToLow:
            return 3
        case .dateOldestFirst, .dateLatestFirst:
            return 4
        case .aToZ, .zToA:
            return 5
        }
    }

    func sort(_ lectures: [Lecture]) -> [Lecture] {
        switch self {
        case .default:
#if SP
            return LectureSortType.dateOldestFirst.sort(lectures)
#elseif BVKS
            return LectureSortType.dateLatestFirst.sort(lectures)
#endif
        case .durationLowToHigh:
            return lectures.sorted { obj1, obj2 in
                obj1.length < obj2.length
            }
        case .durationHighToLow:
            return lectures.sorted { obj1, obj2 in
                obj1.length > obj2.length
            }
        case .progressLowToHigh:
            return lectures.sorted { obj1, obj2 in
                obj1.playProgress < obj2.playProgress
            }
        case .progressHighToLow:
            return lectures.sorted { obj1, obj2 in
                obj1.playProgress > obj2.playProgress
            }
        case .dateOldestFirst:
            return lectures.sorted { obj1, obj2 in
                if obj1.dateOfRecording == obj2.dateOfRecording {
                    if let obj1CreationTimestamp = obj1.creationTimestamp, let obj2CreationTimestamp = obj2.creationTimestamp {
                        return obj1CreationTimestamp < obj2CreationTimestamp
                    } else if obj1.creationTimestamp != nil {
                        return true
                    } else {
                        return false
                    }
                } else {
                    return obj1.dateOfRecording < obj2.dateOfRecording
                }
            }
        case .dateLatestFirst:
            return lectures.sorted { obj1, obj2 in
                if obj1.dateOfRecording == obj2.dateOfRecording {
                    if let obj1CreationTimestamp = obj1.creationTimestamp, let obj2CreationTimestamp = obj2.creationTimestamp {
                        return obj1CreationTimestamp > obj2CreationTimestamp
                    } else if obj2.creationTimestamp != nil {
                        return true
                    } else {
                        return false
                    }
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
