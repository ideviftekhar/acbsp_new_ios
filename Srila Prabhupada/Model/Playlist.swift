//
//  PrivatePlaylist.swift
//  Srila Prabhupada
//
//  Created by IE03 on 20/09/22.
//

import Foundation

struct Playlist: Hashable, Codable {

    let isPrivate: Bool = Bool.random()

    let title: String
    let lectureCount: Int
    let creationTime: Int
    let lectureIds: [Int]
    let thumbnail: String

    var thumbnailURL: URL? {
        guard !thumbnail.isEmpty else {
            return nil
        }
        return URL(string: thumbnail)
    }
}
