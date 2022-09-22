//
//  TopLectures.swift
//  Srila Prabhupada
//
//  Created by IE03 on 19/09/22.
//

import Foundation

struct TopLectures {
    var documentId: String
    var playedIds: [Int]

    init(_ attributes: [String: Any]) {
        self.documentId = attributes["documentId"] as? String ?? ""

        if let arrplayedIds = attributes["playedIds"] as? [Int] {
            self.playedIds = []
            for arrplayedId in arrplayedIds {
                self.playedIds.append(arrplayedId)
            }
        } else {
            self.playedIds = []
        }
    }
}
