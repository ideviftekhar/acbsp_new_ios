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
    func getUsersLectureInfo(source: FirestoreSource, progress: ((_ progress: CGFloat) -> Void)?, completion: @escaping (Swift.Result<[LectureInfo], Error>) -> Void)
    func offlineUpdateLectureProgress(lecture: Lecture, lastPlayedPoint: Int)
    func updateLectureInfo(lectures: [Lecture],
                           isCompleted: Bool?,
                           isDownloaded: Bool?,
                           isFavourite: Bool?,
                           lastPlayedPoint: Int?,
                           postUpdate: Bool,
                           completion: @escaping (Swift.Result<Bool, Error>) -> Void)

    // Listen Info
    func getUsersListenInfo(source: FirestoreSource, completion: @escaping (Swift.Result<[ListenInfo], Error>) -> Void)
    func updateListenInfo(date: Date, addListenSeconds seconds: Int, lecture: Lecture, completion: @escaping (Swift.Result<ListenInfo, Error>) -> Void)

    // Top Lecture
    func getWeekLecturesIds(weekDays: [String], completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func getMonthLecturesIds(month: Int, year: Int, completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func getPopularLectureIds(completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func updateTopLecture(date: Date, lectureID: Int, completion: @escaping (Swift.Result<TopLecture, Error>) -> Void)

    func getRecentlyPlayedLectureIDs(source: FirestoreSource, completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func addToRecentlyPlayed(lecture: Lecture, completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func removeFromRecentlyPlayed(lecture: Lecture, completion: @escaping (Swift.Result<[Int], Error>) -> Void)
}

class DefaultLectureViewModel: NSObject, LectureViewModel {

    struct Notification {
        static let lectureUpdated = Foundation.Notification.Name(rawValue: "lectureUpdateNotification")
    }

    static var defaultModel: LectureViewModel = DefaultLectureViewModel()

    lazy var serialLectureWorkerQueue = DispatchQueue(label: "serialLectureWorkerQueue\(Self.self)", qos: .userInteractive)
    lazy var parallelLectureWorkerQueue = DispatchQueue(label: "parallelLectureWorkerQueue\(Self.self)", qos: .userInteractive, attributes: .concurrent)

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
        NotificationCenter.default.addObserver(self, selector: #selector(downloadsUpdatedNotification(_:)), name: Persistant.Notification.downloadsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadsRemovedNotification(_:)), name: Persistant.Notification.downloadsRemoved, object: nil)
    }

    func getLectures(searchText: String?, sortType: LectureSortType?, filter: [Filter: [String]], lectureIDs: [Int]?, source: FirestoreSource, progress: ((_ progress: CGFloat) -> Void)?, completion: @escaping (Swift.Result<[Lecture], Error>) -> Void) {

        if let lectureIDs = lectureIDs, lectureIDs.isEmpty {
            mainThreadSafe {
                completion(.success([]))
            }
        } else {

            if source == .cache {
                parallelLectureWorkerQueue.async {
                    let success: [Lecture] = Self.filter(lectures: self.allLectures, searchText: searchText, sortType: sortType, filter: filter, lectureIDs: lectureIDs)

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

                            let incomingIDs: Set<Int> = Set(success.map({ $0.id }))

                            var leftoverIDs = incomingIDs

                            let total: CGFloat = CGFloat(success.count)
                            var iteration: CGFloat = 0
                            results = success.reduce([]) { result, lecture in
                                iteration += 1
                                if let progress = progress {
                                    DispatchQueue.main.async {
                                        progress(iteration/total)
                                    }
                                }
                                let lectureID = lecture.id
                                guard leftoverIDs.contains(where: { $0 == lectureID }) else {
                                    return result
                                }

                                leftoverIDs.remove(lectureID)
                                return result + [lecture]
                            }

                            let endDate = Date()
                            print("Took \(endDate.timeIntervalSince1970-startDate.timeIntervalSince1970) seconds to remove \(success.count - results.count) duplicate lecture(s)")
                            success = results   // Unique

                            if !self.userLectureInfo.isEmpty {
                                success = Self.refreshLectureWithLectureInfo(lectures: success, lectureInfos: self.userLectureInfo, downloadedLectures: Persistant.shared.getAllDBLectures(), progress: progress)
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
        serialLectureWorkerQueue.async {
            guard let dbLectures = notification.object as? [DBLecture] else { return }

            var updatedLectures: [Lecture] = []
            for dbLecture in dbLectures {
                let lectureIndexes = self.allLectures.allIndex(where: { $0.id == dbLecture.id })
                for index in lectureIndexes {
                    self.allLectures[index].downloadState = dbLecture.downloadStateEnum
                    self.allLectures[index].downloadError = dbLecture.downloadError
                    updatedLectures.append(self.allLectures[index])
                }
            }

            if !updatedLectures.isEmpty {
                mainThreadSafe {
                    NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: updatedLectures)
                }
            }
        }
    }

    @objc func downloadsUpdatedNotification(_ notification: Foundation.Notification) {

        serialLectureWorkerQueue.async {
            guard let dbLectures = notification.object as? [DBLecture] else { return }

            var updatedLectures: [Lecture] = []
            for dbLecture in dbLectures {
                let lectureIndexes = self.allLectures.allIndex(where: { $0.id == dbLecture.id })
                for index in lectureIndexes {
                    self.allLectures[index].downloadError = dbLecture.downloadError
                    self.allLectures[index].downloadState = dbLecture.downloadStateEnum
                    updatedLectures.append(self.allLectures[index])
                }
            }
            if !updatedLectures.isEmpty {
                mainThreadSafe {
                    NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: updatedLectures)
                }
            }
        }
    }

    @objc func downloadsRemovedNotification(_ notification: Foundation.Notification) {

        serialLectureWorkerQueue.async {
            guard let lectureIDs = notification.object as? [Int] else { return }

            var updatedLectures: [Lecture] = []
            for lectureID in lectureIDs {
                let lectureIndexes = self.allLectures.allIndex(where: { $0.id ==  lectureID })
                for index in lectureIndexes {
                    self.allLectures[index].downloadState = .notDownloaded
                    self.allLectures[index].downloadError = nil
                    updatedLectures.append(self.allLectures[index])
                }
            }

            if !updatedLectures.isEmpty {
                mainThreadSafe {
                    NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: updatedLectures)
                }
            }
        }
    }
}
