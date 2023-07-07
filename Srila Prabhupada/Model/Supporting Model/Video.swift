//
//  Video.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/6/23.
//

import Foundation

struct Video: Hashable, Codable {
    let creationTimestamp: Date?
    let lastModifiedTimestamp: Date?
    let type: String
    let url: String?

    init(creationTimestamp: Date?, downloads: Int, lastModifiedTimestamp: Date?, type: String, url: String?) {
        self.creationTimestamp = creationTimestamp
        self.lastModifiedTimestamp = lastModifiedTimestamp
        self.type = type
        self.url = url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
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

    var videoURL: URL? {
        guard let url = url, !url.isEmpty else {
            return nil
        }
        return URL(string: url)
    }
}
