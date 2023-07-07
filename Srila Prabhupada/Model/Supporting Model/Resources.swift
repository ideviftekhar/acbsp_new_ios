//
//  Resources.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import Foundation

struct Resources: Hashable, Codable {
    let audios: [Audio]
    let transcriptions: [Transcription]
    let videos: [Video]

    init(audios: [Audio], transcriptions: [Transcription], videos: [Video]) {
        self.audios = audios
        self.transcriptions = transcriptions
        self.videos = videos
    }
}
