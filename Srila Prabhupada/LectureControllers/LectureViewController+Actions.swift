//
//  LectureViewController+Actions.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 8/4/23.
//

import UIKit
import StatusAlert
import SKActivityIndicatorView

extension LectureViewController {

    func askToDeleteFromDownloads(lectures: [Model], sourceView: Any?) {

        let message: String
        if lectures.count == 1, let lecture = lectures.first {
            message = "Are you sure you would like to delete '\(lecture.titleDisplay)' from Downloads?"
        } else {
            message = "Are you sure you would like to delete \(lectures.count) lecture(s) from Downloads?"
        }

        self.showAlert(title: "Delete From Downloads",
                       message: message,
                       sourceView: sourceView,
                       cancel: ("Cancel", nil),
                       destructive: ("Delete", {
            Persistant.shared.delete(lectures: lectures)
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: lectures, isCompleted: nil, isDownloaded: false, isFavorite: nil, lastPlayedPoint: nil, postUpdate: false, completion: {_ in })
        }))
    }

    func markAsFavorite(lectures: [Model], sourceView: Any?) {
        DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: lectures, isCompleted: nil, isDownloaded: nil, isFavorite: true, lastPlayedPoint: nil, postUpdate: true, completion: { result in
            switch result {
            case .success:

                let message: String?
                if lectures.count > 1 {
                    message = "\(lectures.count) lecture(s) added to favorites"
                } else {
                    message = nil
                }

                StatusAlert.show(image: LectureOption.markAsFavorite.image, title: "Added to favorites", message: message, in: self.view)

            case .failure(let error):
                Haptic.error()
                self.showAlert(title: "Error!", message: error.localizedDescription)
            }

        })
    }

    func askToRemoveFromFavorite(lectures: [Model], sourceView: Any?) {

        let message: String
        if lectures.count == 1, let lecture = lectures.first {
            message = "Are you sure you would like to remove '\(lecture.titleDisplay)' from Favorites?"
        } else {
            message = "Are you sure you would like to remove \(lectures.count) lecture(s) from Favorites?"
        }

        self.showAlert(title: "Remove From Favorites",
                       message: message,
                       sourceView: moreButton,
                       cancel: ("Cancel", nil),
                       destructive: ("Remove", {
            DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: lectures, isCompleted: nil, isDownloaded: nil, isFavorite: false, lastPlayedPoint: nil, postUpdate: true, completion: { result in
                switch result {
                case .success:

                    let message: String?
                    if lectures.count > 1 {
                        message = "\(lectures.count) lecture(s) removed from favorites"
                    } else {
                        message = nil
                    }

                    StatusAlert.show(image: LectureOption.removeFromFavorite.image, title: "Removed from favorites", message: message, in: self.view)

                case .failure(let error):
                    Haptic.error()
                    self.showAlert(title: "Error!", message: error.localizedDescription)
                }
            })
        }))
    }

    internal func askToRemoveFromPlaylist(lectures: [Model], sourceView: Any?) {

        guard let playlistLectureController = self as? PlaylistLecturesViewController else {
            return
        }

        let message: String
        if lectures.count == 1, let lecture = lectures.first {
            message = "Are you sure you would like to remove '\(lecture.titleDisplay)' from Playlist?"
        } else {
            message = "Are you sure you would like to remove \(lectures.count) lecture(s) from Playlist?"
        }

        self.showAlert(title: "Remove From Playlist",
                       message: message,
                       sourceView: moreButton,
                       cancel: ("Cancel", nil),
                       destructive: ("Remove", {

            SKActivityIndicator.statusTextColor(.textDarkGray)
            SKActivityIndicator.spinnerColor(.textDarkGray)
            SKActivityIndicator.show("Removing from playlist...")

            DefaultPlaylistViewModel.defaultModel.remove(lectures: lectures, from: playlistLectureController.playlist, completion: { result in
                SKActivityIndicator.dismiss()
                switch result {
                case .success(let success):

                    playlistLectureController.playlist = success

                    let existing: [Model] = self.models.filter({ success.lectureIds.contains($0.id) })
                    self.refresh(source: .cache, existing: existing, animated: nil)

                    let message: String?
                    if lectures.count > 1 {
                        message = "Removed \(lectures.count) lecture(s) from playlist"
                    } else {
                        message = nil
                    }

                    StatusAlert.show(image: LectureOption.removeFromPlaylist.image, title: "Removed from Playlist", message: message, in: self.view)

                case .failure(let error):
                    Haptic.error()
                    self.showAlert(title: "Error!", message: error.localizedDescription)
                }
            })
        }))
    }

    internal func markAsHeard(lectures: [Model], sourceView: Any?) {

        if let tabBarController = self.tabBarController as? TabBarController,
           let currentPlayingLecture = tabBarController.playerViewController.currentLecture,
           lectures.contains(where: { currentPlayingLecture.id == $0.id }) {

            let playlistLectureIDs: [Int] = tabBarController.playerViewController.playlistLectureIDs
            if var index = playlistLectureIDs.firstIndex(where: { currentPlayingLecture.id == $0 }) {

                while (index+1) < playlistLectureIDs.count {

                    if !lectures.contains(where: { $0.id == playlistLectureIDs[index+1] }) {
                        break
                    } else {
                        index += 1
                    }
                }

                if (index+1) < playlistLectureIDs.count {
                    // We found a lecture which should be played next

                    let shouldPlay: Bool = !tabBarController.playerViewController.isPaused
                    tabBarController.playerViewController.moveToLectureID(id: playlistLectureIDs[index+1], shouldPlay: shouldPlay)
                } else {
                    // We reached at the end of the playlist but haven't found any lecture to play
                    tabBarController.playerViewController.currentLecture = nil
                }
            } else {
                tabBarController.playerViewController.currentLecture = nil
            }
        }

        DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: lectures, isCompleted: true, isDownloaded: nil, isFavorite: nil, lastPlayedPoint: -1, postUpdate: true, completion: { result in
            switch result {
            case .success:

               let message: String?
                 if lectures.count > 1 {
                     message = "Marked heard \(lectures.count) lecture(s)"
                 } else {
                     message = nil
                 }

                StatusAlert.show(image: LectureOption.markAsHeard.image, title: "Marked as heard", message: message, in: self.view)

            case .failure(let error):
                Haptic.error()
                self.showAlert(title: "Error!", message: error.localizedDescription)
            }

        })
    }

    internal func resetProgress(lectures: [Model], sourceView: Any?) {
        DefaultLectureViewModel.defaultModel.updateLectureInfo(lectures: lectures, isCompleted: false, isDownloaded: nil, isFavorite: nil, lastPlayedPoint: 0, postUpdate: true, completion: { result in
            switch result {
            case .success:

                let message: String?
                  if lectures.count > 1 {
                      message = "Progress reset of \(lectures.count) lecture(s)"
                  } else {
                      message = nil
                  }

                StatusAlert.show(image: LectureOption.resetProgress.image, title: "Progress Reset", message: message, in: self.view)
            case .failure(let error):
                Haptic.error()
                self.showAlert(title: "Error!", message: error.localizedDescription)
            }
        })
    }
}

