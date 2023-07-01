//
//  HomeViewController.swift
//  SrilaPrabhupada
//
//  Created by IE06 on 19/08/22.
//

import UIKit
import FirebaseMessaging
import FirebaseFirestore

class TabBarController: UITabBarController {

    let playerViewController = UIStoryboard.common.instantiate(PlayerViewController.self)

    override func viewDidLoad() {
        super.viewDidLoad()

        do {

            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            let hasNotch: Bool = (keyWindow?.safeAreaInsets.bottom ?? 0) > 0

            if hasNotch {
                tabBar.selectionIndicatorImage = UIImage(named: "selection")
            } else {
                tabBar.selectionIndicatorImage =  UIImage()
            }

            if #available(iOS 13.0, *) {
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.backgroundColor = UIColor.themeColor
                tabBarAppearance.selectionIndicatorTintColor = UIColor.white
                if hasNotch {
                    tabBarAppearance.selectionIndicatorImage = UIImage(named: "selection")
                } else {
                    tabBarAppearance.selectionIndicatorImage = UIImage()
                }

                let font: UIFont = UIFont(name: "AvenirNextCondensed-Medium", size: 12)!
                do {
                    let titleTextAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.D5D5D5, .font: font]

                    tabBarAppearance.inlineLayoutAppearance.normal.titleTextAttributes = titleTextAttributes
                    tabBarAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = titleTextAttributes
                    tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = titleTextAttributes
                    tabBarAppearance.inlineLayoutAppearance.normal.iconColor = UIColor.D5D5D5
                    tabBarAppearance.compactInlineLayoutAppearance.normal.iconColor = UIColor.D5D5D5
                    tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.D5D5D5
                }

                do {
                    let titleTextAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white, .font: font]

                    tabBarAppearance.inlineLayoutAppearance.selected.titleTextAttributes = titleTextAttributes
                    tabBarAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = titleTextAttributes
                    tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = titleTextAttributes
                    tabBarAppearance.inlineLayoutAppearance.selected.iconColor = UIColor.white
                    tabBarAppearance.compactInlineLayoutAppearance.selected.iconColor = UIColor.white
                    tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
                }

                tabBar.standardAppearance = tabBarAppearance
                if #available(iOS 15.0, *) {
                    tabBar.scrollEdgeAppearance = tabBarAppearance
                }
            }
        }

        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { success, _ in

            if success {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        })

        playerViewController.playerDelegate = self
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
        if #available(iOS 14.0, *), #available(macCatalyst 14.0, *),
           UIDevice.current.userInterfaceIdiom == .mac,
           let viewControllers = viewControllers {
            viewControllers[0].tabBarItem.image = UIImage(named: "houseFill")
            viewControllers[1].tabBarItem.image = UIImage(named: "musicNoteList")
            viewControllers[2].tabBarItem.image = UIImage(named: "chartBarXaxis")
            viewControllers[3].tabBarItem.image = UIImage(named: "squareAndArrowDownFill")
            viewControllers[4].tabBarItem.image = UIImage(named: "starFill")
        }
        
        addTimestampObserver()
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

extension TabBarController: PlayerViewControllerDelegate {

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
                shouldReallyPlay = true
            }

            playerViewController.currentLecture = lecture
            if shouldReallyPlay {
                playerViewController.play()
            }
        }
    }

    func playerController(_ controller: PlayerViewController, didChangeVisibleState state: PlayerViewController.ViewState) {

        switch state {
        case .close:
            for controller in viewControllers ?? [] {
                controller.additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
            }
        case .minimize:
            for controller in viewControllers ?? [] {
                controller.additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: MiniPlayerView.miniPlayerHeight, right: 0)
            }
        case .expanded:
            for controller in viewControllers ?? [] {
                controller.additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: MiniPlayerView.miniPlayerHeight, right: 0)
            }
        }
    }
}

extension TabBarController: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

extension TabBarController {
    convenience init(abc: String) {
        self.init(nibName: "Nib", bundle: nil)
    }
}

extension TabBarController {

    private func addTimestampObserver() {
        timestampUpdated(completion: { result in
            switch result {
                
            case .success(let newTimestamp):

                let keyUserDefaults = CommonConstants.keyTimestamp
                let oldTimestamp: Date = (UserDefaults.standard.object(forKey: keyUserDefaults) as? Date) ?? Date(timeIntervalSince1970: 0)

                if oldTimestamp != newTimestamp {
                    self.reloadLectures(newTimestamp: newTimestamp, firestoreSource: .server)
                } else{
                    print("No new lectures")
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        })
    }
    
    private func timestampUpdated(completion: @escaping (Swift.Result<Date, Error>) -> Void) {
        
        let metadataPath = FirestoreCollection.metadata.path
        let documentReference: DocumentReference = FirestoreManager.shared.firestore.collection(metadataPath).document(CommonConstants.metadataTimestampDocumentID)
        
        documentReference.addSnapshotListener { snapshot, error in
            
            if let error = error {
                completion(.failure(error))
            } else {
                guard let attributes = snapshot?.data(),
                let timestampValue = attributes[CommonConstants.keyTimestamp] else { return }
                let newTimestamp = (timestampValue as AnyObject).dateValue()
                completion(.success(newTimestamp))
            }
        }
    }
    
    private func reloadLectures(newTimestamp: Date, firestoreSource: FirestoreSource) {
        DefaultLectureViewModel.defaultModel.getLectures(searchText: nil, sortType: .default, filter: [:], lectureIDs: nil, source: firestoreSource, progress: { _ in }, completion: { [self] result in

            switch result {
            case .success(let lectures):
                UserDefaults.standard.set(newTimestamp, forKey: CommonConstants.keyTimestamp)
                UserDefaults.standard.synchronize()

                self.reloadAllControllers()
                Filter.updateFilterSubtypes(lectures: lectures)
            case .failure(let error):
                Haptic.error()

                let okButton: ButtonConfig = (title: "OK", handler: nil)

                showAlert(title: "Error!", message: error.localizedDescription, cancel: ("Retry", { [self] in
                    self.reloadLectures(newTimestamp: newTimestamp, firestoreSource: firestoreSource)
                }), buttons: [okButton])
            }
        })
    }

    private func reloadAllControllers() {

        guard let navigationControllers = viewControllers as? [UINavigationController] else {
            return
        }

        let viewControllers: [UIViewController] = navigationControllers.flatMap { $0.viewControllers }
        let lectureControllers: [LectureViewController] = viewControllers.filter { $0 is LectureViewController } as? [LectureViewController] ?? []

        for lectureController in lectureControllers {
            if lectureController.isViewLoaded {
                lectureController.refresh(source: .cache)
            }
        }
    }
}
