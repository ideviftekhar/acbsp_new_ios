//
//  PrivatePlaylist.swift
//  Srila Prabhupada
//
//  Created by IE03 on 20/09/22.
//

import Foundation

struct Playlist: Hashable {
    var title: String
    var lectureIds: [Int]

    init(_ attributes: [String: Any]) {
        self.title = attributes["title"] as? String ?? ""

        if let arrplayedIds = attributes["lectureIds"] as? [Int] {
            self.lectureIds = []
            for arrplayedId in arrplayedIds {
                self.lectureIds.append(arrplayedId)
            }
        } else {
            self.lectureIds = []
        }
    }
}
