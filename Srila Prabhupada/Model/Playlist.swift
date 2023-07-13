//
//  PrivatePlaylist.swift
//  Srila Prabhupada
//
//  Created by IE03 on 20/09/22.
//

import Foundation
import UIKit
import FirebaseFirestoreSwift

enum PlaylistType: String, Codable, CaseIterable {
    case `public`   = "Public"
    case `private`  = "Private"
    case unknown    = "Unknown"

    init?(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .public
        case 1:
            self = .private
        default:
            self = .unknown
        }
    }

    var image: UIImage? {
        switch self {
        case .public:
            return UIImage(compatibleSystemName: "person.3")
        case .private:
            return UIImage(compatibleSystemName: "lock")
        case .unknown:
            return nil
        }
    }

    var selectedImage: UIImage? {
        switch self {
        case .public:
            return UIImage(compatibleSystemName: "person.3.fill")
        case .private:
            return UIImage(compatibleSystemName: "lock.fill")
        case .unknown:
            return nil
        }
    }
}

struct Playlist: Hashable, Codable {

    let authorEmail: String
    let description: String?
    var lectureIds: [Int]
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
        self.authorEmail = try container.decodeIfPresent(String.self, forKey: .authorEmail) ?? ""
        self.description = try? container.decodeIfPresent(String.self, forKey: .description)
        let creationTime = try container.decodeIfPresent(Int.self, forKey: .creationTime) ?? 0
        self.creationTime = Date(timeIntervalSince1970: TimeInterval(creationTime/1000))
        self.lectureIds = try container.decodeIfPresent([Int].self, forKey: .lectureIds) ?? []
        self.lecturesCategory = try container.decodeIfPresent(String.self, forKey: .lecturesCategory) ?? ""
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail) ?? ""
        self.listID = try container.decodeIfPresent(String.self, forKey: .listID) ?? ""
        self.listType = try container.decodeIfPresent(PlaylistType.self, forKey: .listType) ?? PlaylistType.unknown
    }
}
