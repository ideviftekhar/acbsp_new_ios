//
//  LectureSyncManager.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/5/23.
//

import Foundation
import FirebaseFirestore

class LectureSyncManager {

    enum Status {
        case none
        case syncing
    }

    var syncStatus: Status = .none

    var syncStatusHandler: ((_ status: Status) -> Void)?

    private var lectures: [Lecture] = []

    func startSync(initialLectures: [Lecture]?, force: Bool, progress: ((_ progress: CGFloat) -> Void)?, completion: @escaping ((_ lectures: [Lecture]) -> Void)) {
        if let initialLectures = initialLectures {
            lectures = initialLectures
        }

        syncStatus = .syncing
        syncStatusHandler?(.syncing)
        fetchServerTimestampAndLoadLectures(force: force, progress: progress, completion: completion)
    }

    private func fetchServerTimestampAndLoadLectures(force: Bool, progress: ((_ progress: CGFloat) -> Void)?, completion: @escaping ((_ lectures: [Lecture]) -> Void)) {

        let keyUserDefaults = CommonConstants.keyTimestamp
        let oldTimestamp: Date = (UserDefaults.standard.object(forKey: keyUserDefaults) as? Date) ?? Date(timeIntervalSince1970: 0)

        DefaultLectureViewModel.defaultModel.getTimestamp(source: .default) { [self] result in
            switch result {
            case .success(let result):

                let newTimestamp: Date = result.timestamp

                let firestoreSource: FirestoreSource
                if force {
                    firestoreSource = .default
                } else if oldTimestamp != newTimestamp {
                    firestoreSource = .default
                } else {
                    firestoreSource = .cache
                }
                self.loadLectureInfo(newTimestamp: newTimestamp, firestoreSource: firestoreSource, progress: progress, completion: completion)
            case .failure:
                self.loadLectureInfo(newTimestamp: oldTimestamp, firestoreSource: .default, progress: progress, completion: completion)
            }
        }
    }

    private func loadLectureInfo(newTimestamp: Date, firestoreSource: FirestoreSource, progress: ((_ progress: CGFloat) -> Void)?, completion: @escaping ((_ lectures: [Lecture]) -> Void)) {

        // We always get lecture info from default source
        DefaultLectureViewModel.defaultModel.getUsersLectureInfo(source: .default, progress: { lectureProgress in
            progress?(lectureProgress/2.0)
        }, completion: { [self] result in
            self.loadLectures(newTimestamp: newTimestamp, firestoreSource: firestoreSource, progress: progress, completion: completion)
        })
    }

    private func loadLectures(newTimestamp: Date, firestoreSource: FirestoreSource, progress: ((_ progress: CGFloat) -> Void)?, completion: @escaping ((_ lectures: [Lecture]) -> Void)) {

        DefaultLectureViewModel.defaultModel.getLectures(searchText: nil, sortType: .default, filter: [:], lectureIDs: nil, source: firestoreSource, progress: { lectureProgress in
            progress?(0.5 + lectureProgress/2.0)
        }, completion: { [self] result in
            switch result {
            case .success(let lectures):

                if firestoreSource == .cache, lectures.isEmpty {
                    loadLectures(newTimestamp: newTimestamp, firestoreSource: .default, progress: progress, completion: completion)
                } else {
                    UserDefaults.standard.set(newTimestamp, forKey: CommonConstants.keyTimestamp)
                    UserDefaults.standard.synchronize()
                    self.lectures = lectures
                    completion(lectures)
                    syncStatus = .none
                    syncStatusHandler?(.none)
                }
            case .failure:
                completion(self.lectures)
                syncStatus = .none
                syncStatusHandler?(.none)
            }
        })
    }
}
