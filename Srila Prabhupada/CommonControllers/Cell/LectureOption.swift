//
//  LectureOption.swift
//  Srila Prabhupada
//
//  Created by IE on 9/19/22.
//

import Foundation

enum LectureOption: String, CaseIterable {

    case download               =   "Download"

    case deleteFromDownloads     =   "Delete from Downloads"

    case markAsFavorite         =   "Mark as Favorite"

    case removeFromFavorites    =   "Remove From Favorites"

    case addToPlaylist          =   "Add to playlist"

    case markAsHeard            =   "Mark as heard"

    case resetProgress          =   "Reset Progress"

    case share                  =   "Share"
}
