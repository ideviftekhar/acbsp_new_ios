//
//  FirestoreManager.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 9/23/22.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirestoreManager: NSObject {

    static let shared = FirestoreManager()

    let firestore: Firestore = {
        let firestore = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        firestore.settings = settings

        return firestore
    }()

    override private init() {
        super.init()
    }

    func getDocuments<T: Decodable>(query: Query, source: FirestoreSource, completion: @escaping ((Swift.Result<[T], Error>) -> Void)) {
        query.getDocuments(source: source, completion: completion)
    }
}

extension Query {

    fileprivate func getDocuments<T: Decodable>(source: FirestoreSource, completion: @escaping ((Swift.Result<[T], Error>) -> Void)) {
        getDocuments(source: source) { snapshot, error in

            if let error = error {
                completion(.failure(error))
           } else if let documents: [QueryDocumentSnapshot] = snapshot?.documents {

               do {
                   let objects = try documents.map({ try $0.data(as: T.self) })
                   completion(.success(objects))
               } catch {
                   print(error)
                   completion(.failure(error))
               }
            }
        }
    }
}
