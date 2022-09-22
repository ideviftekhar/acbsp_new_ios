//
//  FirestoreCollection.swift
//  Srila Prabhupada
//
//  Created by IE on 9/22/22.
//

import Foundation

enum FirestoreCollection {
    case privatePlaylists
    case publicPlaylists
    case topLectures
    case lectures
    case usersSettings(userId: String)
    case usersLectureInfo(userId: String)
    case usersListenInfo(userId: String)

    var path: String {
        switch self {
        case .privatePlaylists:
            return "PrivatePlaylists"
        case .publicPlaylists:
            return "PublicPlaylists"
        case .topLectures:
            return "TopLectures"
        case .lectures:
            return "lectures"
        case .usersSettings(userId: let userId):
            return "users/\(userId)/Settings"
        case .usersLectureInfo(userId: let userId):
            return "users/\(userId)/lectureInfo"
        case .usersListenInfo(userId: let userId):
            return "users/\(userId)/listenInfo"
        }
    }
}
