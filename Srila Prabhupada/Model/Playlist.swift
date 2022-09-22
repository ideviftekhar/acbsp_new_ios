//
//  PrivatePlaylist.swift
//  Srila Prabhupada
//
//  Created by IE03 on 20/09/22.
//

import Foundation

struct Playlist: Hashable, Codable {
    var title: String
    var lectureIds: [Int]
}
