//
//  Resources.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import Foundation

struct Resources: Hashable, Codable {
    let audios: [Audio]

    init(audios: [Audio]) {
        self.audios = audios
    }
}
