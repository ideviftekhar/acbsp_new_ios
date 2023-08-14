//
//  LectureViewController+Sort.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 8/4/23.
//

import UIKit

extension LectureViewController {

    internal func configureSortButton() {
        var actions: [SPAction] = []

        let userDefaultKey: String = "\(Self.self).\(LectureSortType.self)"
        let lastType: LectureSortType

        if let typeString = UserDefaults.standard.string(forKey: userDefaultKey), let type = LectureSortType(rawValue: typeString) {
            lastType = type
        } else {
            lastType = .default
        }

        for option in LectureSortType.allCases {

            let state: UIAction.State = (lastType == option ? .on : .off)

            let action: SPAction = SPAction(title: option.rawValue, image: option.image, identifier: .init(option.rawValue), state: state, groupIdentifier: option.groupIdentifier, handler: { [self] action in
                sortActionSelected(action: action)
            })

            actions.append(action)
        }

        self.sortMenu = SPMenu(title: "", image: nil, identifier: .init(rawValue: "Sort"), options: .displayInline, children: actions, barButton: sortButton, parent: self)

        updateSortButtonUI()
    }

    private func sortActionSelected(action: UIAction) {
        let userDefaultKey: String = "\(Self.self).\(LectureSortType.self)"
        UserDefaults.standard.set(action.identifier.rawValue, forKey: userDefaultKey)
        UserDefaults.standard.synchronize()

        let children: [SPAction] = self.sortMenu.children
        for anAction in children {
            if anAction.action.identifier == action.identifier { anAction.action.state = .on  } else {  anAction.action.state = .off }
        }
        self.sortMenu.children = children

        updateSortButtonUI()

        Haptic.selection()

        refresh(source: .cache, animated: nil)
    }

    private func updateSortButtonUI() {
        if let icon = selectedSortType.imageSelected {
            sortButton.image = icon
        } else {
            sortButton.image = UIImage(systemName: "arrow.up.arrow.down.circle")
        }
    }
}
