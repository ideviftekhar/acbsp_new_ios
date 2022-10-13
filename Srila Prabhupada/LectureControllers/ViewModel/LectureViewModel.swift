//
//  LectureViewModel.swift
//  Srila Prabhupada
//
//  Created by IE on 9/22/22.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreSwift

protocol LectureViewModel: AnyObject {

    func getLectures(searchText: String?, sortType: LectureSortType, filter: [Filter: [String]], lectureIDs: [Int]?, source: FirestoreSource, completion: @escaping (Swift.Result<[Lecture], Error>) -> Void)

    func getUsersLectureInfo(source: FirestoreSource, completion: @escaping (Swift.Result<[LectureInfo], Error>) -> Void)
    func getUsersListenInfo(source: FirestoreSource, completion: @escaping (Swift.Result<[ListenInfo], Error>) -> Void)
    func getWeekLecturesIds(weekDays: [String], completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func getMonthLecturesIds(month: Int, year: Int, completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func getPopularLectureIds(completion: @escaping (Swift.Result<[Int], Error>) -> Void)

    func favourite(lecture: Lecture, isFavourite: Bool, completion: @escaping (Swift.Result<Bool, Error>) -> Void)
}

class DefaultLectureViewModel: NSObject, LectureViewModel {

    struct Notification {
        static let lectureUpdated = Foundation.Notification.Name(rawValue: "lectureUpdateNotification")
    }

    var allLectures: [Lecture] = []

    var userLectureInfo: [LectureInfo] = []
    var userListenInfo: [ListenInfo] = []

    override init() {
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(downloadAddedNotification(_:)), name: Persistant.Notification.downloadAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadUpdatedNotification(_:)), name: Persistant.Notification.downloadUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadRemovedNotification(_:)), name: Persistant.Notification.downloadRemoved, object: nil)
    }

    static func filter(lectures: [Lecture], searchText: String?, sortType: LectureSortType, filter: [Filter: [String]], lectureIDs: [Int]?) -> [Lecture] {
        var lectures: [Lecture] = lectures

        if let lectureIDs = lectureIDs {
            lectures = lectures.filter({ lectureIDs.contains($0.id) })
        }

        if let searchText = searchText, !searchText.isEmpty {

            lectures = lectures.filter { (lecture: Lecture) in
                let matched: Bool = lecture.searchableTexts.first(where: { $0.localizedCaseInsensitiveContains(searchText) }) != nil
                return matched
            }
        }

        for (filter, subtypes) in filter {
            lectures = filter.filter(lectures, selectedSubtypes: subtypes)
        }

        lectures = sortType.sort(lectures)
        return lectures
    }

    static private func refreshLectureWithLectureInfo(lectures: [Lecture], lectureInfo: [LectureInfo]) -> [Lecture] {
        let lectures = lectures.map { lecture -> Lecture in
            var lecture = lecture
            if let lectureInfo = lectureInfo.first(where: { $0.id == lecture.id }) {
                lecture.isFavourites = lectureInfo.isFavourite
                lecture.lastPlayedPoint = lectureInfo.lastPlayedPoint
            }

            return lecture
        }
        return lectures
    }

    func getLectures(searchText: String?, sortType: LectureSortType, filter: [Filter: [String]], lectureIDs: [Int]?, source: FirestoreSource, completion: @escaping (Swift.Result<[Lecture], Error>) -> Void) {

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

    func getUsersLectureInfo(source: FirestoreSource, completion: @escaping (Swift.Result<[LectureInfo], Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        if source == .cache {
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    completion(.success(self.userLectureInfo))
                }
            }
        } else {
            var query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersLectureInfo(userId: currentUser.uid).path)

            FirestoreManager.shared.getDocuments(query: query, source: .default, completion: { (result: Swift.Result<[LectureInfo], Error>) in
                switch result {
                case .success(let success):
                    self.userLectureInfo = success
                    completion(.success(success))

                    if source != .cache {
                        DispatchQueue.global().async {
                            self.allLectures = Self.refreshLectureWithLectureInfo(lectures: self.allLectures, lectureInfo: success)
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
                            }
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }

    func favourite(lecture: Lecture, isFavourite: Bool, completion: @escaping (Swift.Result<Bool, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        var query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersLectureInfo(userId: currentUser.uid).path)
        query = query.whereField("id", isEqualTo: lecture.id).limit(to: 1)

        FirestoreManager.shared.getRawDocuments(query: query, source: .server) { result in
            switch result {
            case .success(let success):

                if let foundInfo = success.first {
                    let isFavouriteData: [String: Any] = ["isFavourite": isFavourite]
                    foundInfo.reference.updateData(isFavouriteData) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {

                            if let index = self.userLectureInfo.firstIndex(where: { $0.id == lecture.id }) {
                                self.userLectureInfo[index].isFavourite = isFavourite
                                NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
                            }
                            if let index = self.allLectures.firstIndex(where: { $0.id == lecture.id && $0.creationTimestamp == lecture.creationTimestamp }) {
                                self.allLectures[index].isFavourites = isFavourite
                                NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
                            }
                            completion(.success(true))
                        }
                    }
                } else {
                    let query: CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersLectureInfo(userId: currentUser.uid).path)

                    let currentTimestamp = Int(Date().timeIntervalSince1970*1000)
                    let isFavouriteData: [String: Any] = [
                        "id": lecture.id,
                        "isFavourite": isFavourite,
                        "creationTimestamp": currentTimestamp,
                        "lastModifiedTimestamp": currentTimestamp,
                        "isCompleted": false,
                        "isDownloaded": false,
                        "isInPrivateList": false,
                        "isInPublicList": false,
                        "lastPlayedPoint": 0
                    ]

                    query.addDocument(data: isFavouriteData) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {

                            if let index = self.allLectures.firstIndex(where: { $0.id == lecture.id && $0.creationTimestamp == lecture.creationTimestamp }) {
                                self.allLectures[index].isFavourites = isFavourite
                                NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
                            }

                            completion(.success(true))
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension DefaultLectureViewModel {

    func getUsersListenInfo(source: FirestoreSource, completion: @escaping (Swift.Result<[ListenInfo], Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        if source == .cache {
            DispatchQueue.main.async {
                completion(.success(self.userListenInfo))
            }
        } else {
            let query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersListenInfo(userId: currentUser.uid).path)

            FirestoreManager.shared.getDocuments(query: query, source: .default, completion: { (result: Swift.Result<[ListenInfo], Error>) in
                switch result {
                case .success(let success):
                    self.userListenInfo = success
                    completion(.success(success))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }

}

extension DefaultLectureViewModel {

    func getWeekLecturesIds(weekDays: [String], completion: @escaping (Swift.Result<[Int], Error>) -> Void) {

        var query: Query =  FirestoreManager.shared.firestore.collection(FirestoreCollection.topLectures.path)

        query = query.whereField("documentId", in: weekDays)

        FirestoreManager.shared.getDocuments(query: query, source: .default, completion: { (result: Swift.Result<[TopLecture], Error>) in
            switch result {
            case .success(let success):
                let lectureIDs: [Int] = success.flatMap({ obj -> [Int] in
                    obj.playedIds
                })
                completion(.success(lectureIDs))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func getMonthLecturesIds(month: Int, year: Int, completion: @escaping (Swift.Result<[Int], Error>) -> Void) {

        var query: Query =  FirestoreManager.shared.firestore.collection((FirestoreCollection.topLectures.path))

        query = query.whereField("creationDay.month", isEqualTo: month)
        query = query.whereField("creationDay.year", isEqualTo: year)

        FirestoreManager.shared.getDocuments(query: query, source: .default, completion: { (result: Swift.Result<[TopLecture], Error>) in
            switch result {
            case .success(let success):
                let lectureIDs: [Int] = success.flatMap({ obj -> [Int] in
                    obj.playedIds
                })
                completion(.success(lectureIDs))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func getPopularLectureIds(completion: @escaping (Swift.Result<[Int], Error>) -> Void) {

        let query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.topLectures.path)

        FirestoreManager.shared.getDocuments(query: query, source: .default) { (result: Swift.Result<[TopLecture], Error>) in

            switch result {
            case .success(let success):
                let lectureIDs: [Int] = success.flatMap({ obj -> [Int] in
                    obj.playedIds
                })

                var counts: [Int: Int] = [:]
                lectureIDs.forEach { counts[$0, default: 0] += 1 }

                let tuplesSortedByValue: [Dictionary<Int, Int>.Element] = counts.sorted { $0.value > $1.value }

                let sortedLectureIDs: [Int] = tuplesSortedByValue.map { $0.key }
                completion(.success(sortedLectureIDs))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension DefaultLectureViewModel {

    @objc func downloadAddedNotification(_ notification: Foundation.Notification) {
        guard let dbLecture = notification.object as? DBLecture else { return }
        if let index = allLectures.firstIndex(where: { $0.id == dbLecture.id && $0.creationTimestamp == dbLecture.creationTimestamp }) {
            allLectures[index].downloadingState = dbLecture.downloadStateEnum
            NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
        }
    }

    @objc func downloadUpdatedNotification(_ notification: Foundation.Notification) {
        guard let dbLecture = notification.object as? DBLecture else { return }
        if let index = allLectures.firstIndex(where: { $0.id == dbLecture.id && $0.creationTimestamp == dbLecture.creationTimestamp }) {
            allLectures[index].downloadingState = dbLecture.downloadStateEnum
            NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
        }
    }

    @objc func downloadRemovedNotification(_ notification: Foundation.Notification) {
        guard let dbLecture = notification.object as? DBLecture else { return }
        if let index = allLectures.firstIndex(where: { $0.id == dbLecture.id && $0.creationTimestamp == dbLecture.creationTimestamp }) {
            allLectures[index].downloadingState = dbLecture.downloadStateEnum
            NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
        }
    }

    private func favouriteUpdated(lecture: Lecture, isFavourite: Bool) {
        if let index = self.allLectures.firstIndex(where: { $0.id == lecture.id && $0.creationTimestamp == lecture.creationTimestamp }) {
            self.allLectures[index].isFavourites = isFavourite
            NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
        }
    }
}
