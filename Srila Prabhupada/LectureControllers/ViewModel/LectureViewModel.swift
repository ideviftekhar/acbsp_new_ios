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

    func getLectures(searchText: String?, sortyType: SortType, filter: [Filter: [String]], lectureIDs: [Int]?, completion: @escaping (Swift.Result<[Lecture], Error>) -> Void)

    func getFavoriteLectureIds(completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func getWeekLecturesIds(weekDays: [String], completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func getMonthLecturesIds(month: Int, year: Int, completion: @escaping (Swift.Result<[Int], Error>) -> Void)
}

class DefaultLectureViewModel: NSObject, LectureViewModel {

    let firestore: Firestore = {
        let firestore = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        firestore.settings = settings

        return firestore
    }()

    func getLectures(searchText: String?, sortyType: SortType, filter: [Filter: [String]], lectureIDs: [Int]?, completion: @escaping (Swift.Result<[Lecture], Error>) -> Void) {

        if var lectureIDs = lectureIDs {
            if lectureIDs.isEmpty {
                completion(.success([]))
            } else {

                var lectureIdsGroup: [[Int]] = []

                while !lectureIDs.isEmpty {
                    let ids = Array(lectureIDs.suffix(10))
                    lectureIdsGroup.append(ids)
                    lectureIDs = Array(lectureIDs.dropFirst(10))
                }

                var lectures: [Lecture] = []
                var completedCount = 0
                for lectureIDs in lectureIdsGroup {

                    var query: Query = firestore.collection(Environment.current.lectureCollectionName)

                    if let searchText = searchText, !searchText.isEmpty {
                        query = query.whereField("title", arrayContains: searchText)
                    }

                    query = query.whereField("id", in: lectureIDs)

                    for (filter, subtypes) in filter {
                        query = filter.applyOn(query: query, selectedSubtypes: subtypes)
                    }

                    query = sortyType.applyOn(query: query)

                    query.getDocuments { snapshot, _ in

                        completedCount += 1

                        if let documents: [QueryDocumentSnapshot] = snapshot?.documents {

                            let remoteLectures = documents.map({ Lecture($0.data()) })

                            lectures.append(contentsOf: remoteLectures)
                        }

                        if completedCount == lectureIdsGroup.count {
                            completion(.success(lectures))
                        }
                    }
                }
            }
        } else {
            var query: Query = firestore.collection(Environment.current.lectureCollectionName)

            if let searchText = searchText, !searchText.isEmpty {
                query = query.whereField("title", arrayContains: searchText)
            }

            for (filter, subtypes) in filter {
                query = filter.applyOn(query: query, selectedSubtypes: subtypes)
            }

            query = sortyType.applyOn(query: query)

            query.getDocuments { snapshot, error in

                if let error = error {
                    completion(.failure(error))
               } else if let documents: [QueryDocumentSnapshot] = snapshot?.documents {

                   let lectures = documents.map({ Lecture($0.data()) })
                   completion(.success(lectures))
                }
            }
        }
    }

    func getFavoriteLectureIds(completion: @escaping (Swift.Result<[Int], Error>) -> Void) {

        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        let documentPath = "users/\(currentUser.uid)/lectureinfo"

        var query: Query = firestore.collection(documentPath)

        query = query.whereField("isFavourite", isEqualTo: true)

        query.getDocuments { snapshot, error in

            if let error = error {
                completion(.failure(error))
            } else if let documents: [QueryDocumentSnapshot] = snapshot?.documents {

                let lectureIDs: [Int] = documents.map({
                    let info: LectureInfo = LectureInfo($0.data())
                    return info.id
                })

                completion(.success(lectureIDs))
            }
        }
    }

    func getWeekLecturesIds(weekDays: [String], completion: @escaping (Swift.Result<[Int], Error>) -> Void) {

        var query: Query = firestore.collection("TopLectures")

        query = query.whereField("documentId", in: weekDays)

        query.getDocuments { snapshot, error in

            if let error = error {
                completion(.failure(error))
           } else if let documents: [QueryDocumentSnapshot] = snapshot?.documents {

               let lectureIDs: [Int] = documents.flatMap({
                   let lecture: TopLectures = TopLectures($0.data())
                   return lecture.playedIds
               })

               completion(.success(lectureIDs))
            }
        }
    }

    func getMonthLecturesIds(month: Int, year: Int, completion: @escaping (Swift.Result<[Int], Error>) -> Void) {

        var query: Query = firestore.collection("TopLectures")

        query = query.whereField("creationDay.month", isEqualTo: month)
        query = query.whereField("creationDay.year", isEqualTo: year)

        query.getDocuments { snapshot, error in

            if let error = error {
                completion(.failure(error))
           } else if let documents: [QueryDocumentSnapshot] = snapshot?.documents {

               let lectureIDs: [Int] = documents.flatMap({
                   let lecture: TopLectures = TopLectures($0.data())
                   return lecture.playedIds
               })

               completion(.success(lectureIDs))
            }
        }
    }
}
