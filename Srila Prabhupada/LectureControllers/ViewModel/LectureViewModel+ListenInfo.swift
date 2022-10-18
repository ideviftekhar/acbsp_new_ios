//
//  ListenInfoViewModel.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/13/22.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreSwift

extension DefaultLectureViewModel {

    func getUsersListenInfo(source: FirestoreSource, completion: @escaping (Swift.Result<[ListenInfo], Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        let query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersListenInfo(userId: currentUser.uid).path)

        FirestoreManager.shared.getDocuments(query: query, source: source, completion: { (result: Swift.Result<[ListenInfo], Error>) in
            switch result {
            case .success(let success):
                completion(.success(success))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func updateListenInfo(day: Int, month: Int, year: Int, lecture: Lecture, completion: @escaping (Swift.Result<ListenInfo, Error>) -> Void) {

        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        let collectionReference: CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersListenInfo(userId: currentUser.uid).path)

        let documentID = "\(day)-\(month)-\(year)"
        let documentReference = collectionReference.document(documentID)

        let countBG: Int = !lecture.search.simple.filter { $0.hasPrefix("BG")}.isEmpty ? 1 : 0
        let countCC: Int = !lecture.search.simple.filter { $0.hasPrefix("CC")}.isEmpty ? 1 : 0
        let countSB: Int = !lecture.search.simple.filter { $0.hasPrefix("SB")}.isEmpty ? 1 : 0
        let countSeminars: Int = !lecture.search.simple.filter { $0.hasPrefix("Seminars")}.isEmpty ? 1 : 0
        let countVSN: Int = !lecture.search.simple.filter { $0.hasPrefix("VSN")}.isEmpty ? 1 : 0
        let countOther: Int = (countBG == 0 && countCC == 0 && countSB == 0 && countSeminars == 0 && countVSN == 0) ? 1 : 0

        FirestoreManager.shared.getRawDocument(documentReference: documentReference, source: .server, completion: { result in
            switch result {
            case .success(let success):

                let currentTimestamp = Int(Date().timeIntervalSince1970*1000)
                let data: [String: Any] = [
                    "lastModifiedTimestamp": currentTimestamp,
                    "playedBy": FieldValue.arrayUnion([currentUser.uid]),
                    "playedIds": FieldValue.arrayUnion([lecture.id]),
                    "listenDetails.BG": FieldValue.increment(Int64(countBG)),
                    "listenDetails.CC": FieldValue.increment(Int64(countCC)),
                    "listenDetails.SB": FieldValue.increment(Int64(countSB)),
                    "listenDetails.Seminars": FieldValue.increment(Int64(countSeminars)),
                    "listenDetails.VSN": FieldValue.increment(Int64(countVSN)),
                    "listenDetails.others": FieldValue.increment(Int64(countOther))
                ]

                success.reference.updateData(data, completion: { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        FirestoreManager.shared.getDocument(documentReference: documentReference, source: .default, completion: completion)
                    }
                })
            case .failure(let error):

                let listenDetails: [String: Int] = ["BG": countBG,
                                                    "CC": countCC,
                                                    "SB": countSB,
                                                    "Seminars": countSeminars,
                                                    "VSN": countVSN,
                                                    "others": countOther]

                let currentTimestamp = Int(Date().timeIntervalSince1970*1000)
                let data: [String: Any] = [
                    "creationTimestamp": currentTimestamp,
                    "date": FieldValue.serverTimestamp(),
                    "dateOfRecord": ["day": day, "month": month, "year": year],
                    "documentId": documentID,
                    "documentPath": documentReference.path,
                    "lastModifiedTimestamp": currentTimestamp,
                    "listenDetails": listenDetails,
                    "playedIds": [lecture.id],
                    "audioListen": 0,
                    "videoListen": 0
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
