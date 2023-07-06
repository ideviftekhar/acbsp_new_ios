//
//  Audio.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import Foundation

struct Audio: Hashable, Codable {
    let creationTimestamp: Date?
    let downloads: Int
    let lastModifiedTimestamp: Date?
    let views: Int
    let url: String?

    init(creationTimestamp: Date?, downloads: Int, lastModifiedTimestamp: Date?, views: Int, url: String?) {
        self.creationTimestamp = creationTimestamp
        self.downloads = downloads
        self.lastModifiedTimestamp = lastModifiedTimestamp
        self.views = views
        self.url = url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.downloads = try container.decode(Int.self, forKey: .downloads)
        self.views = try container.decode(Int.self, forKey: .views)
        self.url = try? container.decode(String.self, forKey: .url)

        if let value = try? container.decode(Date.self, forKey: .creationTimestamp) {
            self.creationTimestamp = value
        } else if let creationTimestamp = try? container.decode(String.self, forKey: .creationTimestamp) {
            self.creationTimestamp = DateFormatter.isoDateFormatter.date(from: creationTimestamp)
        } else {
            self.creationTimestamp = nil
        }

        if let value = try? container.decode(Date.self, forKey: .lastModifiedTimestamp) {
            self.lastModifiedTimestamp = value
        } else if let lastModifiedTimestamp = try? container.decode(String.self, forKey: .lastModifiedTimestamp) {
            self.lastModifiedTimestamp = DateFormatter.isoDateFormatter.date(from: lastModifiedTimestamp)
        } else {
            self.lastModifiedTimestamp = nil
        }
    }

    var audioURL: URL? {
        guard let url = url, !url.isEmpty else {
            return nil
        }
        return URL(string: url)
    }

}
