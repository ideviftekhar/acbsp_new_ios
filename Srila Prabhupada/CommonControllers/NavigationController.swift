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

        let titleTextAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white, .font: UIFont(name: "AvenirNextCondensed-Medium", size: 20)!]
        let largeTitleTextAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white, .font: UIFont(name: "AvenirNextCondensed-Medium", size: 40)!]

        navigationBar.titleTextAttributes = titleTextAttributes
        navigationBar.largeTitleTextAttributes = largeTitleTextAttributes

        do {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithTransparentBackground()
            navigationBarAppearance.backgroundColor = UIColor.themeColor
            navigationBarAppearance.titleTextAttributes = titleTextAttributes
            navigationBarAppearance.largeTitleTextAttributes = largeTitleTextAttributes

            navigationBar.standardAppearance = navigationBarAppearance
            navigationBar.compactAppearance = navigationBarAppearance
            navigationBar.scrollEdgeAppearance = navigationBarAppearance
            if #available(iOS 15.0, *) {
                navigationBar.compactScrollEdgeAppearance = navigationBarAppearance
            }
        }

        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
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
