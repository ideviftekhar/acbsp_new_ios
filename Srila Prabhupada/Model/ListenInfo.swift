//
//  ListenInfo.swift
//  Srila Prabhupada
//
//  Created by IE on 9/22/22.
//

import Foundation
import FirebaseFirestoreSwift

struct ListenInfo: Hashable, Codable {

    let audioListen: Int
    let creationTimestamp: Int
    let dateOfRecord: Day
    let playedIds: [Int]
    let listenDetails: ListenDetails
}
