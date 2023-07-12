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

    func getUsersLectureInfo(source: FirestoreSource, progress: ((_ progress: CGFloat) -> Void)?, completion: @escaping (Swift.Result<[LectureInfo], Error>) -> Void) {

        guard FirestoreManager.shared.currentUser != nil,
                let uid = FirestoreManager.shared.currentUserUID else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            mainThreadSafe {
                completion(.failure(error))
            }
            return
        }

        if source == .cache && !self.userLectureInfo.isEmpty {
            parallelLectureWorkerQueue.async {
                DispatchQueue.main.async {
                    completion(.success(self.userLectureInfo))
                }
            }
        } else {
            let query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersLectureInfo(userId: uid).path)

            FirestoreManager.shared.getDocuments(query: query, source: .default, completion: { [self] (result: Swift.Result<[LectureInfo], Error>) in
                switch result {
                case .success(let success):
                    self.userLectureInfo = success

                    serialLectureWorkerQueue.async {
                        if !self.allLectures.isEmpty {
                            self.allLectures = Self.refreshLectureWithLectureInfo(lectures: self.allLectures, lectureInfos: success, downloadedLectures: Persistant.shared.getAllDBLectures(), progress: progress)
                            self.saveAllCachedLectures()
                        }
                        DispatchQueue.main.async {
                            completion(.success(success))
                        }
                    }

                    DispatchQueue.global(qos: .background).async {
                        let crossReference = Dictionary(grouping: success, by: \.id)
                        let duplicates = crossReference.filter { $1.count > 1 }
                        let duplicateIDs: [Int] = duplicates.compactMap { $0.key }.sorted()

                        if !duplicateIDs.isEmpty {
                            self.removeDuplicateLectureInfo(lectureInfoID: duplicateIDs)
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
            var updatedLectures: [Lecture] = []
            var updatedAllLectures = self.allLectures

            if let index = updatedAllLectures.firstIndex(where: { $0.id == lecture.id }) {
                if lastPlayedPoint == -1 {
                    updatedAllLectures[index].lastPlayedPoint = lecture.length
                } else {
                    updatedAllLectures[index].lastPlayedPoint = lastPlayedPoint
                }
                updatedLectures.append(updatedAllLectures[index])
                self.allLectures = updatedAllLectures
            }

            if let index = self.userLectureInfo.firstIndex(where: { $0.id == lecture.id }) {
                if lastPlayedPoint == -1 {
                    self.userLectureInfo[index].lastPlayedPoint = lecture.length
                } else {
                    self.userLectureInfo[index].lastPlayedPoint = lastPlayedPoint
                }
//            } else {  // Due to the documentID issue, we are skipping this.
//                let currentTimestamp = Int(Date().timeIntervalSince1970*1000)
//                let newLectureInfo = LectureInfo(id: lecture.id, creationTimestamp: currentTimestamp, isFavorite: false, lastPlayedPoint: lastPlayedPoint, documentId: /*documentReference.documentID*/)
//                self.userLectureInfo.append(newLectureInfo)
            }

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: updatedLectures)
            }
        }
    }

    func updateLectureInfo(lectures: [Lecture],
                           isCompleted: Bool?,
                           isDownloaded: Bool?,
                           isFavorite: Bool?,
                           lastPlayedPoint: Int?,
                           postUpdate: Bool,
                           completion: @escaping (Swift.Result<Bool, Error>) -> Void) {
        guard FirestoreManager.shared.currentUser != nil,
                let uid = FirestoreManager.shared.currentUserUID else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            mainThreadSafe {
                completion(.failure(error))
            }
            return
        }

        serialLectureWorkerQueue.async {
            let currentTimestamp = Int(Date().timeIntervalSince1970*1000)

            let collectionReference: CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersLectureInfo(userId: uid).path)

            var temporaryUpdatedLectures: [Lecture] = []

            var permanentUpdatedLectures: [Lecture] = []
            var failedLectures: [Lecture] = []
            var lastError: Error?

            let lectureInfoIDHashTable: [Int: Int] = self.userLectureInfo.enumerated().reduce(into: [Int: Int]()) { result, lecture in
                result[lecture.element.id] = lecture.offset
            }

            var updatedAllLectures = self.allLectures
            let lectureIDHashTable: [Int: Int] = updatedAllLectures.enumerated().reduce(into: [Int: Int]()) { result, lecture in
                result[lecture.element.id] = lecture.offset
            }

            for lecture in lectures {
                var data: [String: Any] = [:]
                data["lastModifiedTimestamp"] = currentTimestamp

                if let isCompleted = isCompleted {  data["isCompleted"] = isCompleted   }
                if let isDownloaded = isDownloaded {  data["isDownloaded"] = isDownloaded   }
                if let isFavorite = isFavorite {  data["isFavourite"] = isFavorite   }

                var lastPlayedPoint = lastPlayedPoint

                if let value = lastPlayedPoint {
                    if value == -1 {
                        lastPlayedPoint = lecture.length
                    }
                    data["lastPlayedPoint"] = lastPlayedPoint
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

                    data["isFavourite"] = isFavorite ?? false
                    data["creationTimestamp"] = currentTimestamp
                    data["isCompleted"] = isCompleted ?? false
                    data["isDownloaded"] = isDownloaded ?? false
                    data["isInPrivateList"] = false
                    data["isInPublicList"] = false
                    data["lastPlayedPoint"] = lastPlayedPoint ?? 0
                }

                documentReference.updateDocument(documentData: data, completion: { (result: (Swift.Result<LectureInfo, Error>)) in
                    switch result {
                    case .success:
                        permanentUpdatedLectures.append(lecture)
                    case .failure(let failure):
                        lastError = failure
                        failedLectures.append(lecture)

                        self.serialLectureWorkerQueue.async {
                            // Reverting userLectureInfo
                            if let index = self.userLectureInfo.firstIndex(where: { $0.id == lecture.id }) {
                                self.userLectureInfo[index].isFavorite = lecture.isFavorite
                                self.userLectureInfo[index].lastPlayedPoint = lecture.lastPlayedPoint
                            }
                        }
                    }

                    // Completed
                    if lectures.count >= (failedLectures.count + permanentUpdatedLectures.count) {
                        if let lastError = lastError as? NSError {
                            if lectures.count == 1 {
                                completion(.failure(lastError))
                            } else {
                                var descriptions: [String] = []
                                if permanentUpdatedLectures.count > 0 {
                                    descriptions.append("Updated \(permanentUpdatedLectures.count) lecture(s)")
                                }

                                if permanentUpdatedLectures.count > 0 {
                                    descriptions.append("Unable to update \(permanentUpdatedLectures.count) lecture(s)")
                                }

                                descriptions.append(lastError.localizedDescription)

                                var userInfo = lastError.userInfo
                                userInfo[NSLocalizedDescriptionKey] = descriptions.joined(separator: "\n")
                                let error = NSError(domain: lastError.domain, code: lastError.code, userInfo: userInfo)
                                completion(.failure(error))
                            }

                            if postUpdate {
                                NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: failedLectures)
                            }
                        } else {
                            completion(.success(true))
                        }
                    }
                })

                // This is to temporarily update the information
                do {
                    if let index = lectureInfoIDHashTable[lecture.id] {
                        if let isFavorite = isFavorite {
                            self.userLectureInfo[index].isFavorite = isFavorite
                        }
                        if let lastPlayedPoint = lastPlayedPoint {
                            self.userLectureInfo[index].lastPlayedPoint = lastPlayedPoint
                        }
                    } else {
                        let newLectureInfo = LectureInfo(id: lecture.id, creationTimestamp: currentTimestamp, isFavorite: isFavorite ?? false, lastPlayedPoint: lastPlayedPoint ?? 0, documentId: documentReference.documentID)
                        self.userLectureInfo.append(newLectureInfo)
                    }

                    if let index = lectureIDHashTable[lecture.id] {
                        var isUpdated: Bool = false
                        if let isFavorite = isFavorite {
                            updatedAllLectures[index].isFavorite = isFavorite
                            isUpdated = true
                        }
                        if let lastPlayedPoint = lastPlayedPoint {
                            updatedAllLectures[index].lastPlayedPoint = lastPlayedPoint
                            isUpdated = true
                        }

                        if isUpdated {
                            temporaryUpdatedLectures.append(updatedAllLectures[index])
                        }
                    }
                }
            }

            self.allLectures = updatedAllLectures
            self.saveAllCachedLectures()

            if postUpdate {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: DefaultLectureViewModel.Notification.lectureUpdated, object: temporaryUpdatedLectures)
                }
            }
        }
    }
}

extension DefaultLectureViewModel {
    internal func removeDuplicateLectureInfo(lectureInfoID: [Int]) {

        guard FirestoreManager.shared.currentUser != nil,
                let uid = FirestoreManager.shared.currentUserUID else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            return
        }

        for lectureID in lectureInfoID {
            let query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersLectureInfo(userId: uid).path).whereField("id", isEqualTo: lectureID)

            FirestoreManager.shared.getRawDocuments(query: query, source: .default, completion: { result in
                switch result {
                case .success(var success):

                    // It's a duplicate record
                    if success.count > 1 {
                        //Keeping the first record
                        success.remove(at: 0)

                        for snapshot in success {
                            snapshot.reference.delete()
                        }
                    }
                case .failure:
                    break
                }
            })
        }
    }
}
