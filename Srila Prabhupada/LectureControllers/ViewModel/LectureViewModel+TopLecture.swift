//
//  TopLectureViewModel.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/13/22.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

extension DefaultLectureViewModel {

    func getWeekLecturesIds(weekDays: [String], completion: @escaping (Swift.Result<[Int], Error>) -> Void) {

        var query: Query =  FirestoreManager.shared.firestore.collection(FirestoreCollection.topLectures.path)

        query = query.whereField("documentId", in: weekDays)

        FirestoreManager.shared.getDocuments(query: query, source: .default, completion: { (result: Swift.Result<[TopLecture], Error>) in
            switch result {
            case .success(let success):
                var lectureIDs: [Int] = success.flatMap({ obj -> [Int] in
                    obj.playedIds
                })
                let uniqueIds: Set<Int> = Set(lectureIDs)
                lectureIDs = Array(uniqueIds)

                completion(.success(lectureIDs))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func getMonthLecturesIds(month: Int, year: Int, completion: @escaping (Swift.Result<[Int], Error>) -> Void) {

        var query: Query =  FirestoreManager.shared.firestore.collection((FirestoreCollection.topLectures.path))

        query = query.whereField("createdDay.month", isEqualTo: month)
        query = query.whereField("createdDay.year", isEqualTo: year)

        FirestoreManager.shared.getDocuments(query: query, source: .default, completion: { (result: Swift.Result<[TopLecture], Error>) in
            switch result {
            case .success(let success):
                var lectureIDs: [Int] = success.flatMap({ obj -> [Int] in
                    obj.playedIds
                })
                let uniqueIds: Set<Int> = Set(lectureIDs)
                lectureIDs = Array(uniqueIds)

                completion(.success(lectureIDs))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func getPopularLectureIds(completion: @escaping (Swift.Result<[Int], Error>) -> Void) {

        let query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.topLectures.path)

        FirestoreManager.shared.getDocuments(query: query, source: .default, completion: { (result: Swift.Result<[TopLecture], Error>) in

            switch result {
            case .success(let success):
                var lectureIDs: [Int] = success.flatMap({ obj -> [Int] in
                    obj.playedIds
                })
                let uniqueIds: Set<Int> = Set(lectureIDs)
                lectureIDs = Array(uniqueIds)

                var counts: [Int: Int] = [:]
                lectureIDs.forEach { counts[$0, default: 0] += 1 }

                let tuplesSortedByValue: [Dictionary<Int, Int>.Element] = counts.sorted { $0.value > $1.value }
                let lectureIds: [Int] = tuplesSortedByValue.map { $0.key }

                completion(.success(lectureIds))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func updateTopLecture(date: Date, lectureID: Int, completion: @escaping (Swift.Result<TopLecture, Error>) -> Void) {

        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        let collectionReference: CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.topLectures.path)

        let documentID = DateFormatter.d_M_yyyy.string(from: date)
        let documentReference = collectionReference.document(documentID)

        FirestoreManager.shared.getRawDocument(documentReference: documentReference, source: .server, completion: { result in
            switch result {
            case .success(let success):

                let currentTimestamp = Int(Date().timeIntervalSince1970*1000)

                var data: [String: Any] = [:]
                data["lastModifiedTimestamp"] = currentTimestamp

                if success.data() == nil {

                    let components = date.components(.day, .month, .year)

                    data["audioPlayedTime"] = 0
                    data["videoPlayedTime"] = 0
                    data["createdDay"] = ["day": components.day ?? 1, "month": components.month ?? 1, "year": components.year ?? 1970]
                    data["creationTimestamp"] = currentTimestamp
                    data["documentId"] = documentID
                    data["documentPath"] = documentReference.path
                    data["playedBy"] = [currentUser.uid]
                    data["playedIds"] = [lectureID]
                } else {
                    data["playedBy"] = FieldValue.arrayUnion([currentUser.uid])
                    data["playedIds"] = FieldValue.arrayUnion([lectureID])
                }

                success.reference.setData(data, merge: true, completion: { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        FirestoreManager.shared.getDocument(documentReference: documentReference, source: .default, completion: completion)
                    }
                })
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}
