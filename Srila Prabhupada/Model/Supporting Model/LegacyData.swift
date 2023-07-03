//
//  LegacyData.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import Foundation

struct LegacyData: Hashable, Codable {

    let lectureCode: String
    let slug: String
    let verse: String
    let wpId: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lectureCode = (try? container.decode(String.self, forKey: .lectureCode)) ?? ""
        self.slug = try container.decode(String.self, forKey: .slug)
        self.verse = (try? container.decode(String.self, forKey: .verse)) ?? ""
        self.wpId = (try? container.decode(Int.self, forKey: .wpId)) ?? 0
    }
    
    init(lectureCode: String, slug: String, verse: String, wpId: Int) {
        self.lectureCode = lectureCode
        self.slug = slug
        self.verse = verse
        self.wpId = wpId
    }
}
