//
//  RecentPlayID.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/7/23.
//

import Foundation

struct RecentPlayID: Hashable, Codable {

    let recentPlayIDs: [Int]

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        recentPlayIDs = (try values.decodeIfPresent([Int].self, forKey: .recentPlayIDs)) ?? []
    }
}
