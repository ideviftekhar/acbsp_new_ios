//
//  HomeViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 19/08/22.
//

import UIKit
import FirebaseMessaging
import ARNTransitionAnimator

class TabBarController: UITabBarController, MiniPlayerContainable {
    var miniPlayerView: UIView {
        return playerViewController.miniPlayerView
    }

    let playerViewController = UIStoryboard.common.instantiate(PlayerViewController.self)

    private var animator: ARNTransitionAnimator?

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

        configureMiniPlyaer()
        self.setupAnimator()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func configureMiniPlyaer() {

        self.miniPlayerView.isHidden = true
        playerViewController.miniPlayerView.delegate = self

        playerViewController.modalPresentationStyle = .overCurrentContext

        self.view.insertSubview(miniPlayerView, belowSubview: self.tabBar)
        miniPlayerView.translatesAutoresizingMaskIntoConstraints = false
        miniPlayerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        miniPlayerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        miniPlayerView.bottomAnchor.constraint(equalTo: self.tabBar.topAnchor).isActive = true
    }
}

extension TabBarController {

    func setupAnimator() {
        let animation = MusicPlayerTransitionAnimation(rootVC: self, modalVC: playerViewController)
        animation.completion = { [weak self] isPresenting in
            if isPresenting {
                guard let self = self else { return }
                let modalGestureHandler = TransitionGestureHandler(targetView: self.playerViewController.view, direction: .bottom)
                modalGestureHandler.panCompletionThreshold = 15.0
                self.animator?.registerInteractiveTransitioning(.dismiss, gestureHandler: modalGestureHandler)
            } else {
                self?.setupAnimator()
            }
        }

        let gestureHandler = TransitionGestureHandler(targetView: self.miniPlayerView, direction: .top)
        gestureHandler.panCompletionThreshold = 15.0
        gestureHandler.panFrameSize = self.view.bounds.size

        self.animator = ARNTransitionAnimator(duration: 0.5, animation: animation)
        self.animator?.registerInteractiveTransitioning(.present, gestureHandler: gestureHandler)

        playerViewController.transitioningDelegate = self.animator
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

        playerViewController.play()
    }
}

extension TabBarController: MiniPlayerViewDelegate {
    func miniPlayerView(_ playerView: MiniPlayerView, didSeekTo seconds: Int) {
        playerViewController.seekTo(seconds: seconds)
    }

    func miniPlayerView(_ playerView: MiniPlayerView, didChangePlay isPlay: Bool) {
        if isPlay {
            playerViewController.play()
        } else {
            playerViewController.pause()
        }
    }

    func miniPlayerViewDidExpand(_ playerView: MiniPlayerView) {
        if playerViewController.currentLecture != nil, playerViewController.presentingViewController == nil {
            self.present(playerViewController, animated: true, completion: nil)
        }
    }
}

extension TabBarController: UNUserNotificationCenterDelegate {

}
