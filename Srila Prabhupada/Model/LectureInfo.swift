//
//  LectureInfo.swift
//  Srila Prabhupada
//
//  Created by IE03 on 17/09/22.
//

import Foundation

struct LectureInfo {
    var isFavourite: Bool
    var id: Int

    init(_ attributes: [String: Any]) {
        self.isFavourite = attributes["isFavourite"] as? Bool ?? false
        self.id = attributes["id"] as? Int ?? 0
    }
}
