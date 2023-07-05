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

                let keyUserDefaults = CommonConstants.keyTimestamp
                let oldTimestamp: Date = (UserDefaults.standard.object(forKey: keyUserDefaults) as? Date) ?? Date(timeIntervalSince1970: 0)

                if oldTimestamp != newTimestamp {
                    self.startSyncing()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        })
    }

    private func timestampUpdated(completion: @escaping (Swift.Result<Date, Error>) -> Void) {

        let metadataPath = FirestoreCollection.metadata.path
        let documentReference: DocumentReference = FirestoreManager.shared.firestore.collection(metadataPath).document(CommonConstants.metadataTimestampDocumentID)

        documentReference.addSnapshotListener { snapshot, error in

            if let error = error {
                completion(.failure(error))
            } else {
                guard let attributes = snapshot?.data(),
                let timestampValue = attributes[CommonConstants.keyTimestamp] else { return }
                let newTimestamp = (timestampValue as AnyObject).dateValue()
                completion(.success(newTimestamp))
            }
        }
    }
}
