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
            return UIImage(systemName: "arrow.up.arrow.down")
        case .lecturesLessToMore:
            return UIImage(systemName: "lessthan.circle")
        case .lecturesMoreToLess:
            return UIImage(systemName: "greaterthan.circle")
        case .dateOldestFirst:
            return UIImage(systemName: "calendar.badge.clock")
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
        case .lecturesLessToMore:
            return UIImage(systemName: "lessthan.circle.fill")
        case .lecturesMoreToLess:
            return UIImage(systemName: "greaterthan.circle.fill")
        case .dateOldestFirst:
            return UIImage(systemName: "calendar.circle.fill")
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
        case .lecturesLessToMore, .lecturesMoreToLess:
            return 2
        case .dateOldestFirst, .dateLatestFirst:
            return 3
        case .aToZ, .zToA:
            return 4
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
