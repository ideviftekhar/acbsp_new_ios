//
//  Language.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import Foundation

struct Language: Hashable, Codable {

    let main: String
    let translations: [String]

    init(main: String, translations: [String]) {
        self.main = main
        self.translations = translations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.main = try container.decode(String.self, forKey: .main)

        if let value = try? container.decode([String].self, forKey: .translations) {
            self.translations = value
        } else if let value = try? container.decode(String.self, forKey: .translations) {
            self.translations = [value]
        } else {
            self.translations = []
        }
    }
}
