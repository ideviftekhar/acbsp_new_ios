//
//  LectureViewModel+RecentlyPlayed.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 11/19/22.
//

import Foundation
import FirebaseFirestore

extension DefaultLectureViewModel {

    func getRecentlyPlayedLectureIDs(source: FirestoreSource, completion: @escaping (Swift.Result<RecentPlayID, Error>) -> Void) {

        guard FirestoreManager.shared.currentUser != nil,
              let uid = FirestoreManager.shared.currentUserUID else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            mainThreadSafe {
                completion(.failure(error))
            }
            return
        }

        let collectionReference: CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.users.path)

        let documentReference = collectionReference.document(uid)

        FirestoreManager.shared.getDocument(documentReference: documentReference, source: .server, completion: completion)
    }

    func addToRecentlyPlayed(lecture: Lecture, completion: @escaping (Swift.Result<RecentPlayID, Error>) -> Void) {

        guard FirestoreManager.shared.currentUser != nil,
                let uid = FirestoreManager.shared.currentUserUID else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            mainThreadSafe {
                completion(.failure(error))
            }
            return
        }

        let collectionReference: CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.users.path)

        let documentReference = collectionReference.document(uid)

        FirestoreManager.shared.getRawDocument(documentReference: documentReference, source: .server, completion: { result in
            switch result {
            case .success(let success):

                var data: [String: Any] = [:]

                if success.data() == nil {
                    data["recentPlayIDs"] = [lecture.id]
                } else {
                    data["recentPlayIDs"] = FieldValue.arrayUnion([lecture.id])
                }

                success.reference.updateDocument(documentData: data, completion: completion)
            case .failure(let error):
                mainThreadSafe {
                    completion(.failure(error))
                }
            }
        })
    }

    func removeFromRecentlyPlayed(lecture: Lecture, completion: @escaping (Swift.Result<RecentPlayID, Error>) -> Void) {

        guard FirestoreManager.shared.currentUser != nil,
                let uid = FirestoreManager.shared.currentUserUID else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            mainThreadSafe {
                completion(.failure(error))
            }
            return
        }

        let collectionReference: CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.users.path)

        let documentReference = collectionReference.document(uid)

        FirestoreManager.shared.getRawDocument(documentReference: documentReference, source: .server, completion: { result in
            switch result {
            case .success(let success):

                var data: [String: Any] = [:]

                if success.data() == nil {
                    data["recentPlayIDs"] = [lecture.id]
                } else {
                    data["recentPlayIDs"] = FieldValue.arrayRemove([lecture.id])
                }

                success.reference.updateDocument(documentData: data, completion: completion)
            case .failure(let error):
                mainThreadSafe {
                    completion(.failure(error))
                }
            }
        })
    }
}
