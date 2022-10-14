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

        playerViewController.addToTabBarController(self)
        playerViewController.currentLecture = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
