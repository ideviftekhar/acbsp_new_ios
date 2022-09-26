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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.lectureCount = (try? container.decode(Int.self, forKey: .lectureCount)) ?? 0
        self.creationTime = try container.decode(Int.self, forKey: .creationTime)
        self.lectureIds = try container.decode([Int].self, forKey: .lectureIds)
        self.thumbnail = try container.decode(String.self, forKey: .thumbnail)
    }
}
