//
//  Transcription.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/6/23.
//

import Foundation

struct Transcription: Hashable, Codable {
    let transcription: String?

    init(transcription: String?) {
        self.transcription = transcription
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.transcription = try? container.decodeIfPresent(String.self, forKey: .transcription)
    }
}
