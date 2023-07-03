//
//  LastSyncTimestamp.swift
//  Srila Prabhupada
//
//  Created by IE03 on 29/05/23.
//

import Foundation

enum LastSyncTimestampKeys: CodingKey {
    case message, source, status, timestamp
}

struct LastSyncTimestamp: Hashable, Decodable {
    let message: String?
    let source: String?
    let status: String?
    var timestamp: Date
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: LastSyncTimestampKeys.self)
        message = try values.decode(String.self, forKey: .message)
        source = try values.decode(String.self, forKey: .source)
        status = try values.decode(String.self, forKey: .status)
        
        if let date = try? values.decodeIfPresent(Date.self, forKey: .timestamp) {
            self.timestamp = date
        } else {
            self.timestamp = Date()
        }
    }
}
