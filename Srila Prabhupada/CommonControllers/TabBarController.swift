//
//  HomeViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 19/08/22.
//

import UIKit
import FirebaseMessaging

class TabBarController: UITabBarController {

    let playerViewController = UIStoryboard.common.instantiate(PlayerViewController.self)

    override func viewDidLoad() {
        super.viewDidLoad()

        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { success, _ in

            if success {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        })

        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        let hasNotch: Bool = (keyWindow?.safeAreaInsets.bottom ?? 0) > 0
        if !hasNotch {
            tabBar.selectionIndicatorImage = nil
        }

        playerViewController.addToTabBarController(self)
        playerViewController.currentLecture = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playerViewController.beginAppearanceTransition(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerViewController.endAppearanceTransition()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerViewController.beginAppearanceTransition(false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playerViewController.endAppearanceTransition()
    }

    var viewFrame: CGRect = .zero
    var tabFrame: CGRect = .zero

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !viewFrame.equalTo(view.frame) || !tabFrame.equalTo(tabBar.frame) {
            viewFrame = view.frame
            tabFrame = tabBar.frame
            playerViewController.reposition()
        }
    }

    override var childForStatusBarStyle: UIViewController? {
        if playerViewController.visibleState == .expanded {
            return playerViewController
        }
        return nil
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension TabBarController {

    func showPlayer(lecture: Lecture, playlistLectures: [Lecture]) {

        playerViewController.playlistLectures = playlistLectures

        if let playerLecture = playerViewController.currentLecture,
           playerLecture.id == lecture.id, playerLecture.creationTimestamp == lecture.creationTimestamp {

            if playerViewController.isPaused {
                playerViewController.play()
            } else {
                playerViewController.pause()
            }
        } else {

            let shouldPlay: Bool

            if playerViewController.currentLecture == nil {
                shouldPlay = true
            } else if !playerViewController.isPaused {
                shouldPlay = true
            } else {
                shouldPlay = false
            }

            playerViewController.currentLecture = lecture
            if shouldPlay {
                playerViewController.play()
            }
        }
    }
}

extension TabBarController: UNUserNotificationCenterDelegate {

}

extension TabBarController {
    convenience init(abc: String) {
        self.init(nibName: "Nib", bundle: nil)
    }
}
