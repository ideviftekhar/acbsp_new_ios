//
//  SortType.swift
//  Srila Prabhupada
//
//  Created by IE03 on 13/09/22.
//

import Foundation
import FirebaseFirestore

enum SortType: String, CaseIterable {
    case `default` = "Default"
    case durationLowtoHigh = "Duration: Low to High"
    case durationHighToLow = "Duration: High to Low"
    case dateOldestFirst = "Recording Date: Oldest First"
    case dateLatestFirst = "Recording Date: Latest First"
    case aToZ = "Alphabetically: A -> Z"
    case zToA = "Alphabetically: Z -> A"

    var firebaseKey: String {
        switch self {
        case .default:              return ""
        case .durationLowtoHigh:    return "length"
        case .durationHighToLow:    return "length"
        case .dateOldestFirst:      return "creationTimestamp"
        case .dateLatestFirst:      return "creationTimestamp"
        case .aToZ:                 return "title"
        case .zToA:                 return "title"
        }
    }

    var descending: Bool {
        switch self {
        case .default:              return true
        case .durationLowtoHigh:    return false
        case .durationHighToLow:    return true
        case .dateOldestFirst:      return false
        case .dateLatestFirst:      return true
        case .aToZ:                 return false
        case .zToA:                 return true
        }
    }

    func applyOn(query: Query) -> Query {
        switch self {
        case .default:
            return query
        default:
            return query.order(by: firebaseKey, descending: descending)
        }
    }
}

