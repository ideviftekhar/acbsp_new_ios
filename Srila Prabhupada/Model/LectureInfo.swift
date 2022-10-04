//
//  LectureInfo.swift
//  Srila Prabhupada
//
//  Created by IE03 on 17/09/22.
//

import Foundation

struct LectureInfo: Hashable, Codable {
    let id: Int
    let isFavourite: Bool
    let isInPrivateList: Bool
    let isInPublicList: Bool
    let lastPlayedPoint: Int
}
