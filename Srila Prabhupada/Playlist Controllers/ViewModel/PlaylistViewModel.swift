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

    func getPrivatePlaylist(searchText: String?, sortyType: SortType, filter: [Filter: [String]], completion: @escaping (Swift.Result<[Playlist], Error>) -> Void)
    func getPublicPlaylist(searchText: String?, sortyType: SortType, filter: [Filter: [String]], completion: @escaping (Swift.Result<[Playlist], Error>) -> Void)
}

class DefaultPlaylistViewModel: NSObject, PlaylistViewModel {

    let firestore: Firestore = {
        let firestore = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        firestore.settings = settings

        return firestore
    }()

    func getPrivatePlaylist(searchText: String?, sortyType: SortType, filter: [Filter: [String]], completion: @escaping (Swift.Result<[Playlist], Error>) -> Void) {

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

        var query = firestore.collectionGroup(email)

        if let searchText = searchText, !searchText.isEmpty {
            query = query.whereField("title", arrayContains: searchText)
        }

        for (filter, subtypes) in filter {
            query = filter.applyOn(query: query, selectedSubtypes: subtypes)
        }

        query = sortyType.applyOn(query: query)

        query.getDocuments { snapshot, error in

            if let error = error {
                completion(.failure(error))
            } else if let documents: [QueryDocumentSnapshot] = snapshot?.documents {

                do {
                    let remotePlaylist = try documents.map({ try $0.data(as: Playlist.self) })
                    completion(.success(remotePlaylist))
                } catch {
                    print(error)
                    completion(.failure(error))
                }
            }
        }
    }

    func getPublicPlaylist(searchText: String?, sortyType: SortType, filter: [Filter: [String]], completion: @escaping (Swift.Result<[Playlist], Error>) -> Void) {
        var query: Query = firestore.collection("PublicPlaylists")

        if let searchText = searchText, !searchText.isEmpty {
            query = query.whereField("title", arrayContains: searchText)
        }

        for (filter, subtypes) in filter {
            query = filter.applyOn(query: query, selectedSubtypes: subtypes)
        }

        query = sortyType.applyOn(query: query)

        query.getDocuments { snapshot, error in

            if let error = error {
                completion(.failure(error))
            } else if let documents: [QueryDocumentSnapshot] = snapshot?.documents {

                do {
                    let remotePlaylist = try documents.map({ try $0.data(as: Playlist.self) })
                    completion(.success(remotePlaylist))
                } catch {
                    print(error)
                    completion(.failure(error))
                }
            }
        }
    }
}
