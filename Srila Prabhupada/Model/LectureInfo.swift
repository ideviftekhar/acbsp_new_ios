//
//  LectureInfo.swift
//  Srila Prabhupada
//
//  Created by IE03 on 17/09/22.
//

import Foundation

struct LectureInfo: Hashable, Codable {
    let id: Int
    let creationTimestamp: Int
    var isFavorite: Bool
    var lastPlayedPoint: Int
    var documentId: String

    enum CodingKeys: String, CodingKey {
        case id
        case creationTimestamp
        case isFavorite = "isFavourite"
        case lastPlayedPoint
        case documentId
    }

    init(id: Int, creationTimestamp: Int, isFavorite: Bool, lastPlayedPoint: Int, documentId: String) {
        self.id = id
        self.creationTimestamp = creationTimestamp
        self.isFavorite = isFavorite
        self.lastPlayedPoint = lastPlayedPoint
        self.documentId = documentId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.documentId = try container.decode(String.self, forKey: .documentId)
        self.creationTimestamp = (try? container.decode(Int.self, forKey: .creationTimestamp)) ?? 0
        self.isFavorite = (try? container.decode(Bool.self, forKey: .isFavorite)) ?? false
        self.lastPlayedPoint = (try? container.decode(Int.self, forKey: .lastPlayedPoint)) ?? 0
    }
}
