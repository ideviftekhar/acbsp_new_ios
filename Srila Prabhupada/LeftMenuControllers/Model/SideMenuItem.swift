//
//  SideMenuItem.swift
//  Srila Prabhupada
//
//  Created by IE on 9/19/22.
//

import Foundation
import UIKit

enum SideMenuItem: String, CaseIterable {
    case mediaLibrary = "Media library"
    case history = "History"
    case stats = "Stats"
    case popularLectures = "Popular Lectures"
    case about = "About"
    case share = "Share"
    case donate = "Donate"
    case copyright = "Copyright"
    case rateUs = "Rate Us on App Store"

    var image: UIImage? {
        switch self {
        case .mediaLibrary:
            return UIImage(named: "photo.circle")
        case .history:
            return UIImage(compatibleSystemName: "clock")
        case .stats:
            return UIImage(compatibleSystemName: "chart.pie")
        case .popularLectures:
            return UIImage(compatibleSystemName: "heart.circle")
        case .about:
            return UIImage(compatibleSystemName: "exclamationmark.circle")
        case .share:
            return UIImage(named: "square.and.arrow.up.circle")
        case .donate:
            return UIImage(named: "gift.circle")
        case .copyright:
            return UIImage(compatibleSystemName: "c.circle")
        case .rateUs:
            return UIImage(compatibleSystemName: "star.circle")
        }
    }
}
