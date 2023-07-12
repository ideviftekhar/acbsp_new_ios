//
//  PlayerViewController+Position.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/18/22.
//

import Foundation
import UIKit

extension PlayerViewController {

    var parentTabBarController: TabBarController? {
        var nextResponder: UIResponder? = self

        repeat {
            nextResponder = nextResponder?.next

            if let viewController = nextResponder as? TabBarController {
                return viewController
            }

        } while nextResponder != nil

        return nil
    }

    func addToTabBarController(_ tabBarController: UITabBarController) {
        loadViewIfNeeded()

        do {
            // Close state
            do {
                tabBarController.view.insertSubview(playerContainerView, belowSubview: tabBarController.tabBar)
                let rect = CGRect(x: 0, y: tabBarController.view.bounds.maxY, width: tabBarController.view.bounds.width, height: MiniPlayerView.miniPlayerHeight)
                playerContainerView.frame = rect
            }

            self.view.frame = tabBarController.view.bounds
            self.playerContainerView.addSubview(self.view)
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

        guard let tabBarController = self.parentTabBarController else {
            return
        }

        tabBarController.view.insertSubview(playerContainerView, aboveSubview: tabBarController.tabBar)

        let middleAnimationBlock = { [self] in
            miniPlayerView.alpha = 0.0
            fullPlayerContainerView.alpha = 1.0
        }

        let animationBlock = { [self] in
            playerContainerView.frame = tabBarController.view.bounds
            self.view.frame = tabBarController.view.bounds
        }

        visibleState = .expanded
        playerDelegate?.playerController(self, didChangeVisibleState: visibleState)
        tabBarController.setNeedsStatusBarAppearanceUpdate()
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: middleAnimationBlock)
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3, options: .curveEaseInOut, animations: animationBlock)
        } else {
            middleAnimationBlock()
            animationBlock()
        }
    }

    func minimize(animated: Bool) {

        guard let tabBarController = self.parentTabBarController else {
            return
        }

        let middleAnimationBlock = { [self] in
            miniPlayerView.alpha = 1.0
            fullPlayerContainerView.alpha = 0.0
        }

        let animationBlock = { [self] in
            let y = tabBarController.tabBar.frame.minY - MiniPlayerView.miniPlayerHeight
            let rect = CGRect(x: 0, y: y, width: tabBarController.view.frame.width, height: MiniPlayerView.miniPlayerHeight)
            playerContainerView.frame = rect
            self.view.frame = tabBarController.view.bounds
        }

        let options: UIView.AnimationOptions
        if visibleState == .close {
            options = .curveEaseOut
        } else {
            options = .curveEaseInOut
        }

        visibleState = .minimize
        playerDelegate?.playerController(self, didChangeVisibleState: visibleState)
        tabBarController.setNeedsStatusBarAppearanceUpdate()
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: middleAnimationBlock)
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.1, options: options, animations: animationBlock)
        } else {
            animationBlock()
        }
    }

    func close(animated: Bool) {

        guard let tabBarController = self.parentTabBarController else {
            return
        }

        tabBarController.view.insertSubview(playerContainerView, belowSubview: tabBarController.tabBar)

        let animationBlock = { [self] in
            let y = tabBarController.tabBar.frame.minY
            let rect = CGRect(x: 0, y: y, width: tabBarController.view.frame.width, height: MiniPlayerView.miniPlayerHeight)
            playerContainerView.frame = rect
            self.view.frame = tabBarController.view.bounds
            miniPlayerView.alpha = 1.0
            fullPlayerContainerView.alpha = 0.0
        }

        visibleState = .close
        playerDelegate?.playerController(self, didChangeVisibleState: visibleState)
        tabBarController.setNeedsStatusBarAppearanceUpdate()
        if animated {
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.1, options: .curveEaseInOut, animations: animationBlock)
        } else {
            animationBlock()
        }
    }

    @IBAction private func playlistButtonTapped(_ sender: UIButton) {
        if playlistButton.isSelected {
            hidePlaylist(animated: true)
        } else {
            showPlaylist(animated: true)
        }
    }

    func showPlaylist(animated: Bool) {
        let animationBlock = { [self] in
            playlistButton.isSelected = true
            tableViewHeightConstraint.isActive = false
            playingInfoStackView.axis = .horizontal
            playingInfoImageViewWidthConstraint.constant = 50
            playingInfoTitleStackView.alignment = .leading
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()

            thumbnailImageView.shadowColor = nil
            thumbnailImageView.shadowOffset = .zero
            thumbnailImageView.shadowRadius = 0
            thumbnailImageView.shadowOpacity = 0
            thumbnailImageView.clipsToBounds = true
            thumbnailImageView.layer.shadowPath = nil
        }
        if animated {
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.1, options: .curveEaseInOut, animations: animationBlock)
        } else {
            animationBlock()
        }
    }

    func hidePlaylist(animated: Bool) {
        let animationBlock = { [self] in
            playlistButton.isSelected = false
            tableViewHeightConstraint.isActive = true
            playingInfoStackView.axis = .vertical
            if self.traitCollection.verticalSizeClass == .compact {
                playingInfoImageViewWidthConstraint.constant = 150
            } else {
                playingInfoImageViewWidthConstraint.constant = 300
            }
            playingInfoTitleStackView.alignment = .center

            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()

            thumbnailImageView.shadowColor = UIColor.black
            thumbnailImageView.shadowOffset = .zero
            thumbnailImageView.shadowRadius = 100
            thumbnailImageView.shadowOpacity = 0.5
            thumbnailImageView.clipsToBounds = false
            thumbnailImageView.layer.shadowPath = UIBezierPath(roundedRect: thumbnailImageView.bounds, cornerRadius: 20).cgPath

        }
        if animated {
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.1, options: .curveEaseInOut, animations: animationBlock)
        } else {
            animationBlock()
        }
    }
}
