//
//  TabBarController+TimestampObserver.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 7/4/23.
//

import UIKit
import FirebaseFirestore

extension TabBarController {

    internal func addTimestampObserver() {
        timestampUpdated(completion: { result in
            switch result {

            case .success(let newTimestamp):

                let keyUserDefaults = CommonConstants.lastSyncTimestamp
                let oldTimestamp: Date = (UserDefaults.standard.object(forKey: keyUserDefaults) as? Date) ?? Date(timeIntervalSince1970: 0)

                if oldTimestamp != newTimestamp.timestamp {
                    self.startSyncing(force: true)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        })
    }

    private func timestampUpdated(completion: @escaping (Swift.Result<LastSyncTimestamp, Error>) -> Void) {

        let metadataPath = FirestoreCollection.metadata.path
        let documentReference: DocumentReference = FirestoreManager.shared.firestore.collection(metadataPath).document(CommonConstants.lastSyncTimestamp)

        documentReference.addSnapshotListener { snapshot, error in

            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                do {
                    let object = try snapshot.data(as: LastSyncTimestamp.self)
                    DispatchQueue.main.async {
                        completion(.success(object))
                    }
                } catch let error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
}
