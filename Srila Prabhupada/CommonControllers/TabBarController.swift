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
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension TabBarController {

    func showPlayer(currentLecture: Lecture, playlistLectures: [Lecture]) {

//        if currentLecture.downloadingState == .downloaded, let audioURL = currentLecture.localFileURL {
//
//            let playerController = AVPlayerViewController()
//            playerController.player = AVPlayer(url: audioURL)
//            self.present(playerController, animated: true) {
//                playerController.player?.play()
//            }
//        } else {
//            guard let firstAudio = currentLecture.resources.audios.first,
//                  let audioURL = firstAudio.audioURL else {
//                return
//            }
//
//            let playerController = AVPlayerViewController()
//            playerController.player = AVPlayer(url: audioURL)
//            self.present(playerController, animated: true) {
//                playerController.player?.play()
//            }
//        }

        playerViewController.playlistLectures = playlistLectures
        playerViewController.currentLecture = currentLecture
        self.present(playerViewController, animated: true, completion: nil)
    }
}

extension TabBarController: UNUserNotificationCenterDelegate {

}
