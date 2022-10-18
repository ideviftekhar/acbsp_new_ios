//
//  LectureViewModel.swift
//  Srila Prabhupada
//
//  Created by IE on 9/22/22.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

protocol LectureViewModel: AnyObject {

    static var defaultModel: LectureViewModel { get }

    func getLectures(searchText: String?, sortType: LectureSortType?, filter: [Filter: [String]], lectureIDs: [Int]?, source: FirestoreSource, completion: @escaping (Swift.Result<[Lecture], Error>) -> Void)

    func getUsersLectureInfo(source: FirestoreSource, completion: @escaping (Swift.Result<[LectureInfo], Error>) -> Void)
    func getUsersListenInfo(source: FirestoreSource, completion: @escaping (Swift.Result<[ListenInfo], Error>) -> Void)
    func getWeekLecturesIds(weekDays: [String], completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func getMonthLecturesIds(month: Int, year: Int, completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func getPopularLectureIds(completion: @escaping (Swift.Result<[Int], Error>) -> Void)

    func offlineUpdateLectureProgress(lecture: Lecture, lastPlayedPoint: Int)
    func updateLectureInfo(lectures: [Lecture],
                           isCompleted: Bool?,
                           isDownloaded: Bool?,
                           isFavourite: Bool?,
                           lastPlayedPoint: Int?,
                           completion: @escaping (Swift.Result<Bool, Error>) -> Void)
}

class DefaultLectureViewModel: NSObject, LectureViewModel {

    struct Notification {
        static let lectureUpdated = Foundation.Notification.Name(rawValue: "lectureUpdateNotification")
    }

    static var defaultModel: LectureViewModel = DefaultLectureViewModel()

    var allLectures: [Lecture] = []

    var userLectureInfo: [LectureInfo] = []

    override init() {
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(downloadsAddedNotification(_:)), name: Persistant.Notification.downloadsAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadUpdatedNotification(_:)), name: Persistant.Notification.downloadUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadsRemovedNotification(_:)), name: Persistant.Notification.downloadsRemoved, object: nil)
    }

    func getLectures(searchText: String?, sortType: LectureSortType?, filter: [Filter: [String]], lectureIDs: [Int]?, source: FirestoreSource, completion: @escaping (Swift.Result<[Lecture], Error>) -> Void) {

        if let lectureIDs = lectureIDs, lectureIDs.isEmpty {
            completion(.success([]))
        } else {

            if source == .cache {
                DispatchQueue.global().async {
                    var success: [Lecture] = Self.filter(lectures: self.allLectures, searchText: searchText, sortType: sortType, filter: filter, lectureIDs: lectureIDs)
                    success = Self.refreshLectureWithLectureInfo(lectures: success, lectureInfo: self.userLectureInfo)

                    DispatchQueue.main.async {
                        completion(.success(success))
                    }
                }
            } else {
                let query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.lectures.path)

                FirestoreManager.shared.getDocuments(query: query, source: source, completion: { (result: Swift.Result<[Lecture], Error>) in
                    switch result {
                    case .success(var success):
                        DispatchQueue.global().async {

                            var results = [Lecture]()

                            let startDate = Date()
                            success.forEach({ lecture in
                                let existingElements = results.filter { $0.id == lecture.id }
                                if existingElements.count == 0 {
                                    results.append(lecture)
                                }
                            })
                            let endDate = Date()
                            print("Took \(endDate.timeIntervalSince1970-startDate.timeIntervalSince1970) seconds to remove duplicate elements")
                            success = results   // Unique

                            success = Self.refreshLectureWithLectureInfo(lectures: success, lectureInfo: self.userLectureInfo)
                            self.allLectures = success

                            let success = Self.filter(lectures: success, searchText: searchText, sortType: sortType, filter: filter, lectureIDs: lectureIDs)
                            DispatchQueue.main.async {
                                completion(.success(success))
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            }
        }
    }
}

extension DefaultLectureViewModel {

    @objc func downloadsAddedNotification(_ notification: Foundation.Notification) {
        guard let dbLectures = notification.object as? [DBLecture] else { return }

        for dbLecture in dbLectures {
            let lectureIndexes = self.allLectures.allIndex(where: { $0.id == dbLecture.id })
            for index in lectureIndexes {
                allLectures[index].downloadingState = dbLecture.downloadStateEnum
            }
        }

        NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
    }

    @objc func downloadUpdatedNotification(_ notification: Foundation.Notification) {
        guard let dbLecture = notification.object as? DBLecture else { return }

        let lectureIndexes = self.allLectures.allIndex(where: { $0.id == dbLecture.id })
        for index in lectureIndexes {
            allLectures[index].downloadingState = dbLecture.downloadStateEnum
        }
        if !lectureIndexes.isEmpty {
            NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
        }
    }

    @objc func downloadsRemovedNotification(_ notification: Foundation.Notification) {
        guard let dbLectures = notification.object as? [DBLecture] else { return }

        for dbLecture in dbLectures {
            let lectureIndexes = self.allLectures.allIndex(where: { $0.id == dbLecture.id })
            for index in lectureIndexes {
                allLectures[index].downloadingState = dbLecture.downloadStateEnum
            }
        }

        NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
    }

    private func favouriteUpdated(lecture: Lecture, isFavourite: Bool) {

        let lectureIndexes = self.allLectures.allIndex (where: { $0.id == lecture.id })
        for index in lectureIndexes {
            self.allLectures[index].isFavourites = isFavourite
        }
        if !lectureIndexes.isEmpty {
            NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
        }
    }
}
