//
//  ListenInfo.swift
//  Srila Prabhupada
//
//  Created by IE on 9/22/22.
//

import Foundation
//import FirebaseFirestoreSwift

struct ListenInfo: Hashable, Codable {
//    @DocumentID private(set) var id: String?

    let audioListen: Int
    let creationTimestamp: Int
    let dateOfRecord: Day
    let playedIds: [Int]
    let listenDetails: ListenDetails
}
