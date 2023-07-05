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
    case dateOldestFirst = "Recording Date: Oldest First"
    case dateLatestFirst = "Recording Date: Latest First"
    case aToZ = "Alphabetically: A -> Z"
    case zToA = "Alphabetically: Z -> A"

    var image: UIImage? {
        switch self {
        case .`default`:
            return UIImage(compatibleSystemName: "arrow.up.arrow.down")
        case .durationLowToHigh:
            return UIImage(compatibleSystemName: "clock")
        case .durationHighToLow:
            return LectureSortType.durationLowToHigh.image
        case .dateOldestFirst:
            return UIImage(compatibleSystemName: "calendar.badge.clock")
        case .dateLatestFirst:
            return UIImage(compatibleSystemName: "calendar.badge.clock")
        case .aToZ:
            return UIImage(compatibleSystemName: "a.square")
        case .zToA:
            return UIImage(compatibleSystemName: "z.square")
        }
    }

    var imageSelected: UIImage? {
        switch self {
        case .`default`:
            return UIImage(compatibleSystemName: "arrow.up.arrow.down.circle")
        case .durationLowToHigh:
            return UIImage(compatibleSystemName: "clock.fill")
        case .durationHighToLow:
           return LectureSortType.durationLowToHigh.imageSelected
        case .dateOldestFirst:
            return UIImage(compatibleSystemName: "calendar.circle.fill")
        case .dateLatestFirst:
            return UIImage(compatibleSystemName: "calendar.circle.fill")
        case .aToZ:
            return UIImage(compatibleSystemName: "a.circle.fill")
        case .zToA:
            return UIImage(compatibleSystemName: "z.circle.fill")
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
