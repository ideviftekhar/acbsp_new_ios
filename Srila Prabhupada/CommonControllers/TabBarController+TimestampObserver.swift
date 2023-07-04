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
                    self.reloadLectures(newTimestamp: newTimestamp, firestoreSource: .server)
                } else {
                    print("No new lectures")
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

    private func reloadLectures(newTimestamp: Date, firestoreSource: FirestoreSource) {
        DefaultLectureViewModel.defaultModel.getLectures(searchText: nil, sortType: .default, filter: [:], lectureIDs: nil, source: firestoreSource, progress: { _ in }, completion: { [self] result in

            switch result {
            case .success(let lectures):
                UserDefaults.standard.set(newTimestamp, forKey: CommonConstants.keyTimestamp)
                UserDefaults.standard.synchronize()

                self.reloadAllControllers()
            case .failure(let error):
                Haptic.error()

                let okButton: ButtonConfig = (title: "OK", handler: nil)

                showAlert(title: "Error!", message: error.localizedDescription, cancel: ("Retry", { [self] in
                    self.reloadLectures(newTimestamp: newTimestamp, firestoreSource: firestoreSource)
                }), buttons: [okButton])
            }
        })
    }
}
