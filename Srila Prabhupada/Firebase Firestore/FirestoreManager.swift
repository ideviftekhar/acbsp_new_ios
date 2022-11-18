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

    func getRawDocuments(query: Query, source: FirestoreSource, completion: @escaping ((Swift.Result<[QueryDocumentSnapshot], Error>) -> Void)) {
        query.spGetRawDocuments(source: source, completion: completion)
    }

    func getDocuments<T: Decodable>(query: Query, source: FirestoreSource, completion: @escaping ((Swift.Result<[T], Error>) -> Void)) {
        query.spGetDocuments(source: source, completion: completion)
    }

    func getDocument<T: Decodable>(documentReference: DocumentReference, source: FirestoreSource, completion: @escaping ((Swift.Result<T, Error>) -> Void)) {
        documentReference.spGetDocument(source: source, completion: completion)
    }

    func getRawDocument(documentReference: DocumentReference, source: FirestoreSource, completion: @escaping ((Swift.Result<DocumentSnapshot, Error>) -> Void)) {
        documentReference.spGetRawDocument(source: source, completion: completion)
    }
}

extension Query {

    fileprivate func spGetRawDocuments(source: FirestoreSource, completion: @escaping ((Swift.Result<[QueryDocumentSnapshot], Error>) -> Void)) {
        getDocuments(completion: { snapshot, error in

            mainThreadSafe {
                if let error = error {
                    completion(.failure(error))
                } else if let documents: [QueryDocumentSnapshot] = snapshot?.documents {
                    completion(.success(documents))
                } else {
                    let error = NSError(domain: "Firestore Database", code: 0, userInfo: [NSLocalizedDescriptionKey: "Documents are not available"])
                    completion(.failure(error))
                }
            }
        })
    }

    fileprivate func spGetDocuments<T: Decodable>(source: FirestoreSource, completion: @escaping ((Swift.Result<[T], Error>) -> Void)) {

        spGetRawDocuments(source: source, completion: { result in
            switch result {
            case .success(let documents):
                DispatchQueue.global().async {
                    do {
                        let objects = try documents.map({ try $0.data(as: T.self) })
                        DispatchQueue.main.async {
                            completion(.success(objects))
                        }
                    } catch let error {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}

extension DocumentReference {

    fileprivate func spGetRawDocument(source: FirestoreSource, completion: @escaping ((Swift.Result<DocumentSnapshot, Error>) -> Void)) {
        getDocument(source: source, completion: { snapshot, error in

            mainThreadSafe {
                if let error = error {
                    completion(.failure(error))
                } else if let document: DocumentSnapshot = snapshot {
                    completion(.success(document))
                } else {
                    let error = NSError(domain: "Firestore Database", code: 0, userInfo: [NSLocalizedDescriptionKey: "Document is not available"])
                    completion(.failure(error))
                }
            }
        })
    }

    fileprivate func spGetDocument<T: Decodable>(source: FirestoreSource, completion: @escaping ((Swift.Result<T, Error>) -> Void)) {
        spGetRawDocument(source: source, completion: { result in
            switch result {
            case .success(let document):

                DispatchQueue.global().async {
                    do {
                        let object = try document.data(as: T.self)
                        DispatchQueue.main.async {
                            completion(.success(object))
                        }
                    } catch let error {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}
