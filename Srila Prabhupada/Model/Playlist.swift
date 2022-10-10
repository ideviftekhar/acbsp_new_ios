//
//  PrivatePlaylist.swift
//  Srila Prabhupada
//
//  Created by IE03 on 20/09/22.
//

import Foundation

enum PlaylistType: String, Codable, CaseIterable {
    case `private`  = "Private"
    case `public`   = "Public"

    init?(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .private
        case 1:
            self = .public
        default:
            self = .private
        }
    }
}

struct Playlist: Hashable, Codable {

    let authorEmail: String
    let description: String?
    let lectureIds: [Int]
    let creationTime: Date
    let lecturesCategory: String
    let title: String
    let thumbnail: String
    let listID: String
    let listType: PlaylistType

    var thumbnailURL: URL? {
        guard !thumbnail.isEmpty else {
            return nil
        }
        return URL(string: thumbnail)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.authorEmail = try container.decode(String.self, forKey: .authorEmail)
        self.description = try? container.decode(String.self, forKey: .description)
        let creationTime = try container.decode(Int.self, forKey: .creationTime)
        self.creationTime = Date(timeIntervalSince1970: TimeInterval(creationTime))
        self.lectureIds = try container.decode([Int].self, forKey: .lectureIds)
        self.lecturesCategory = try container.decode(String.self, forKey: .lecturesCategory)
        self.title = try container.decode(String.self, forKey: .title)
        self.thumbnail = try container.decode(String.self, forKey: .thumbnail)
        self.listID = try container.decode(String.self, forKey: .listID)
        self.listType = try container.decode(PlaylistType.self, forKey: .listType)
    }
}
