//
//  Audio.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import Foundation

struct Audio: Hashable, Codable {
    let creationTimestamp: String
    let downloads: Int
    let lastModifiedTimestamp: String
    let views: Int
    let url: String?

    init(creationTimestamp: String, downloads: Int, lastModifiedTimestamp: String, views: Int, url: String?) {
        self.creationTimestamp = creationTimestamp
        self.downloads = downloads
        self.lastModifiedTimestamp = lastModifiedTimestamp
        self.views = views
        self.url = url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.creationTimestamp = try container.decode(String.self, forKey: .creationTimestamp)
        self.downloads = try container.decode(Int.self, forKey: .downloads)
        self.lastModifiedTimestamp = try container.decode(String.self, forKey: .lastModifiedTimestamp)
        self.views = try container.decode(Int.self, forKey: .views)
        self.url = try? container.decode(String.self, forKey: .url)
    }

    var audioURL: URL? {
        guard let url = url, !url.isEmpty else {
            return nil
        }
        return URL(string: url)
    }

}
