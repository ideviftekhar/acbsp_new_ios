//
//  LectureInfoViewModel.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/13/22.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

extension DefaultLectureViewModel {

    func getUsersLectureInfo(source: FirestoreSource, completion: @escaping (Swift.Result<[LectureInfo], Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        if source == .cache {
            serialLectureWorkerQueue.async {
                DispatchQueue.main.async {
                    completion(.success(self.userLectureInfo))
                }
            }
        } else {
            let query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersLectureInfo(userId: currentUser.uid).path)

            FirestoreManager.shared.getDocuments(query: query, source: .default, completion: { [self] (result: Swift.Result<[LectureInfo], Error>) in
                switch result {
                case .success(let success):
                    self.userLectureInfo = success
                    completion(.success(success))

                    if source != .cache {
                        serialLectureWorkerQueue.async {
                            if !self.allLectures.isEmpty {
                                self.allLectures = Self.refreshLectureWithLectureInfo(lectures: self.allLectures, lectureInfo: success)
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
                                }
                            }
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }

    func offlineUpdateLectureProgress(lecture: Lecture, lastPlayedPoint: Int) {
        // This is to temporarily update the information
        serialLectureWorkerQueue.async { [self] in
            let lectureIndexes = self.allLectures.allIndex(where: { $0.id == lecture.id })
            for index in lectureIndexes {
                self.allLectures[index].lastPlayedPoint = lastPlayedPoint
            }
        }
    }

    func updateLectureInfo(lectures: [Lecture],
                           isCompleted: Bool?,
                           isDownloaded: Bool?,
                           isFavourite: Bool?,
                           lastPlayedPoint: Int?,
                           completion: @escaping (Swift.Result<Bool, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        serialLectureWorkerQueue.async {
            let currentTimestamp = Int(Date().timeIntervalSince1970*1000)

            let collectionReference: CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersLectureInfo(userId: currentUser.uid).path)

            for lecture in lectures {
                var data: [String: Any] = [:]
                data["lastModifiedTimestamp"] = currentTimestamp

                if let isCompleted = isCompleted {  data["isCompleted"] = isCompleted   }
                if let isDownloaded = isDownloaded {  data["isDownloaded"] = isDownloaded   }
                if let isFavourite = isFavourite {  data["isFavourite"] = isFavourite   }
                if let lastPlayedPoint = lastPlayedPoint {
                    if lastPlayedPoint == -1 {
                        data["lastPlayedPoint"] = lecture.length
                    } else {
                        data["lastPlayedPoint"] = lastPlayedPoint
                    }
                }

                let documentReference: DocumentReference

                if let lectureInfo = self.userLectureInfo.first(where: { $0.id == lecture.id }) {
                    documentReference = collectionReference.document(lectureInfo.documentId)
                } else {
                    documentReference = collectionReference.document()
                    data["id"] = lecture.id

                    data["android"] = NSNull()
                    data["ios"] = NSNull()
                    data["documentId"] = documentReference.documentID
                    data["documentPath"] = documentReference.path
                    data["downloadPlace"] = 0
                    data["favouritePlace"] = 0
                    data["privateListIDs"] = NSNull()
                    data["publicListIDs"] = NSNull()
                    data["totalPlayedNo"] = 0
                    data["totalPlayedTime"] = 0
                    data["totallength"] = lecture.length

                    data["isFavourite"] = isFavourite ?? false
                    data["creationTimestamp"] = currentTimestamp
                    data["isCompleted"] = isCompleted ?? false
                    data["isDownloaded"] = isDownloaded ?? false
                    data["isInPrivateList"] = false
                    data["isInPublicList"] = false
                    data["lastPlayedPoint"] = lastPlayedPoint ?? 0
                }

                documentReference.setData(data, merge: true)

                // This is to temporarily update the information
                do {
                    let lectureIndexes = self.allLectures.allIndex(where: { $0.id == lecture.id })
                    for index in lectureIndexes {
                        if let isFavourite = isFavourite {
                            self.allLectures[index].isFavourites = isFavourite
                        }
                        if let lastPlayedPoint = lastPlayedPoint {
                            self.allLectures[index].lastPlayedPoint = lastPlayedPoint
                        }
                    }
                }
            }

            // This is to permanently update the lecture info list
            self.getUsersLectureInfo(source: .default) { _ in }

            DispatchQueue.main.async {
                completion(.success(true))

                NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: nil)
            }
        }
    }
}
