//
//  LoadingViewController.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/27/22.
//

import UIKit
import FirebaseFirestore

class LoadingViewController: UIViewController {

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var loadingLabel: UILabel!
    @IBOutlet private var progressView: UIProgressView!
    @IBOutlet private var titleLabel: UILabel!
    var forceLoading: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setTimestampAndLoadLectures()
    }

    private func setTimestampAndLoadLectures() {
        
        titleLabel.text = Constants.loadingTitleText
        
        self.loadingLabel.text = "Please wait..."
        progressView.progress = 0
        progressView.alpha = 0.0
        
        DefaultLectureViewModel.defaultModel.getTimestamp(source: .default) { [self] result in
            
            progressView.alpha = 0.0
            loadingLabel.text = nil

            switch result {
            case .success(let result):

                let keyUserDefaults = CommonConstants.keyTimestamp
                let oldTimestamp: Date = (UserDefaults.standard.object(forKey: keyUserDefaults) as? Date) ?? Date(timeIntervalSince1970: 0)

                let newTimestamp: Date = result.timestamp
                                
                let firestoreSource: FirestoreSource
                if self.forceLoading {
                    firestoreSource = .default
                } else if oldTimestamp != newTimestamp {
                    firestoreSource = .default
                } else {
                    firestoreSource = .cache
                }
                self.loadLectures(newTimestamp: newTimestamp, firestoreSource: firestoreSource)
            case .failure(let error):
                Haptic.error()
                self.showAlert(title: "Error!", message: error.localizedDescription, cancel: ("Retry", { [self] in
                    setTimestampAndLoadLectures()
                }), destructive: ("Logout", { [self] in
                    self.askToLogout()
                }))
            }
        }
    }

    private func loadLectures(newTimestamp: Date, firestoreSource: FirestoreSource) {
        
        self.loadingLabel.text = "Loading lectures..."
        progressView.progress = 0
        progressView.alpha = 0.0

        DefaultLectureViewModel.defaultModel.getLectures(searchText: nil, sortType: .default, filter: [:], lectureIDs: nil, source: firestoreSource, progress: { [self] progress in
            progressView.alpha = 1.0

            let intProgress = Int(progress*100)
            loadingLabel.text = "Loading lectures... \(intProgress)%"
            progressView.setProgress(Float(progress), animated: false)

        }, completion: { [self] result in

            progressView.alpha = 0.0
            loadingLabel.text = nil

            switch result {
            case .success(let lectures):
                
                if firestoreSource == .cache, lectures.isEmpty {
                    loadLectures(newTimestamp: newTimestamp, firestoreSource: .default)
                } else {
                    UserDefaults.standard.set(newTimestamp, forKey: CommonConstants.keyTimestamp)
                    UserDefaults.standard.synchronize()

                    Filter.updateFilterSubtypes(lectures: lectures)
                    loadLectureInfo()
                }
            case .failure(let error):
                Haptic.error()
                showAlert(title: "Error!", message: error.localizedDescription, cancel: ("Retry", { [self] in
                    loadLectures(newTimestamp: newTimestamp, firestoreSource: firestoreSource)
                }), destructive: ("Logout", { [self] in
                    self.askToLogout()
                }))
            }
        })
    }

    private func loadLectureInfo() {

        progressView.alpha = 0.0
        self.loadingLabel.text = "Loading profile..."

        DefaultLectureViewModel.defaultModel.getUsersLectureInfo(source: .default, progress: { [self] progress in
            progressView.alpha = 1.0

            let intProgress = Int(progress*100)
            loadingLabel.text = "Loading profile... \(intProgress)%"
            progressView.setProgress(Float(progress), animated: false)

        }, completion: { [self] result in
            progressView.alpha = 0.0
            loadingLabel.text = nil

            switch result {
            case .success:

                if let keyWindow = self.view.window, let currentRootController = keyWindow.rootViewController {

                    let tabBarController = UIStoryboard.main.instantiate(TabBarController.self)
                    keyWindow.rootViewController = tabBarController

//                    tabBarController.view.frame = currentRootController.view.bounds
//                    UIView.transition(with: keyWindow, duration: 0.5, options: .showHideTransitionViews, animations: {
//                        keyWindow.rootViewController = tabBarController
//                    })
                }

            case .failure(let error):
                Haptic.error()
                showAlert(title: "Error!", message: error.localizedDescription, cancel: ("Retry", {
                    self.loadLectureInfo()
                }), destructive: ("Logout", { [self] in
                    self.askToLogout()
                }))
            }
        })
    }

    private func askToLogout() {
        self.showAlert(title: "Logout", message: "Are you sure you would like to Logout?", preferredStyle: .actionSheet, sourceView: imageView, cancel: ("Cancel", nil), destructive: ("Logout", {

            FirestoreManager.shared.signOut(completion: { result in
                switch result {
                case .success:

                    if let keyWindow = self.view.window {
                        UIView.transition(with: keyWindow, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                            let loginNavigationController = UIStoryboard.main.instantiate(UINavigationController.self, identifier: "LoginNavigationController")
                            keyWindow.rootViewController = loginNavigationController
                        })
                    }
                case .failure(let error):
                    Haptic.error()
                    self.showAlert(title: "Error!", message: error.localizedDescription)
                }
            })
        }))
    }
}
