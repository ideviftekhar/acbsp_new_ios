//
//  PlaylistLecturesViewController.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 9/8/22.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import ProgressHUD

class PlaylistLecturesViewController: LectureViewController {

    var playlist: Playlist!
    let playlistViewModel: PlaylistViewModel = DefaultPlaylistViewModel()

    private lazy var addLecturesButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addLecturesButtonAction(_:)))

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "\(playlist.listType.rawValue) Playlist"
        self.navigationItem.prompt = playlist.title
        do {
            noItemTitle = "No Lectures"
            noItemMessage = "No lectures in '\(playlist.title)' playlist"
        }

        if !isSelectionEnabled && Auth.auth().currentUser?.email == playlist.authorEmail {
            var rightButtons = self.navigationItem.rightBarButtonItems ?? []
            rightButtons.insert(addLecturesButton, at: 0)
            self.navigationItem.rightBarButtonItems = rightButtons
        }
    }

    override func refreshAsynchronous(source: FirestoreSource) {
        super.refreshAsynchronous(source: source)

        showLoading()
        Self.lectureViewModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: playlist.lectureIds, source: source, completion: { [self] result in
            hideLoading()
            switch result {
            case .success(let lectures):
                reloadData(with: lectures)
            case .failure(let error):
                showAlert(title: "Error", message: error.localizedDescription)
            }
        })
    }

    @objc func addLecturesButtonAction(_ sender: UIBarButtonItem) {
        let navController = UIStoryboard.home.instantiate(UINavigationController.self, identifier: "HomeNavigationController")
        if let homeController = navController.viewControllers.first as? HomeViewController {
            homeController.isSelectionEnabled = true
            homeController.delegate = self
        }
        present(navController, animated: true, completion: nil)
    }
}

extension PlaylistLecturesViewController: LectureViewControllerDelegate {
    func lectureController(_ controller: LectureViewController, didSelected lectures: [Lecture]) {

        ProgressHUD.show("Adding \(lectures.count) lectures to '\(playlist.title)' playlist...", interaction: false)
        self.playlistViewModel.add(lectures: lectures, to: playlist, completion: { result in
            ProgressHUD.dismiss()

            switch result {
            case .success(let lectureIds):
                self.playlist.lectureIds = lectureIds
                self.refreshAsynchronous(source: .default)
                controller.dismiss(animated: true)
            case .failure(let error):
                controller.showAlert(title: "Error", message: error.localizedDescription)
            }
        })
    }
}
