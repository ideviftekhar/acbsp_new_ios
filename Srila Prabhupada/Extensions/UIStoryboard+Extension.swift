//
//  UIStoryboard+Extension.swift
//  Srila Prabhupada
//
//  Created by IE06 on 08/09/22.
//

import Foundation
import UIKit

extension UIStoryboard {

    static let main = UIStoryboard(name: "Main", bundle: nil)
    static let sideMenu = UIStoryboard(name: "SideMenu", bundle: nil)
    static let home = UIStoryboard(name: "Home", bundle: nil)
    static let downloads = UIStoryboard(name: "Downloads", bundle: nil)
    static let favorites = UIStoryboard(name: "Favorites", bundle: nil)
    static let history = UIStoryboard(name: "History", bundle: nil)
    static let playlists = UIStoryboard(name: "Playlists", bundle: nil)
    static let popularLecture = UIStoryboard(name: "PopularLecture", bundle: nil)
    static let topLectures = UIStoryboard(name: "TopLectures", bundle: nil)
    static let stats = UIStoryboard(name: "Stats", bundle: nil)
    static let common = UIStoryboard(name: "Common", bundle: nil)


    func instantiate<T: UIViewController>(_ controllerType: T.Type, identifier: String? = nil) -> T {

        let identifier: String = identifier ?? String(describing: T.self)

        return instantiateViewController(withIdentifier: identifier) as! T
    }

}
