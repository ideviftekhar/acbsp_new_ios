//
//  PlayRate.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/6/22.
//

import Foundation

enum PlayRate: String, CaseIterable {
    case point5 = "0.50x"
    case point75 = "0.75x"
    case one = "1.0x"
    case onePoint15 = "1.15x"
    case onePoint25 = "1.25x"
    case onePoint5 = "1.5x"
    case onePoint75 = "1.75x"
    case two = "2.0x"

    init?(rawValue: Float) {
        switch rawValue {
        case 0.5: self = .point5
        case 0.75: self = .point75
        case 1.0: self = .one
        case 1.15: self = .onePoint15
        case 1.25: self = .onePoint25
        case 1.5: self = .onePoint5
        case 1.75: self = .onePoint75
        case 2.0: self = .two
        default: return nil
        }
    }

    var rate: Float {
        switch self {
        case .point5: return 0.5
        case .point75: return 0.75
        case .one: return 1.0
        case .onePoint15: return 1.15
        case .onePoint25: return 1.25
        case .onePoint5: return 1.5
        case .onePoint75: return 1.75
        case .two: return 2.0
        }
    }


    var groupIdentifier: Int {
        switch self {
        case .point5, .point75:
            return 1
        case .one:
            return 2
        case .onePoint15, .onePoint25, .onePoint5, .onePoint75, .two:
            return 3
        }
    }

    var next: PlayRate {
        switch self {
        case .point5: return .point75
        case .point75: return .one
        case .one: return .onePoint15
        case .onePoint15: return .onePoint25
        case .onePoint25: return .onePoint5
        case .onePoint5: return .onePoint75
        case .onePoint75: return .two
        case .two: return .two
        }
    }
}
