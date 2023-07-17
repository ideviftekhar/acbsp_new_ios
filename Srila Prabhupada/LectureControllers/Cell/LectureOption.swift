//
//  LectureOption.swift
//  Srila Prabhupada
//
//  Created by IE on 9/19/22.
//

import Foundation
import UIKit

enum LectureOption: String, CaseIterable {

    case addToQueue             =   "Add to Queue"

    case removeFromPlayNext     =   "Remove from Play Next"

    case download               =   "Download"

    case resumeDownload         =   "Resume Download"

    case pauseDownload          =   "Pause Download"

    case deleteFromDownloads    =   "Delete from Downloads"

    case markAsFavorite         =   "Mark as Favorite"

    case removeFromFavorite     =   "Remove from Favorite"

    case addToPlaylist          =   "Add to Playlist"

    case removeFromPlaylist     =   "Remove from Playlist"

    case markAsHeard            =   "Mark as Heard"

    case resetProgress          =   "Reset Progress"

    case share                  =   "Share"

    case info                   =   "Info"

    var image: UIImage? {
        switch self {
        case .addToQueue:
            return UIImage(systemName: "text.badge.plus")
        case .removeFromPlayNext:
            return UIImage(systemName: "text.badge.minus")
        case .download, .resumeDownload:
            return UIImage(systemName: "square.and.arrow.down")
        case .pauseDownload:
            return UIImage(systemName: "pause.fill")
        case .deleteFromDownloads:
            return UIImage(systemName: "icloud.slash")
        case .markAsFavorite:
            return UIImage(systemName: "star.fill")
        case .removeFromFavorite:
            return UIImage(systemName: "star.slash.fill")
        case .addToPlaylist:
            return UIImage(systemName: "music.note.list")
        case .removeFromPlaylist:
            return UIImage(systemName: "text.badge.minus")
        case .markAsHeard:
            return UIImage(systemName: "checkmark")
        case .resetProgress:
            return UIImage(systemName: "arrow.clockwise")
        case .share:
            return UIImage(systemName: "square.and.arrow.up.fill")
        case .info:
            return UIImage(systemName: "info.circle")
        }
    }
}
