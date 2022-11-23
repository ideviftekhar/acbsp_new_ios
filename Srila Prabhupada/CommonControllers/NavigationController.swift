//
//  NavigationController.swift
//  Srila Prabhupada
//
//  Created by IE on 9/16/22.
//

import Foundation
import UIKit

class NavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.backgroundColor = UIColor.themeColor
            navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

            navigationBar.standardAppearance = navigationBarAppearance
            navigationBar.compactAppearance = navigationBarAppearance
            navigationBar.scrollEdgeAppearance = navigationBarAppearance
            if #available(iOS 15.0, *) {
                navigationBar.compactScrollEdgeAppearance = navigationBarAppearance
            }
        }
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        if let tabBarController = tabBarController {
            return tabBarController.preferredStatusBarUpdateAnimation
        } else {
            return .fade
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let tabBarController = tabBarController {
            return tabBarController.preferredStatusBarStyle
        } else {
            return .lightContent
        }
    }
}
