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

    init(lectureCode: String, slug: String, verse: String, wpId: Int) {
        self.lectureCode = lectureCode
        self.slug = slug
        self.verse = verse
        self.wpId = wpId
    }
}
