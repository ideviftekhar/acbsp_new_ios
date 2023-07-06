//
//  LoadingViewController.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/27/22.
//

import UIKit
import FirebaseFirestore

class LoadingViewController: UIViewController {

    @IBOutlet private var backgroundImageView: UIImageView!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var loadingLabel: UILabel!
    @IBOutlet private var activtiyIndicator: UIActivityIndicatorView!
    @IBOutlet private var progressView: UIProgressView!
    @IBOutlet private var titleLabel: UILabel!
    var forceLoading: Bool = false

    let lectureSyncManager = LectureSyncManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = Constants.loadingTitleText
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        validateLocalCacheAndSync()
    }

    private func validateLocalCacheAndSync() {

        if forceLoading {
            startSyncing()
        } else {

            self.activtiyIndicator.startAnimating()
            self.loadingLabel.text = "Loading.."
            progressView.progress = 0
            progressView.alpha = 0.0

            DefaultLectureViewModel.defaultModel.getAllCachedLectures { [self] lectures in
                self.activtiyIndicator.stopAnimating()
                loadingLabel.text = nil
                (DefaultLectureViewModel.defaultModel as? DefaultLectureViewModel)?.allLectures = lectures
                if lectures.isEmpty {
                    self.startSyncing()
                } else {
                    if let keyWindow = self.view.window {
                        let tabBarController = UIStoryboard.main.instantiate(TabBarController.self)
                        tabBarController.lectures = lectures
                        keyWindow.rootViewController = tabBarController
                    }
                }
            }
        }
    }

    private func startSyncing() {

        self.activtiyIndicator.startAnimating()
        self.loadingLabel.text = "Loading..."
        progressView.progress = 0
        progressView.alpha = 0.0

        lectureSyncManager.startSync(initialLectures: nil, force: forceLoading, progress: { [self] progress in

            progressView.alpha = 1.0

            let intProgress = Int(progress*100)
            loadingLabel.text = "Loading... \(intProgress)%"
            progressView.setProgress(Float(progress), animated: false)

        }, completion: { [self] lectures in
            self.activtiyIndicator.stopAnimating()
            progressView.alpha = 0.0
            loadingLabel.text = nil

            if let keyWindow = self.view.window {

                let tabBarController = UIStoryboard.main.instantiate(TabBarController.self)
                tabBarController.lectures = lectures
                keyWindow.rootViewController = tabBarController
            }
        })
    }
}
