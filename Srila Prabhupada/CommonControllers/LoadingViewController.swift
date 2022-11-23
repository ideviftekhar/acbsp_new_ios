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

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadLectures()
    }

    private func loadLectures() {
        self.loadingLabel.text = "Loading lectures..."
        progressView.progress = 0
        progressView.alpha = 0.0

        DefaultLectureViewModel.defaultModel.getLectures(searchText: nil, sortType: .default, filter: [:], lectureIDs: nil, source: .default, progress: { [self] progress in
            progressView.alpha = 1.0

            let intProgress = Int(progress*100)
            loadingLabel.text = "Loading lectures... \(intProgress)%"
            progressView.setProgress(Float(progress), animated: true)

        }, completion: { [self] result in

            progressView.alpha = 0.0

            switch result {
            case .success(let lectures):
                Filter.updateFilterSubtypes(lectures: lectures)
                loadLectureInfo()
            case .failure(let error):
                progressView.progress = 0
                loadingLabel.text = nil
                showAlert(title: "Error!", message: error.localizedDescription, cancel: ("Retry", { [self] in
                    loadLectures()
                }), destructive: ("Logout", { [self] in
                    self.askToLogout()
                }))
            }
        })
    }

    private func loadLectureInfo() {

        self.loadingLabel.text = "Please wait..."
        progressView.alpha = 0

        DefaultLectureViewModel.defaultModel.getUsersLectureInfo(source: .default, completion: { [self] result in
            self.loadingLabel.text = nil

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
                    self.showAlert(title: "Error!", message: error.localizedDescription)
                }
            })
        }))
    }
}
