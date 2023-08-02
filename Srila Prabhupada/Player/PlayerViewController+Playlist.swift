//
//  PlayerViewController+Playlist.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/17/23.
//

import Foundation
import UIKit

extension PlayerViewController {

    @IBAction func loopLectureButtonPressed(_ sender: UIButton) {
        Haptic.selection()
        if loopLectureButton.isSelected == true {
            change(shuffle: false, loop: false)
        } else {
            change(shuffle: false, loop: true)
        }
    }

    @IBAction func shuffleLectureButtonPressed(_ sender: UIButton) {
        Haptic.selection()
        if shuffleLectureButton.isSelected == true {
            change(shuffle: false, loop: false)
        } else {
            change(shuffle: true, loop: false)
        }
    }

    @IBAction func playlistMenuDoneButtonPressed(_ sender: UIButton) {
        Haptic.selection()
        self.lectureTebleView.setEditing(false, animated: true)
        playNextMenuButton.isHidden = false
        loopLectureButton.isHidden = false
        shuffleLectureButton.isHidden = false
        stackViewMain.isHidden = false
        playingInfoStackView.isHidden = false

        playNextMenuDoneButton.isHidden = true
    }

    internal func change(shuffle: Bool, loop: Bool) {

        if shuffle {
            shuffleLectureButton.isSelected = true
            loopLectureButton.isSelected = false
        } else if loop {
            loopLectureButton.isSelected = true
            shuffleLectureButton.isSelected = false
        } else {
            loopLectureButton.isSelected = false
            shuffleLectureButton.isSelected = false
        }

        self.updatePlaylistLectureIDs(ids: self.playlistLectureIDs, canShuffle: true, animated: nil) // This is to reload current playlist
    }

    internal func configurePlaylistOptionMenu() {
        var childrens: [SPAction] = []

        let editAction: SPAction = SPAction(title: "Edit", image: UIImage(systemName: "pencil"), identifier: .init("Edit"), groupIdentifier: 1, handler: { [self] _ in
            Haptic.softImpact()
            self.lectureTebleView.setEditing(true, animated: true)
            playNextMenuButton.isHidden = true
            loopLectureButton.isHidden = true
            shuffleLectureButton.isHidden = true
            playingInfoStackView.isHidden = true

            playNextMenuDoneButton.isHidden = false

        })
        childrens.append(editAction)

        let clearWatchedAction: SPAction = SPAction(title: "Clear Watched", image: UIImage(systemName: "text.badge.minus"), identifier: .init("Clear Watched"), groupIdentifier: 2, handler: { [self] _ in
            Haptic.success()
            let completedIDs: [Int] = models.filter { $0.isCompleted }.map { $0.id }
            self.removeFromQueue(lectureIDs: completedIDs)
        })
        childrens.append(clearWatchedAction)

        let clearAllAction: SPAction = SPAction(title: "Clear All", image: UIImage(systemName: "text.badge.xmark"), identifier: .init("Clear All"), groupIdentifier: 2, handler: { [self] _ in
            Haptic.warning()
            self.showAlert(title: "Clear Play Next?", message: "Are you sure you would like to clear Play Next Queue?", preferredStyle: .alert, sourceView: playNextMenuButton, cancel: ("Cancel", nil), destructive: ("Clear", {
                Haptic.success()
                self.clearPlayingQueue(keepPlayingLecture: true)
            }))
        })
        clearAllAction.action.attributes = .destructive
        childrens.append(clearAllAction)

        if let playNextMenuButton = playNextMenuButton {
            self.playNextOptionMenu = SPMenu(title: "", image: nil, identifier: .init(rawValue: "PlaylistOption"), options: .displayInline, children: childrens, button: playNextMenuButton)
        }
    }
}

extension PlayerViewController {

