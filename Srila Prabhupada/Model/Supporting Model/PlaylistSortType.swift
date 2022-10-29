//
//  PlaylistSortType.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 9/23/22.
//

import Foundation
import UIKit

enum PlaylistSortType: String, CaseIterable {
    case `default` = "Default"
    case lecturesLessToMore = "Lectures: Less First"
    case lecturesMoreToLess = "Lectures: More First"
    case dateOldestFirst = "Creation Date: Oldest First"
    case dateLatestFirst = "Creation Date: Latest First"
    case aToZ = "Alphabetically: A -> Z"
    case zToA = "Alphabetically: Z -> A"

    var image: UIImage? {
        switch self {
        case .`default`:
            return UIImage(compatibleSystemName: "arrow.up.arrow.down")
        case .lecturesLessToMore:
            return UIImage(compatibleSystemName: "lessthan.circle")
        case .lecturesMoreToLess:
            return UIImage(compatibleSystemName: "greaterthan.circle")
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
        case .lecturesLessToMore:
            return UIImage(compatibleSystemName: "lessthan.circle.fill")
        case .lecturesMoreToLess:
            return UIImage(compatibleSystemName: "greaterthan.circle.fill")
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

    func sort(_ playlists: [Playlist]) -> [Playlist] {
        switch self {
        case .default:
            return PlaylistSortType.dateOldestFirst.sort(playlists)
        case .lecturesLessToMore:
            return playlists.sorted { (obj1: Playlist, obj2: Playlist) in
                obj1.lectureIds.count < obj2.lectureIds.count
            }
        case .lecturesMoreToLess:
            return playlists.sorted { (obj1: Playlist, obj2: Playlist) in
                obj1.lectureIds.count > obj2.lectureIds.count
            }
        case .dateOldestFirst:
            return playlists.sorted { (obj1: Playlist, obj2: Playlist) in
                obj1.creationTime < obj2.creationTime
            }
        case .dateLatestFirst:
            return playlists.sorted { (obj1: Playlist, obj2: Playlist) in
                obj1.creationTime > obj2.creationTime
            }
        case .aToZ:
            return playlists.sorted { (obj1: Playlist, obj2: Playlist) in
                obj1.title.caseInsensitiveCompare(obj2.title) == .orderedAscending
            }
        case .zToA:
            return playlists.sorted { (obj1: Playlist, obj2: Playlist) in
                obj1.title.caseInsensitiveCompare(obj2.title) == .orderedDescending
            }
        }
    }
}
