//
//  PlayerViewController+Position.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/18/22.
//

import Foundation
import UIKit

extension PlayerViewController {

    func addToTabBarController(_ tabBarController: UITabBarController) {
        loadViewIfNeeded()

        do {
            tabBarController.addChild(self)
            self.view.frame = tabBarController.view.bounds
            self.view.autoresizingMask = []
            tabBarController.view.addSubview(playerContainerView)
            self.playerContainerView.addSubview(self.view)
            self.didMove(toParent: tabBarController)
        }
        close(animated: false)
    }

    func reposition() {

        switch self.visibleState {
        case .close:
            close(animated: true)
        case .minimize:
            minimize(animated: true)
        case .expanded:
            expand(animated: true)
        }
    }

    func expand(animated: Bool) {

        guard let tabBarController = self.parent as? UITabBarController else {
            return
        }

        tabBarController.view.insertSubview(playerContainerView, aboveSubview: tabBarController.tabBar)

        let middleAnimationBlock = { [self] in
            miniPlayerView.alpha = 0.0
            fullPlayerContainerView.alpha = 1.0
        }

        let animationBlock = { [self] in
            playerContainerView.frame = tabBarController.view.bounds
        }

        visibleState = .expanded
        setNeedsStatusBarAppearanceUpdate()
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: middleAnimationBlock)
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3, options: .curveEaseInOut, animations: animationBlock)
        } else {
            middleAnimationBlock()
            animationBlock()
        }
    }

    func minimize(animated: Bool) {

        guard let tabBarController = self.parent as? UITabBarController else {
            return
        }

        let middleAnimationBlock = { [self] in
            miniPlayerView.alpha = 1.0
            fullPlayerContainerView.alpha = 0.0
        }

        let animationBlock = { [self] in
            let y = tabBarController.tabBar.frame.minY - 60
            let rect = CGRect(x: 0, y: y, width: tabBarController.view.frame.width, height: 60)
            playerContainerView.frame = rect
        }

        let options: UIView.AnimationOptions
        if visibleState == .close {
            options = .curveEaseOut
        } else {
            options = .curveEaseInOut
        }

        visibleState = .minimize
        setNeedsStatusBarAppearanceUpdate()
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: middleAnimationBlock)
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.1, options: options, animations: animationBlock)
        } else {
            animationBlock()
        }
    }

    func close(animated: Bool) {

        guard let tabBarController = self.parent as? UITabBarController else {
            return
        }

        tabBarController.view.insertSubview(playerContainerView, belowSubview: tabBarController.tabBar)

        let animationBlock = { [self] in
            let y = tabBarController.tabBar.frame.minY
            let rect = CGRect(x: 0, y: y, width: tabBarController.view.frame.width, height: 60)
            playerContainerView.frame = rect
            miniPlayerView.alpha = 1.0
            fullPlayerContainerView.alpha = 0.0
        }

        visibleState = .close
        setNeedsStatusBarAppearanceUpdate()
        if animated {
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.1, options: .curveEaseInOut, animations: animationBlock)
        } else {
            animationBlock()
        }
    }
}
