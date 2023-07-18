//
//  PlayerViewController+Playlist.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/17/23.
//

import Foundation
import UIKit

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
