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
    case contactUs = "Contact Us"
    case share = "Share"
    case donate = "Donate"
    #if SP
    case copyright = "Copyright"
    #endif
    case rateUs = "Rate Us"

    var image: UIImage? {
        switch self {
        case .mediaLibrary:
            return UIImage(named: "photo.circle")
        case .history:
            return UIImage(systemName: "clock")
        case .stats:
            return UIImage(systemName: "chart.pie")
        case .popularLectures:
            return UIImage(systemName: "heart.circle")
        case .about:
            return UIImage(systemName: "exclamationmark.circle")
        case .share:
            return UIImage(named: "square.and.arrow.up.circle")
        case .donate:
            return UIImage(named: "gift.circle")
#if SP
        case .copyright:
            return UIImage(systemName: "c.circle")
#endif
        case .rateUs:
            return UIImage(systemName: "star.circle")
        case .contactUs:
            return UIImage(systemName: "message.circle")
        }
    }
}
