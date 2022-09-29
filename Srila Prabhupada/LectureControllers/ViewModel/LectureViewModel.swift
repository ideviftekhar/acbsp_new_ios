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

    func getFavoriteLectureIds(completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func getWeekLecturesIds(weekDays: [String], completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func getMonthLecturesIds(month: Int, year: Int, completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func getListenedLectureIds(completion: @escaping (Swift.Result<[Int], Error>) -> Void)
}

class DefaultLectureViewModel: NSObject, LectureViewModel {

    static let lectureUpdateNotification = Notification.Name(rawValue: "lectureUpdateNotification")

    var allLectures: [Lecture] = []

    override init() {
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(downloadAddedNotification(_:)), name: Persistant.downloadAddedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadUpdatedNotification(_:)), name: Persistant.downloadUpdatedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadRemovedNotification(_:)), name: Persistant.downloadRemovedNotification, object: nil)
    }

    @objc func downloadAddedNotification(_ notification: Notification) {
        guard let dbLecture = notification.object as? DBLecture else { return }
        if let index = allLectures.firstIndex(where: { $0.id == dbLecture.id }) {
            allLectures[index].downloadingState = dbLecture.downloadStateEnum
            NotificationCenter.default.post(name: DefaultLectureViewModel.lectureUpdateNotification, object: nil)
        }
    }

    @objc func downloadUpdatedNotification(_ notification: Notification) {
        guard let dbLecture = notification.object as? DBLecture else { return }
        if let index = allLectures.firstIndex(where: { $0.id == dbLecture.id }) {
            allLectures[index].downloadingState = dbLecture.downloadStateEnum
            NotificationCenter.default.post(name: DefaultLectureViewModel.lectureUpdateNotification, object: nil)
        }
    }

    @objc func downloadRemovedNotification(_ notification: Notification) {
        guard let dbLecture = notification.object as? DBLecture else { return }
        if let index = allLectures.firstIndex(where: { $0.id == dbLecture.id }) {
            allLectures[index].downloadingState = dbLecture.downloadStateEnum
            NotificationCenter.default.post(name: DefaultLectureViewModel.lectureUpdateNotification, object: nil)
        }
    }

    static func filter(lectures: [Lecture], searchText: String?, sortType: LectureSortType, filter: [Filter: [String]], lectureIDs: [Int]?) -> [Lecture] {
        var lectures: [Lecture] = lectures

        if let lectureIDs = lectureIDs {
            lectures = lectures.filter({ lectureIDs.contains($0.id) })
        }

        if let searchText = searchText, !searchText.isEmpty {
            let selectedSubtypes: [String] = searchText.split(separator: " ").map { String($0) }

            lectures = lectures.filter { (lecture: Lecture) in
                return selectedSubtypes.first(where: { (subtype: String) in
                    return lecture.title.first(where: { (title: String) in
                        title.localizedCaseInsensitiveContains(subtype)
                    }) != nil
                }) != nil
            }
        }

        for (filter, subtypes) in filter {
            lectures = filter.filter(lectures, selectedSubtypes: subtypes)
        }

        lectures = sortType.sort(lectures)
        return lectures
    }

    func getLectures(searchText: String?, sortType: LectureSortType, filter: [Filter: [String]], lectureIDs: [Int]?, source: FirestoreSource, completion: @escaping (Swift.Result<[Lecture], Error>) -> Void) {

        if let lectureIDs = lectureIDs, lectureIDs.isEmpty {
            completion(.success([]))
        } else {

            if source == .cache {
                DispatchQueue.global().async {
                    let success = Self.filter(lectures: self.allLectures, searchText: searchText, sortType: sortType, filter: filter, lectureIDs: lectureIDs)
                    DispatchQueue.main.async {
                        completion(.success(success))
                    }
                }
            } else {
                let query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.lectures.path)

                FirestoreManager.shared.getDocuments(query: query, source: source, completion: { (result: Swift.Result<[Lecture], Error>) in
                    switch result {
                    case .success(let success):
                        self.allLectures = success

                        DispatchQueue.global().async {
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

    func getFavoriteLectureIds(completion: @escaping (Swift.Result<[Int], Error>) -> Void) {

        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        var query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersLectureInfo(userId: currentUser.uid).path)

        query = query.whereField("isFavourite", isEqualTo: true)

        FirestoreManager.shared.getDocuments(query: query, source: FirestoreSource.default, completion: { (result: Swift.Result<[LectureInfo], Error>) in
            switch result {
            case .success(let success):
                let lectureIDs: [Int] = success.map({ $0.id })
                completion(.success(lectureIDs))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func getListenedLectureIds(completion: @escaping (Swift.Result<[Int], Error>) -> Void) {

        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        let query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersListenInfo(userId: currentUser.uid).path)

        FirestoreManager.shared.getDocuments(query: query, source: FirestoreSource.default, completion: { (result: Swift.Result<[ListenInfo], Error>) in
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

    func getWeekLecturesIds(weekDays: [String], completion: @escaping (Swift.Result<[Int], Error>) -> Void) {

        var query: Query =  FirestoreManager.shared.firestore.collection(FirestoreCollection.topLectures.path)

        query = query.whereField("documentId", in: weekDays)

        FirestoreManager.shared.getDocuments(query: query, source: FirestoreSource.default, completion: { (result: Swift.Result<[TopLecture], Error>) in
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

        FirestoreManager.shared.getDocuments(query: query, source: FirestoreSource.default, completion: { (result: Swift.Result<[TopLecture], Error>) in
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
}
