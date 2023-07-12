//
//  UserSettings.swift
//  Srila Prabhupada
//
//  Created by IE03 on 17/06/23.
//

import Foundation

struct UserSettings: Hashable, Codable {

    let notification: NotificationModel?
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.notification = try container.decodeIfPresent(NotificationModel.self, forKey: .notification)
    }
}

struct NotificationModel: Hashable, Codable {
    var bengali: Bool
    var english: Bool
    var hindi: Bool
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.bengali = (try container.decodeIfPresent(Bool.self, forKey: .bengali)) ?? true
        self.english = (try container.decodeIfPresent(Bool.self, forKey: .english)) ?? true
        self.hindi = (try container.decodeIfPresent(Bool.self, forKey: .hindi)) ?? true
    }
}