    // Loading last played lectures
    func loadLastPlayedLectures(cachedLectures: [Lecture]) {
        DispatchQueue.global(qos: .background).async {
            let lectureIDDefaultKey: String = "\(Self.self).\(Lecture.self)"
            let lectureID = UserDefaults.standard.integer(forKey: lectureIDDefaultKey)

            let currentLecture: Model?
            do {
                if let lecture = cachedLectures.first(where: { $0.id == lectureID }) {
                    currentLecture = lecture
                } else {
                    currentLecture = nil
                }
            }

            do {
                let playlistLecturesKey: String = "\(PlayerViewController.self).playlistLectures"
                let data = FileUserDefaults.standard.data(for: playlistLecturesKey)

                var playlistLectureIDs: [Int] = []

                if let data = data {
                    playlistLectureIDs = (try? JSONDecoder().decode([Int].self, from: data)) ?? []
                }
                if !playlistLectureIDs.contains(where: { $0 == lectureID }) {
                    playlistLectureIDs.insert(lectureID, at: 0)
                }

                var updatedLectureIDs: [Int] = []
                // Removing duplicates
                do {
                    var lectureIDsHashTable: [Int: Int] = playlistLectureIDs.enumerated().reduce(into: [Int: Int]()) { result, object in
                        if result[object.element] == nil {
                            result[object.element] = object.offset
                        }
                    }

                    for lectureID in playlistLectureIDs where lectureIDsHashTable[lectureID] != nil {
                        updatedLectureIDs.append(lectureID)
                        lectureIDsHashTable[lectureID] = nil
                    }
                }

                DispatchQueue.main.async {
                    self.currentLecture = currentLecture
                    self.updatePlaylistLectureIDs(ids: updatedLectureIDs, canShuffle: true, animated: nil)
                }
            }
        }
    }

    func addToQueue(lectureIDs: [Int]) {

        DispatchQueue.global(qos: .background).async {

            let userDefaultKey: String = "\(Self.self).playlistLectures"
            var updatedLectureIDs: [Int] = []

            if let data = FileUserDefaults.standard.data(for: userDefaultKey),
               let oldLectureIDs = try? JSONDecoder().decode([Int].self, from: data), !oldLectureIDs.isEmpty {

                let mergedLectureIDs: [Int] = oldLectureIDs + lectureIDs

                // Removing duplicates
                do {
                    var lectureIDsHashTable: [Int: Int] = mergedLectureIDs.enumerated().reduce(into: [Int: Int]()) { result, object in
                        if result[object.element] == nil {
                            result[object.element] = object.offset
                        }
                    }

                    for lectureID in mergedLectureIDs where lectureIDsHashTable[lectureID] != nil {
                        updatedLectureIDs.append(lectureID)
                        lectureIDsHashTable[lectureID] = nil
                    }
                }
            } else {
                updatedLectureIDs = lectureIDs
            }

            if let currentLecture = self.currentLecture {
                if !updatedLectureIDs.contains(currentLecture.id) {
                    updatedLectureIDs.insert(currentLecture.id, at: 0)
                }
            }

            let data = try? JSONEncoder().encode(updatedLectureIDs)
            FileUserDefaults.standard.set(data, for: userDefaultKey)

            DispatchQueue.main.async {
                self.updatePlaylistLectureIDs(ids: updatedLectureIDs, canShuffle: true, animated: nil)
            }
        }
    }

    func addToPlayNext(lectureIDs: [Int]) {

        DispatchQueue.global(qos: .background).async {

            let userDefaultKey: String = "\(Self.self).playlistLectures"
            var updatedLectureIDs: [Int] = []

            if let data = FileUserDefaults.standard.data(for: userDefaultKey),
               let oldLectureIDs = try? JSONDecoder().decode([Int].self, from: data) {

                var mergedLectureIDs: [Int] = oldLectureIDs

                if let currentLecture = self.currentLecture {
                    if !mergedLectureIDs.contains(currentLecture.id) {
                        mergedLectureIDs.append(currentLecture.id)
                    }
                }

                if let currentLecture = self.currentLecture,
                   let oldValueIndex = mergedLectureIDs.firstIndex(of: currentLecture.id) {
                    mergedLectureIDs.insert(contentsOf: lectureIDs, at: oldValueIndex + 1)
                } else {
                    mergedLectureIDs.append(contentsOf: lectureIDs)
                }

                // Removing duplicates
                do {
                    var lectureIDsHashTable: [Int: Int] = mergedLectureIDs.enumerated().reduce(into: [Int: Int]()) { result, object in
                        if result[object.element] == nil {
                            result[object.element] = object.offset
                        }
                    }

                    for lectureID in mergedLectureIDs where lectureIDsHashTable[lectureID] != nil {
                        updatedLectureIDs.append(lectureID)
                        lectureIDsHashTable[lectureID] = nil
                    }
                }
            } else {
                updatedLectureIDs = lectureIDs

                if let currentLecture = self.currentLecture {
                    if !updatedLectureIDs.contains(currentLecture.id) {
                        updatedLectureIDs.append(currentLecture.id)
                    }
                }
            }

            let data = try? JSONEncoder().encode(updatedLectureIDs)
            FileUserDefaults.standard.set(data, for: userDefaultKey)

            DispatchQueue.main.async {
                self.updatePlaylistLectureIDs(ids: updatedLectureIDs, canShuffle: true, animated: nil)
            }
        }
    }

