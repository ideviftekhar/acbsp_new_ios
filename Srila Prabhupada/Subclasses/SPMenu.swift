//
//  SPMenu.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/17/22.
//

import Foundation
import UIKit

final class SPAction {

    let action: UIAction
    let groupIdentifier: Int
    let handler: UIActionHandler

    init(title: String = "", image: UIImage? = nil, identifier: UIAction.Identifier? = nil, attributes: UIMenuElement.Attributes = [], state: UIMenuElement.State = .off, groupIdentifier: Int, handler: @escaping UIActionHandler) {
        self.action = .init(title: title, image: image, identifier: identifier, attributes: attributes, state: state, handler: handler)
        self.groupIdentifier = groupIdentifier
        self.handler = handler
    }
}

final class SPMenu {

    private(set) var menu: UIMenu?
    let button: UIButton?
    let barButton: UIBarButtonItem?
    let parentController: UIViewController?

    var children: [SPAction] {
        didSet {
            if #available(iOS 14.0, *) {

                let groups = Self.convertToGroups(actions: children)

                menu = menu?.replacingChildren(groups)
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
            let groups = Self.convertToGroups(actions: children)
            menu = UIMenu(title: title, image: image, identifier: identifier, options: options, children: groups)
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
            let groups = Self.convertToGroups(actions: children)
            menu = UIMenu(title: title, image: image, identifier: identifier, options: options, children: groups)
            barButton.menu = menu
        } else {
            menu = nil
            barButton.target = self
            barButton.action = #selector(menuActioniOS13(_:))
        }
    }

    private static func convertToGroups(actions: [SPAction]) -> [UIMenuElement] {
        var groups: [[SPAction]] = []
        if Environment.current.device == .mac {
            groups = [actions]
        } else {
            for action in actions {
                if let index = groups.firstIndex(where: { $0.first?.groupIdentifier == action.groupIdentifier }) {
                    groups[index].append(action)
                } else {
                    groups.append([action])
                }
            }
        }
        var finalChildrens: [UIMenuElement]
        if groups.count == 1, let group = groups.first {
            finalChildrens = group.map({ $0.action })
        } else {
            finalChildrens = []

            for group in groups {
                let menu = UIMenu(options: .displayInline, children: group.map({ $0.action }))
                finalChildrens.append(menu)
            }
        }
        return finalChildrens
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

            if action.action.attributes == .destructive, destructive == nil {
                destructive = button
            } else if action.action.attributes != .disabled, action.action.attributes != .hidden {
                buttons.append(button)
            }
        }

        let controller: UIViewController? = parentController ?? button?.parentViewController

        controller?.showAlert(title: nil, message: nil, preferredStyle: .actionSheet, sourceView: sender, cancel: ("Cancel", nil), destructive: destructive, buttons: buttons)
    }
}
