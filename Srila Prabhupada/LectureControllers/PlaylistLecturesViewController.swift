//
//  PlaylistLecturesViewController.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 9/8/22.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import SKActivityIndicatorView
import StatusAlert

class PlaylistLecturesViewController: LectureViewController {

    var playlist: Playlist!

    private lazy var addLecturesButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addLecturesButtonAction(_:)))

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = playlist.title
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !isSelectionEnabled && Auth.auth().currentUser?.email == playlist.authorEmail, playlist.lectureIds.isEmpty {
            addLecturesButtonAction(addLecturesButton)
        }
    }

    override func refreshAsynchronous(source: FirestoreSource, completion: @escaping (Result<[LectureViewController.Model], Error>) -> Void) {

        DefaultLectureViewModel.defaultModel.getLectures(searchText: searchText, sortType: selectedSortType, filter: selectedFilters, lectureIDs: playlist.lectureIds, source: source, progress: nil, completion: completion)
    }

    @objc func addLecturesButtonAction(_ sender: UIBarButtonItem) {
        let navController = UIStoryboard.home.instantiate(UINavigationController.self, identifier: "HomeNavigationController")
        if let homeController = navController.viewControllers.first as? HomeViewController {
            homeController.isSelectionEnabled = true
            homeController.selectedPlaylist = playlist
            homeController.delegate = self
        }
        present(navController, animated: true, completion: nil)
    }
}

extension PlaylistLecturesViewController: LectureViewControllerDelegate {
    func lectureControllerDidCancel(_ controller: LectureViewController) {
        controller.dismiss(animated: true)
    }

    func lectureController(_ controller: LectureViewController, didSelected lectures: [Lecture]) {

        let message: String
        if lectures.count == 1, let lecture = lectures.first {
            message = "Would you like to add '\(lecture.titleDisplay)' to '\(playlist.title)' Playlist?"
        } else {
            message = "Would you like to add \(lectures.count) lecture(s) to '\(playlist.title)' Playlist?"
        }

        controller.showAlert(title: "Add to '\(playlist.title)'?",
                       message: message,
                       sourceView: addLecturesButton,
                       cancel: ("Cancel", nil),
                       buttons: ("Add", {

            SKActivityIndicator.statusTextColor(.textDarkGray)
            SKActivityIndicator.spinnerColor(.textDarkGray)
            SKActivityIndicator.show("Adding to '\(self.playlist.title)' ...")

            DefaultPlaylistViewModel.defaultModel.add(lectures: lectures, to: self.playlist, completion: { result in
                SKActivityIndicator.dismiss()

                switch result {
                case .success(let lectureIds):
                    Haptic.success()
                    self.highlightedLectures = lectures
                    self.playlist.lectureIds = lectureIds
                    self.refresh(source: .cache)
                    controller.dismiss(animated: true, completion: {

                        let message: String?
                        if lectures.count > 1 {
                            message = "Added \(lectures.count) lecture(s)"
                        } else {
                            message = nil
                        }

                        let playlistIcon = UIImage(compatibleSystemName: "music.note.list")
                        StatusAlert.show(image: playlistIcon, title: "Added to '\(self.playlist.title)'", message: message, in: self.view)
                    })
                case .failure(let error):
                    Haptic.error()
                    controller.showAlert(error: error)
                }
            })
        }))
    }
}