    func removeFromQueue(lectureIDs: [Int]) {

        DispatchQueue.global(qos: .background).async {

            let userDefaultKey: String = "\(Self.self).playlistLectures"
            var updatedLectureIDs: [Int] = []

            if let data = FileUserDefaults.standard.data(for: userDefaultKey),
               var mergedLectureIDs = try? JSONDecoder().decode([Int].self, from: data), !mergedLectureIDs.isEmpty {
                mergedLectureIDs.removeAll(where: { lectureIDs.contains($0) })
                updatedLectureIDs = mergedLectureIDs
            }

            if let currentLecture = self.currentLecture {
                if !updatedLectureIDs.contains(currentLecture.id) {
                    updatedLectureIDs.insert(currentLecture.id, at: 0)
                }
            }

            // Removing duplicates
            var finalLectureIDs: [Int] = []
            do {
                var lectureIDsHashTable: [Int: Int] = updatedLectureIDs.enumerated().reduce(into: [Int: Int]()) { result, object in
                    if result[object.element] == nil {
                        result[object.element] = object.offset
                    }
                }

                for lectureID in updatedLectureIDs where lectureIDsHashTable[lectureID] != nil {
                    finalLectureIDs.append(lectureID)
                    lectureIDsHashTable[lectureID] = nil
                }
            }

            let data = try? JSONEncoder().encode(finalLectureIDs)
            FileUserDefaults.standard.set(data, for: userDefaultKey)

            var updatedLectureIdsQueue = self.currentLectureIDsQueue
            updatedLectureIdsQueue.removeAll { lectureIDs.contains($0) }

            DispatchQueue.main.async {
                self.updatePlaylistLectureIDs(ids: finalLectureIDs, canShuffle: false, animated: nil)
            }
        }
    }

    func clearPlayingQueue(keepPlayingLecture: Bool) {

        DispatchQueue.global(qos: .background).async {

            let userDefaultKey: String = "\(Self.self).playlistLectures"
            var updatedLectureIDs: [Int] = []

            if keepPlayingLecture, let currentLecture = self.currentLecture {
                updatedLectureIDs.insert(currentLecture.id, at: 0)
            }

            let data = try? JSONEncoder().encode(updatedLectureIDs)
            FileUserDefaults.standard.set(data, for: userDefaultKey)

            DispatchQueue.main.async {
                self.updatePlaylistLectureIDs(ids: updatedLectureIDs, canShuffle: true, animated: nil)
            }
        }
    }

    func moveQueueLecture(id: Int, toIndex index: Int) {

        DispatchQueue.global(qos: .background).async {
            var updatedLectureIdsQueue = self.currentLectureIDsQueue
            let destinationLectureID = updatedLectureIdsQueue[index]

            if let lectureIndex = updatedLectureIdsQueue.firstIndex(of: id), lectureIndex != index {
                updatedLectureIdsQueue.remove(at: lectureIndex)
                updatedLectureIdsQueue.insert(id, at: index)
            }

            if let sourceIndex = self.playlistLectureIDs.firstIndex(of: id),
               let destinationIndex = self.playlistLectureIDs.firstIndex(of: destinationLectureID),
               sourceIndex != destinationIndex {
                var updatedLectureIDs = self.playlistLectureIDs
                updatedLectureIDs.remove(at: sourceIndex)
                updatedLectureIDs.insert(id, at: destinationIndex)

                let data = try? JSONEncoder().encode(updatedLectureIDs)
                let userDefaultKey: String = "\(Self.self).playlistLectures"
                FileUserDefaults.standard.set(data, for: userDefaultKey)

                DispatchQueue.main.async {
                    self.updatePlaylistLectureIDs(ids: updatedLectureIDs, canShuffle: false, lectureIDsQueue: updatedLectureIdsQueue, animated: false)
                }
            }
        }
    }
}
