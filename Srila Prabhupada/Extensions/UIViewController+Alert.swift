//
//  UIViewController+Alert.swift
//  Srila Prabhupada
//
//  Created by IE06 on 9/12/22.
//

import UIKit

extension UIViewController {

    typealias ButtonConfig = (title: String, handler: (() -> Void)?)

    func showAlert(title: String,
                   message: String,
                   preferredStyle: UIAlertController.Style = .alert,
                   cancel: ButtonConfig = (title: "OK", handler: nil),
                   destructive: ButtonConfig? = nil,
                   buttons: ButtonConfig...) {

        showAlert(title: title, message: message, preferredStyle: preferredStyle, cancel: cancel, destructive: destructive, buttons: buttons)
    }

    func showAlert(title: String,
                   message: String,
                   preferredStyle: UIAlertController.Style = .alert,
                   cancel: ButtonConfig = (title: "OK", handler: nil),
                   destructive: ButtonConfig? = nil,
                   buttons: [ButtonConfig]) {

        let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        alert.addAction(UIAlertAction(title: cancel.title, style: .cancel, handler: { _ in
            cancel.handler?()
        }))

        if let destructive = destructive {
            alert.addAction(UIAlertAction(title: destructive.title, style: .destructive, handler: { _ in
                destructive.handler?()
            }))
        }

        for button in buttons {
            alert.addAction(UIAlertAction(title: button.title, style: .default, handler: { _ in
                button.handler?()
            }))
        }

        // show the alert
        if let navController = self.navigationController {
            navController.present(alert, animated: true)
        } else if let tabBarController = self.tabBarController {
            tabBarController.present(alert, animated: true)
        } else {
            self.present(alert, animated: true)
        }
    }
}
