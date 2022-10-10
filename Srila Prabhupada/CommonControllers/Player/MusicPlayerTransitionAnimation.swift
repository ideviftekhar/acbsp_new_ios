//
//  MusicPlayerTransitionAnimation.swift
//  MusicPlayerTransition
//
//  Created by xxxAIRINxxx on 2016/11/05.
//  Copyright © 2016 xxxAIRINxxx. All rights reserved.
//

import Foundation
import UIKit
import ARNTransitionAnimator

protocol MiniPlayerContainable where Self: UIViewController {
    var miniPlayerView: UIView { get }
}

final class MusicPlayerTransitionAnimation: TransitionAnimatable {

    fileprivate weak var rootVC: MiniPlayerContainable!
    fileprivate weak var modalVC: UIViewController!

    var completion: ((Bool) -> Void)?

    private var miniPlayerStartFrame: CGRect = CGRect.zero
    private var tabBarStartFrame: CGRect = CGRect.zero

    private var containerView: UIView?

    init(rootVC: MiniPlayerContainable, modalVC: UIViewController) {
        self.rootVC = rootVC
        self.modalVC = modalVC
    }

    var tabBar: UITabBar? {
        if let tabBarController = self.rootVC as? UITabBarController {
            return tabBarController.tabBar
        } else if let tabBarController = self.rootVC.tabBarController {
            return tabBarController.tabBar
        } else {
            return nil
        }
    }

    // @see : http://stackoverflow.com/questions/25588617/ios-8-screen-blank-after-dismissing-view-controller-with-custom-presentation
    func prepareContainer(_ transitionType: TransitionType, containerView: UIView, from fromVC: UIViewController, to toVC: UIViewController) {
        self.containerView = containerView
        if transitionType.isPresenting {
            self.rootVC.view.insertSubview(self.modalVC.view, belowSubview: self.rootVC.miniPlayerView)
        } else {
            self.rootVC.view.insertSubview(self.modalVC.view, belowSubview: self.rootVC.miniPlayerView)
        }
        self.rootVC.view.setNeedsLayout()
        self.rootVC.view.layoutIfNeeded()
        self.modalVC.view.setNeedsLayout()
        self.modalVC.view.layoutIfNeeded()

        self.miniPlayerStartFrame = self.rootVC.miniPlayerView.frame
        if let tabBar = self.tabBar {
            self.tabBarStartFrame = tabBar.frame
        } else {
            self.tabBarStartFrame = CGRect(x: 0, y: self.rootVC.view.bounds.maxY, width: self.rootVC.view.bounds.width, height: 0)
        }
    }

    func willAnimation(_ transitionType: TransitionType, containerView: UIView) {
        if transitionType.isPresenting {
            self.rootVC.beginAppearanceTransition(true, animated: false)

            self.modalVC.view.frame.origin.y = self.rootVC.miniPlayerView.frame.origin.y + self.rootVC.miniPlayerView.frame.size.height
        } else {
            self.rootVC.beginAppearanceTransition(false, animated: false)

            self.rootVC.miniPlayerView.alpha = 1.0
            self.rootVC.miniPlayerView.frame.origin.y = -self.rootVC.miniPlayerView.bounds.size.height

            if let tabBar = self.tabBar {
//                tabBar.frame.origin.y = containerView.bounds.size.height
            }
        }
    }

    func updateAnimation(_ transitionType: TransitionType, percentComplete: CGFloat) {
        if transitionType.isPresenting {
            // miniPlayerView
            let startOriginY = self.miniPlayerStartFrame.origin.y
            let endOriginY = -self.miniPlayerStartFrame.size.height
            let diff = -endOriginY + startOriginY
            // tabBar
            let tabStartOriginY = self.tabBarStartFrame.origin.y
            let tabEndOriginY = self.modalVC.view.frame.size.height
            let tabDiff = tabEndOriginY - tabStartOriginY

            let playerY = startOriginY - (diff * percentComplete)
            self.rootVC.miniPlayerView.frame.origin.y = max(min(playerY,  self.miniPlayerStartFrame.origin.y), endOriginY)

            self.modalVC.view.frame.origin.y = self.rootVC.miniPlayerView.frame.origin.y + self.rootVC.miniPlayerView.frame.size.height
            let tabY = tabStartOriginY + (tabDiff * percentComplete)

            let tabBarOriginY = min(max(tabY, self.tabBarStartFrame.origin.y), tabEndOriginY)
            let alpha = 1.0 - (1.0 * percentComplete)

            if let tabBar = self.tabBar {
                tabBar.alpha = alpha
//                tabBar.frame.origin.y = tabBarOriginY
            }
        } else {
            // miniPlayerView
            let startOriginY = 0 - self.rootVC.miniPlayerView.bounds.size.height
            let endOriginY = self.miniPlayerStartFrame.origin.y
            let diff = -startOriginY + endOriginY
            // tabBar
            let tabStartOriginY = self.rootVC.view.bounds.size.height
//            let tabStartOriginY = self.rootVC.containerView.bounds.size.height
            let tabEndOriginY = self.tabBarStartFrame.origin.y
            let tabDiff = tabStartOriginY - tabEndOriginY

            self.rootVC.miniPlayerView.frame.origin.y = startOriginY + (diff * percentComplete)
            self.modalVC.view.frame.origin.y = self.rootVC.miniPlayerView.frame.origin.y + self.rootVC.miniPlayerView.frame.size.height

            let alpha = 1.0 * percentComplete
//            self.rootVC.containerView.subviews.forEach { $0.alpha = alpha + 0.4 }

            let tabBarOriginY = tabStartOriginY - (tabDiff * (1.0 - percentComplete))

            if let tabBar = self.tabBar {
//                tabBar.frame.origin.y = tabBarOriginY
                tabBar.alpha = alpha
            }
        }
    }

    func finishAnimation(_ transitionType: TransitionType, didComplete: Bool) {
        self.rootVC.endAppearanceTransition()

        if transitionType.isPresenting {
            if didComplete {
                self.rootVC.miniPlayerView.alpha = 0.0
                self.modalVC.view.removeFromSuperview()
                self.containerView?.addSubview(self.modalVC.view)

                self.completion?(transitionType.isPresenting)
            }   else {
                self.rootVC.beginAppearanceTransition(true, animated: false)
                self.rootVC.endAppearanceTransition()
            }
        } else {
            if didComplete {
                self.modalVC.view.removeFromSuperview()

                self.completion?(transitionType.isPresenting)
            } else {
                self.rootVC.miniPlayerView.alpha = 0.0

                self.modalVC.view.removeFromSuperview()
                self.containerView?.addSubview(self.modalVC.view)

                self.rootVC.beginAppearanceTransition(false, animated: false)
                self.rootVC.endAppearanceTransition()
            }
        }
    }
}

extension MusicPlayerTransitionAnimation {

    func sourceVC() -> UIViewController { return self.rootVC }

    func destVC() -> UIViewController { return self.modalVC }
}
