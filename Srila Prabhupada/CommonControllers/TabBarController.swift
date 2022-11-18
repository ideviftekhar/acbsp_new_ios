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

        // Loading last played lectures
        do {
            let lectureIDDefaultKey: String = "\(PlayerViewController.self).\(Lecture.self)"
            let lectureID = UserDefaults.standard.integer(forKey: lectureIDDefaultKey)

            if lectureID != 0 {
                let playlistLecturesKey: String = "\(PlayerViewController.self).playlistLectures"
                var playlistLectureIDs: [Int] = (UserDefaults.standard.array(forKey: playlistLecturesKey) as? [Int]) ?? []
                if !playlistLectureIDs.contains(where: { $0 == lectureID }) {
                    playlistLectureIDs.insert(lectureID, at: 0)
                }

                DefaultLectureViewModel.defaultModel.getLectures(searchText: nil, sortType: nil, filter: [:], lectureIDs: playlistLectureIDs, source: .cache, progress: nil) { result in
                    switch result {
                    case .success(let success):
                        if self.playerViewController.currentLecture == nil,
                           let lectureToPlay = success.first(where: { $0.id == lectureID }) {
                            self.showPlayer(lecture: lectureToPlay, playlistLectures: success, shouldPlay: false)
                        }
                    case .failure:
                        break
                    }
                }
            } else {
                playerViewController.currentLecture = nil
            }
        }
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if var viewControllers = self.viewControllers, viewControllers.contains(playerViewController) {
            viewControllers.removeAll { $0 is PlayerViewController }
            self.viewControllers = viewControllers
        }

        playerViewController.reposition()
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        switch playerViewController.visibleState {
        case .close:
            return .lightContent
        case .minimize:
            return .lightContent
        case .expanded:
            return .darkContent
        }
    }
}

extension TabBarController {

    func showPlayer(lecture: Lecture, playlistLectures: [Lecture], shouldPlay: Bool? = nil) {

        playerViewController.playlistLectures = playlistLectures

        if let playerLecture = playerViewController.currentLecture,
           playerLecture.id == lecture.id, playerLecture.creationTimestamp == lecture.creationTimestamp {

            if let shouldPlay = shouldPlay {
                if shouldPlay {
                    playerViewController.play()
                } else {
                    playerViewController.pause()
                }
            } else {
                if playerViewController.isPaused {
                    playerViewController.play()
                } else {
                    playerViewController.pause()
                }
            }
        } else {

            let shouldReallyPlay: Bool

            if let shouldPlay = shouldPlay {
                shouldReallyPlay = shouldPlay
            } else if playerViewController.currentLecture == nil {
                shouldReallyPlay = true
            } else if !playerViewController.isPaused {
                shouldReallyPlay = true
            } else {
                shouldReallyPlay = false
            }

            playerViewController.currentLecture = lecture
            if shouldReallyPlay {
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
