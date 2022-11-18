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

    func clearCache()

    func getLectures(searchText: String?,
                     sortType: LectureSortType?,
                     filter: [Filter: [String]],
                     lectureIDs: [Int]?,
                     source: FirestoreSource,
                     progress: ((_ progress: CGFloat) -> Void)?,
                     completion: @escaping (Swift.Result<[Lecture], Error>) -> Void)

    // Lecture Info
    func getUsersLectureInfo(source: FirestoreSource, completion: @escaping (Swift.Result<[LectureInfo], Error>) -> Void)
    func offlineUpdateLectureProgress(lecture: Lecture, lastPlayedPoint: Int)
    func updateLectureInfo(lectures: [Lecture],
                           isCompleted: Bool?,
                           isDownloaded: Bool?,
                           isFavourite: Bool?,
                           lastPlayedPoint: Int?,
                           completion: @escaping (Swift.Result<Bool, Error>) -> Void)

    // Listen Info
    func getUsersListenInfo(source: FirestoreSource, completion: @escaping (Swift.Result<[ListenInfo], Error>) -> Void)
    func updateListenInfo(date: Date, addListenSeconds seconds: Int, lecture: Lecture, completion: @escaping (Swift.Result<ListenInfo, Error>) -> Void)

    // Top Lecture
    func getWeekLecturesIds(weekDays: [String], completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func getMonthLecturesIds(month: Int, year: Int, completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func getPopularLectureIds(completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func updateTopLecture(date: Date, lectureID: Int, completion: @escaping (Swift.Result<TopLecture, Error>) -> Void)
}

class DefaultLectureViewModel: NSObject, LectureViewModel {

    struct Notification {
        static let lectureUpdated = Foundation.Notification.Name(rawValue: "lectureUpdateNotification")
    }

    static var defaultModel: LectureViewModel = DefaultLectureViewModel()

    lazy var serialLectureWorkerQueue = DispatchQueue(label: "serialLectureWorkerQueue\(Self.self)", qos: .userInteractive)

    func clearCache() {
        serialLectureWorkerQueue.async { [self] in
            allLectures.removeAll()
            userLectureInfo.removeAll()
        }
    }

    var allLectures: [Lecture] = []

    var userLectureInfo: [LectureInfo] = []

    override init() {
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(downloadsAddedNotification(_:)), name: Persistant.Notification.downloadsAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadUpdatedNotification(_:)), name: Persistant.Notification.downloadUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadsRemovedNotification(_:)), name: Persistant.Notification.downloadsRemoved, object: nil)
    }

    func getLectures(searchText: String?, sortType: LectureSortType?, filter: [Filter: [String]], lectureIDs: [Int]?, source: FirestoreSource, progress: ((_ progress: CGFloat) -> Void)?, completion: @escaping (Swift.Result<[Lecture], Error>) -> Void) {

        if let lectureIDs = lectureIDs, lectureIDs.isEmpty {
            mainThreadSafe {
                completion(.success([]))
            }
        } else {

            if source == .cache {
                serialLectureWorkerQueue.async {
                    var success: [Lecture] = Self.filter(lectures: self.allLectures, searchText: searchText, sortType: sortType, filter: filter, lectureIDs: lectureIDs)
                    success = Self.refreshLectureWithLectureInfo(lectures: success, lectureInfos: self.userLectureInfo, downloadedLectures: Persistant.shared.getAllDBLectures())

                    DispatchQueue.main.async {
                        completion(.success(success))
                    }
                }
            } else {
                let query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.lectures.path)

                FirestoreManager.shared.getDocuments(query: query, source: source, completion: { [self] (result: Swift.Result<[Lecture], Error>) in
                    switch result {
                    case .success(var success):
                        serialLectureWorkerQueue.async {

                            var results = [Lecture]()

                            let startDate = Date()

                            let total: CGFloat = CGFloat(success.count)
                            var iteration: CGFloat = 0
                            success.forEach({ lecture in

                                let existingElements = results.filter { $0.id == lecture.id }
                                if existingElements.count == 0 {
                                    results.append(lecture)
                                }

                                iteration += 1
                                if let progress = progress {
                                    DispatchQueue.main.async {
                                        progress(iteration/total)
                                    }
                                }
                            })
                            let endDate = Date()
                            print("Took \(endDate.timeIntervalSince1970-startDate.timeIntervalSince1970) seconds to remove duplicate elements")
                            success = results   // Unique

                            if !self.userLectureInfo.isEmpty {
                                success = Self.refreshLectureWithLectureInfo(lectures: success, lectureInfos: self.userLectureInfo, downloadedLectures: Persistant.shared.getAllDBLectures())
                            }

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

        var updatedLectures: [Lecture] = []
        for dbLecture in dbLectures {
            let lectureIndexes = self.allLectures.allIndex(where: { $0.id == dbLecture.id })
            for index in lectureIndexes {
                allLectures[index].downloadState = dbLecture.downloadStateEnum
                updatedLectures.append(allLectures[index])
            }
        }

        if !updatedLectures.isEmpty {
            mainThreadSafe {
                NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: updatedLectures)
            }
        }
    }

    @objc func downloadUpdatedNotification(_ notification: Foundation.Notification) {
        guard let dbLecture = notification.object as? DBLecture else { return }

        var updatedLectures: [Lecture] = []
        let lectureIndexes = self.allLectures.allIndex(where: { $0.id == dbLecture.id })
        for index in lectureIndexes {
            allLectures[index].downloadState = dbLecture.downloadStateEnum
            updatedLectures.append(allLectures[index])
        }
        if !updatedLectures.isEmpty {
            mainThreadSafe {
                NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: updatedLectures)
            }
        }
    }

    @objc func downloadsRemovedNotification(_ notification: Foundation.Notification) {
        guard let dbLectures = notification.object as? [DBLecture] else { return }

        var updatedLectures: [Lecture] = []
        for dbLecture in dbLectures {
            let lectureIndexes = self.allLectures.allIndex(where: { $0.id == dbLecture.id })
            for index in lectureIndexes {
                allLectures[index].downloadState = dbLecture.downloadStateEnum
                updatedLectures.append(allLectures[index])
            }
        }

        if !updatedLectures.isEmpty {
            mainThreadSafe {
                NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: updatedLectures)
            }
        }
    }
}
