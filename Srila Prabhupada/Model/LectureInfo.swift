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
    var isFavourite: Bool
    var lastPlayedPoint: Int
    var documentId: String

    init(id: Int, creationTimestamp: Int, isFavourite: Bool, lastPlayedPoint: Int, documentId: String) {
        self.id = id
        self.creationTimestamp = creationTimestamp
        self.isFavourite = isFavourite
        self.lastPlayedPoint = lastPlayedPoint
        self.documentId = documentId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.documentId = try container.decode(String.self, forKey: .documentId)
        self.creationTimestamp = (try? container.decode(Int.self, forKey: .creationTimestamp)) ?? 0
        self.isFavourite = (try? container.decode(Bool.self, forKey: .isFavourite)) ?? false
        self.lastPlayedPoint = (try? container.decode(Int.self, forKey: .lastPlayedPoint)) ?? 0
    }
}
