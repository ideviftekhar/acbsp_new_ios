//
//  PlaylistViewModel.swift
//  Srila Prabhupada
//
//  Created by IE on 9/22/22.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

protocol PlaylistViewModel: AnyObject {

    func getPrivatePlaylist(searchText: String?, sortType: PlaylistSortType, completion: @escaping (Swift.Result<[Playlist], Error>) -> Void)
    func getPublicPlaylist(searchText: String?, sortType: PlaylistSortType, completion: @escaping (Swift.Result<[Playlist], Error>) -> Void)
}

class DefaultPlaylistViewModel: NSObject, PlaylistViewModel {

    let firestore: Firestore = {
        let firestore = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        firestore.settings = settings

        return firestore
    }()

    func getPrivatePlaylist(searchText: String?, sortType: PlaylistSortType, completion: @escaping (Swift.Result<[Playlist], Error>) -> Void) {

        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        guard let email = currentUser.email else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "No email associated with user"])
            completion(.failure(error))
            return
        }

        let query = firestore.collectionGroup(email)

        FirestoreManager.shared.getDocuments(query: query, source: .default, completion: { (result: Swift.Result<[Playlist], Error>) in
            switch result {
            case .success(var success):

                if let searchText = searchText, !searchText.isEmpty {
                    let selectedSubtypes: [String] = searchText.split(separator: " ").map { String($0) }
                    success = success.filter { playlist in
                        selectedSubtypes.first(where: { playlist.title.localizedCaseInsensitiveContains($0) }) != nil
                    }
                }

                success = sortType.sort(success)
                completion(.success(success))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func getPublicPlaylist(searchText: String?, sortType: PlaylistSortType, completion: @escaping (Swift.Result<[Playlist], Error>) -> Void) {
        let query: Query = firestore.collection((FirestoreCollection.publicPlaylists.path))

        FirestoreManager.shared.getDocuments(query: query, source: .default, completion: { (result: Swift.Result<[Playlist], Error>) in
            switch result {
            case .success(var success):

                if let searchText = searchText, !searchText.isEmpty {
                    let selectedSubtypes: [String] = searchText.split(separator: " ").map { String($0) }
                    success = success.filter { playlist in
                        selectedSubtypes.first(where: { playlist.title.localizedCaseInsensitiveContains($0) }) != nil
                    }
                }

                success = sortType.sort(success)
                completion(.success(success))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}
