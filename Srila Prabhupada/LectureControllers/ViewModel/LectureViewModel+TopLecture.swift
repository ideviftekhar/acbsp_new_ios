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

    func updateTopLecture(day: Int, month: Int, year: Int, lectureID: Int, completion: @escaping (Swift.Result<TopLecture, Error>) -> Void) {

        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        let collectionReference: CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.topLectures.path)

        let documentID = "\(day)-\(month)-\(year)"
        let documentReference = collectionReference.document(documentID)
        
        FirestoreManager.shared.getRawDocument(documentReference: documentReference, source: .server, completion: { result in
            switch result {
            case .success(let success):

                let currentTimestamp = Int(Date().timeIntervalSince1970*1000)
                let data: [String: Any] = [
                    "lastModifiedTimestamp": currentTimestamp,
                    "playedBy": FieldValue.arrayUnion([currentUser.uid]),
                    "playedIds": FieldValue.arrayUnion([lectureID]),
                ]

                success.reference.updateData(data, completion: { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        FirestoreManager.shared.getDocument(documentReference: documentReference, source: .default, completion: completion)
                    }
                })
            case .failure(let error):

                let currentTimestamp = Int(Date().timeIntervalSince1970*1000)
                let data: [String: Any] = [
                    "audioPlayedTime": 0,
                    "createdDay": ["day":day, "month": month, "year": year],
                    "creationTimestamp": currentTimestamp,
                    "documentId": documentID,
                    "documentPath": documentReference.path,
                    "lastModifiedTimestamp": currentTimestamp,
                    "playedBy": [currentUser.uid],
                    "playedIds": [lectureID],
                    "videoPlayedTime": 0
                ]

                documentReference.setData(data, merge: true, completion: { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        FirestoreManager.shared.getDocument(documentReference: documentReference, source: .default, completion: completion)
                    }
                })

                completion(.failure(error))
            }
        })
    }
}
