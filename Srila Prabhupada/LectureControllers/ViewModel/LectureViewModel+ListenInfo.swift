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
            mainThreadSafe {
                completion(.failure(error))
            }
            return
        }

        let query: Query = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersListenInfo(userId: currentUser.uid).path)
        query.order(by: "creationTimestamp", descending: true)

        FirestoreManager.shared.getDocuments(query: query, source: source, completion: { (result: Swift.Result<[ListenInfo], Error>) in
            switch result {
            case .success(let success):
                completion(.success(success))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func updateListenInfo(date: Date, addListenSeconds seconds: Int, lecture: Lecture, completion: @escaping (Swift.Result<ListenInfo, Error>) -> Void) {

        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            mainThreadSafe {
                completion(.failure(error))
            }
            return
        }

        let collectionReference: CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.usersListenInfo(userId: currentUser.uid).path)

        let documentID = DateFormatter.d_M_yyyy.string(from: date)
        let documentReference = collectionReference.document(documentID)

        let countBG: Int = !lecture.search.simple.filter { $0.hasPrefix("BG")}.isEmpty ? seconds : 0
        let countCC: Int = !lecture.search.simple.filter { $0.hasPrefix("CC")}.isEmpty ? seconds : 0
        let countSB: Int = !lecture.search.simple.filter { $0.hasPrefix("SB")}.isEmpty ? seconds : 0
        let countSeminars: Int = !lecture.search.simple.filter { $0.hasPrefix("Seminars")}.isEmpty ? seconds : 0
        let countVSN: Int = !lecture.search.simple.filter { $0.hasPrefix("VSN")}.isEmpty ? seconds : 0
        let countOther: Int = (countBG == 0 && countCC == 0 && countSB == 0 && countSeminars == 0 && countVSN == 0) ? seconds : 0

        FirestoreManager.shared.getRawDocument(documentReference: documentReference, source: .server, completion: { result in
            switch result {
            case .success(let success):

                let currentTimestamp = Int(Date().timeIntervalSince1970*1000)

                var data: [String: Any] = [:]
                data["lastModifiedTimestamp"] = currentTimestamp

                if success.data() == nil {

                    let components = date.components(.day, .month, .year)

                    let listenDetails: [String: Int] = ["BG": countBG,
                                                        "CC": countCC,
                                                        "SB": countSB,
                                                        "Seminars": countSeminars,
                                                        "VSN": countVSN,
                                                        "others": countOther]

                    data["creationTimestamp"] = currentTimestamp
                    data["date"] = FieldValue.serverTimestamp()
                    data["dateOfRecord"] = ["day": components.day ?? 1, "month": components.month ?? 1, "year": components.year ?? 1970]
                    data["documentId"] = documentID
                    data["documentPath"] = documentReference.path
                    data["listenDetails"] = listenDetails
                    data["playedIds"] = [lecture.id]
                    data["audioListen"] = seconds
                    data["videoListen"] = 0
                } else {
                    data["audioListen"] = FieldValue.increment(Int64(seconds))
                    data["playedBy"] = FieldValue.arrayUnion([currentUser.uid])
                    data["playedIds"] = FieldValue.arrayUnion([lecture.id])

                    let listenDetails: [String: Any] = ["BG": FieldValue.increment(Int64(countBG)),
                                                        "CC": FieldValue.increment(Int64(countCC)),
                                                        "SB": FieldValue.increment(Int64(countSB)),
                                                        "Seminars": FieldValue.increment(Int64(countSeminars)),
                                                        "VSN": FieldValue.increment(Int64(countVSN)),
                                                        "others": FieldValue.increment(Int64(countOther))]
                    data["listenDetails"] = listenDetails
                }

                success.reference.setData(data, merge: true, completion: { error in
                    mainThreadSafe {
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            FirestoreManager.shared.getDocument(documentReference: documentReference, source: .default, completion: completion)
                        }
                    }
                })
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}
