//
//  TopLectures.swift
//  Srila Prabhupada
//
//  Created by IE03 on 19/09/22.
//

import Foundation

struct TopLecture: Hashable, Codable {

    let documentId: String
    let playedBy: [String]
    let playedIds: [Int]
    let createdDay: Day
}
