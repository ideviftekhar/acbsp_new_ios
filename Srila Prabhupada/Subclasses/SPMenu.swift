//
//  SPMenu.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/17/22.
//

import Foundation
import UIKit

class SPAction {

    let action: UIAction
    let handler: UIActionHandler

    init(title: String = "", image: UIImage? = nil, identifier: UIAction.Identifier? = nil, discoverabilityTitle: String? = nil, attributes: UIMenuElement.Attributes = [], state: UIMenuElement.State = .off, handler: @escaping UIActionHandler) {
        self.action = .init(title: title, image: image, identifier: identifier, discoverabilityTitle: discoverabilityTitle, attributes: attributes, state: state, handler: handler)
        self.handler = handler
    }
}

class SPMenu {

    private(set) var menu: UIMenu?
    let button: UIButton?
    let barButton: UIBarButtonItem?
    let parentController: UIViewController?

    var children: [SPAction] {
        didSet {
            if #available(iOS 14.0, *) {
                menu = menu?.replacingChildren(children.map({ $0.action }))
                button?.menu = menu
                barButton?.menu = menu
            }
        }
    }

    var selectedAction: SPAction? {

        guard let selectedAction = children.first(where: { $0.action.state == .on }) else {
            return nil
        }
        return selectedAction
    }

    init(title: String, image: UIImage?, identifier: UIMenu.Identifier, options: UIMenu.Options, children: [SPAction], button: UIButton) {
        self.children = children
        self.button = button
        self.barButton = nil
        self.parentController = nil
        if #available(iOS 14.0, *) {
            menu = UIMenu(title: title, image: image, identifier: identifier, options: options, children: children.map({ $0.action }))
            button.showsMenuAsPrimaryAction = true
            button.menu = menu
        } else {
            menu = nil
            button.addTarget(self, action: #selector(menuActioniOS13(_:)), for: .touchUpInside)
        }
    }

    init(title: String, image: UIImage?, identifier: UIMenu.Identifier, options: UIMenu.Options, children: [SPAction], barButton: UIBarButtonItem, parent: UIViewController?) {
        self.children = children
        self.button = nil
        self.barButton = barButton
        self.parentController = parent
        if #available(iOS 14.0, *) {
            menu = UIMenu(title: title, image: image, identifier: identifier, options: options, children: children.map({ $0.action }))
            barButton.menu = menu
        } else {
            menu = nil
            barButton.target = self
            barButton.action = #selector(menuActioniOS13(_:))
        }
    }

    // Backward compatibility for iOS 13
    @objc private func menuActioniOS13(_ sender: Any) {

        var buttons: [UIViewController.ButtonConfig] = []

        var destructive: UIViewController.ButtonConfig?

        for action in children {

            let checkedText: String = action.action.state == .on ? " ✓" : ""

            let button: UIViewController.ButtonConfig = (title: action.action.title + checkedText, handler: {
                action.handler(action.action)
            })

            if action.action.attributes == .destructive {
                destructive = button
            } else if action.action.attributes != .disabled, action.action.attributes != .hidden {
                buttons.append(button)
            }
        }

        let controller: UIViewController? = parentController ?? button?.parentViewController

        controller?.showAlert(title: nil, message: nil, preferredStyle: .actionSheet, sourceView: sender, cancel: ("Cancel", nil), destructive: destructive, buttons: buttons)
    }
}
