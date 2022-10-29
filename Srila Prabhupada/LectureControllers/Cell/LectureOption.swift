//
//  LectureOption.swift
//  Srila Prabhupada
//
//  Created by IE on 9/19/22.
//

import Foundation
import UIKit

enum LectureOption: String, CaseIterable {

    case download               =   "Download"

    case downloading            =   "Downloading..."

    case deleteFromDownloads    =   "Delete from Downloads"

    case markAsFavourite        =   "Mark as Favourite"

    case removeFromFavourites   =   "Remove From Favourite"

    case addToPlaylist          =   "Add to playlist"

    case markAsHeard            =   "Mark as heard"

    case resetProgress          =   "Reset Progress"

    case share                  =   "Share"

    var image: UIImage? {
        switch self {
        case .download:
            return UIImage(compatibleSystemName: "square.and.arrow.down")
        case .downloading:
            return UIImage(compatibleSystemName: "square.and.arrow.down.fill")
        case .deleteFromDownloads:
            return UIImage(compatibleSystemName: "trash")
        case .markAsFavourite:
            return UIImage(compatibleSystemName: "star.fill")
        case .removeFromFavourites:
            return UIImage(compatibleSystemName: "star")
        case .addToPlaylist:
            return UIImage(compatibleSystemName: "music.note.list")
        case .markAsHeard:
            return UIImage(compatibleSystemName: "checkmark")
        case .resetProgress:
            return UIImage(compatibleSystemName: "arrow.clockwise")
        case .share:
            return UIImage(compatibleSystemName: "square.and.arrow.up.fill")
        }
    }
}
