//
//  TabBarController+LectureLoading.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/4/23.
//

import UIKit
import FirebaseFirestore

extension TabBarController {

    internal func fetchServerTimestampAndLoadLectures(cachedLectures: [Lecture]) {

        let keyUserDefaults = CommonConstants.keyTimestamp
        let oldTimestamp: Date = (UserDefaults.standard.object(forKey: keyUserDefaults) as? Date) ?? Date(timeIntervalSince1970: 0)

        DefaultLectureViewModel.defaultModel.getTimestamp(source: .default) { [self] result in
            switch result {
            case .success(let result):

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
            case .failure:
                self.loadLectures(newTimestamp: oldTimestamp, firestoreSource: .default)
            }
        }
    }

    private func loadLectures(newTimestamp: Date, firestoreSource: FirestoreSource) {

        DefaultLectureViewModel.defaultModel.getLectures(searchText: nil, sortType: .default, filter: [:], lectureIDs: nil, source: firestoreSource, progress: nil, completion: { [self] result in
            switch result {
            case .success(let lectures):

                if firestoreSource == .cache, lectures.isEmpty {
                    loadLectures(newTimestamp: newTimestamp, firestoreSource: .default)
                } else {
                    UserDefaults.standard.set(newTimestamp, forKey: CommonConstants.keyTimestamp)
                    UserDefaults.standard.synchronize()

                    loadLectureInfo()
                }
            case .failure:
                loadLectures(newTimestamp: newTimestamp, firestoreSource: firestoreSource)
            }
        })
    }

    private func loadLectureInfo() {

        DefaultLectureViewModel.defaultModel.getUsersLectureInfo(source: .default, progress: nil, completion: { [self] result in
            self.reloadAllControllers()
        })
    }
}
