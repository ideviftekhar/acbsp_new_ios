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

    case pauseDownload          =   "Pause Download"

    case deleteFromDownloads    =   "Delete from Downloads"

    case markAsFavourite        =   "Mark as Favourite"

    case removeFromFavourites   =   "Remove From Favourite"

    case addToPlaylist          =   "Add to playlist"

    case removeFromPlaylist     =   "Remove from playlist"

    case markAsHeard            =   "Mark as heard"

    case resetProgress          =   "Reset Progress"

    case share                  =   "Share"

    var image: UIImage? {
        switch self {
        case .download:
            return UIImage(compatibleSystemName: "square.and.arrow.down")
        case .pauseDownload:
            return UIImage(compatibleSystemName: "pause.fill")
        case .deleteFromDownloads:
            return UIImage(compatibleSystemName: "icloud.slash")
        case .markAsFavourite:
            return UIImage(compatibleSystemName: "star.fill")
        case .removeFromFavourites:
            return UIImage(compatibleSystemName: "star.slash.fill")
        case .addToPlaylist:
            return UIImage(compatibleSystemName: "music.note.list")
        case .removeFromPlaylist:
            return UIImage(compatibleSystemName: "text.badge.minus")
        case .markAsHeard:
            return UIImage(compatibleSystemName: "checkmark")
        case .resetProgress:
            return UIImage(compatibleSystemName: "arrow.clockwise")
        case .share:
            return UIImage(compatibleSystemName: "square.and.arrow.up.fill")
        }
    }
}
