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

    func createPlaylist(title: String, category: String, description: String, listType: PlaylistType, lectures: [Lecture], completion: @escaping (Swift.Result<Playlist, Error>) -> Void)
    func update(playlist: Playlist, title: String, category: String, description: String, completion: @escaping (Swift.Result<Playlist, Error>) -> Void)

    func getPrivatePlaylist(searchText: String?, sortType: PlaylistSortType, completion: @escaping (Swift.Result<[Playlist], Error>) -> Void)
    func getPublicPlaylist(searchText: String?, sortType: PlaylistSortType, userEmail: String?, completion: @escaping (Swift.Result<[Playlist], Error>) -> Void)

    func add(lectures: [Lecture], to playlist: Playlist, completion: @escaping (Swift.Result<[Int], Error>) -> Void)
    func delete(playlist: Playlist, completion: @escaping (Swift.Result<Bool, Error>) -> Void)
}

class DefaultPlaylistViewModel: NSObject, PlaylistViewModel {

    func createPlaylist(title: String, category: String, description: String, listType: PlaylistType, lectures: [Lecture], completion: @escaping (Swift.Result<Playlist, Error>) -> Void) {

        guard let currentUser = Auth.auth().currentUser, let email = currentUser.email else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        let currentTimestamp = Int(Date().timeIntervalSince1970*1000)
        let newLectureIds: [Int] = lectures.map { $0.id }

        var document: [String: Any] = [:]
        document["authorEmail"] = email
        document["creationTime"] = currentTimestamp
        document["description"] = description
        document["lastUpdate"] = currentTimestamp
        document["lecturesCategory"] = category
        document["listType"] = listType.rawValue
        document["thumbnail"] = ""
        document["title"] = title
        document["lectureCount"] = newLectureIds.count
        document["lectureIds"] = newLectureIds

        switch listType {
        case .private:
            let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.privatePlaylists.path).document(currentUser.uid).collection(email)

            let newDocument = collectionReference.document()

            document["docPath"] = "PublicPlaylists/\(newDocument.documentID)"
            document["listID"] = newDocument.documentID

            newDocument.setData(document, completion: { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    FirestoreManager.shared.getDocument(documentReference: newDocument, source: .default, completion: completion)
                }
            })

        case .public:
            let publicPlaylistsPath = FirestoreCollection.publicPlaylists.path

            let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(publicPlaylistsPath)

            let newDocument = collectionReference.document()

            document["docPath"] = "PublicPlaylists/\(newDocument.documentID)"
            document["listID"] = newDocument.documentID

            newDocument.setData(document, completion: { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    FirestoreManager.shared.getDocument(documentReference: newDocument, source: .default, completion: completion)
                }
            })
        }
    }

    func update(playlist: Playlist, title: String, category: String, description: String, completion: @escaping (Swift.Result<Playlist, Error>) -> Void) {

        guard let currentUser = Auth.auth().currentUser, let email = currentUser.email else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        let currentTimestamp = Int(Date().timeIntervalSince1970*1000)

        var document: [String: Any] = [:]
        document["description"] = description
        document["lastUpdate"] = currentTimestamp
        document["lecturesCategory"] = category
        document["title"] = title

        switch playlist.listType {
        case .private:
            let privatePlaylistsPath = FirestoreCollection.privatePlaylists.path
            let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(privatePlaylistsPath).document(currentUser.uid).collection(email)
            let existingDocument = collectionReference.document(playlist.listID)

            existingDocument.setData(document, merge: true, completion: { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    FirestoreManager.shared.getDocument(documentReference: existingDocument, source: .default, completion: completion)
                }
            })

        case .public:
            let publicPlaylistsPath = FirestoreCollection.publicPlaylists.path
            let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(publicPlaylistsPath)
            let existingDocument = collectionReference.document(playlist.listID)

            existingDocument.setData(document, completion: { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    FirestoreManager.shared.getDocument(documentReference: existingDocument, source: .default, completion: completion)
                }
            })
        }
    }

    func getPrivatePlaylist(searchText: String?, sortType: PlaylistSortType, completion: @escaping (Swift.Result<[Playlist], Error>) -> Void) {

        guard let currentUser = Auth.auth().currentUser, let email = currentUser.email else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            completion(.failure(error))
            return
        }

        let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.privatePlaylists.path).document(currentUser.uid).collection(email)

        FirestoreManager.shared.getDocuments(query: collectionReference, source: .default, completion: { (result: Swift.Result<[Playlist], Error>) in
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

    func getPublicPlaylist(searchText: String?, sortType: PlaylistSortType, userEmail: String?, completion: @escaping (Swift.Result<[Playlist], Error>) -> Void) {
        var query: Query = FirestoreManager.shared.firestore.collection((FirestoreCollection.publicPlaylists.path))

        if let userEmail = userEmail {
            query = query.whereField("authorEmail", isEqualTo: userEmail)
        }

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

    func add(lectures: [Lecture], to playlist: Playlist, completion: @escaping (Swift.Result<[Int], Error>) -> Void) {
        switch playlist.listType {
        case .private:
            guard let currentUser = Auth.auth().currentUser, let email = currentUser.email else {
                let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
                completion(.failure(error))
                return
            }

            let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.privatePlaylists.path).document(currentUser.uid).collection(email)

            let documentReference = collectionReference.document(playlist.listID)

            FirestoreManager.shared.getRawDocument(documentReference: documentReference, source: .server, completion: { result in
                switch result {

                case .success(let document):

                    var lectureIds: [Int] = (document["lectureIds"] as? [Int]) ?? []
                    let newLectureIds: [Int] = lectures.map { $0.id }
                    lectureIds.append(contentsOf: newLectureIds)
                    lectureIds = Array(Set(lectureIds))
                    let data: [String: Any] = ["lectureIds": lectureIds, "lectureCount": lectureIds.count]

                    document.reference.setData(data, merge: true) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(lectureIds))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            })

        case .public:
            let publicPlaylistsPath = FirestoreCollection.publicPlaylists.path

            let documentReference: DocumentReference = FirestoreManager.shared.firestore.collection(publicPlaylistsPath).document(playlist.listID)

            FirestoreManager.shared.getDocument(documentReference: documentReference, source: .server) { (result: Swift.Result<Playlist, Error>) in
                switch result {
                case .success(let document):

                    var lectureIds = document.lectureIds
                    let newLectureIds: [Int] = lectures.map { $0.id }
                    lectureIds.append(contentsOf: newLectureIds)
                    lectureIds = Array(Set(lectureIds))
                    let data: [String: Any] = ["lectureIds": lectureIds, "lectureCount": lectureIds.count]
                    documentReference.setData(data, merge: true) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(lectureIds))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    func delete(playlist: Playlist, completion: @escaping (Swift.Result<Bool, Error>) -> Void) {
        switch playlist.listType {
        case .private:
            guard let currentUser = Auth.auth().currentUser, let email = currentUser.email else {
                let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
                completion(.failure(error))
                return
            }

            let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.privatePlaylists.path).document(currentUser.uid).collection(email)
            let documentReference = collectionReference.document(playlist.listID)
            documentReference.delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(true))
                }
            }
        case .public:
            let publicPlaylistsPath = FirestoreCollection.publicPlaylists.path
            let documentReference: DocumentReference = FirestoreManager.shared.firestore.collection(publicPlaylistsPath).document(playlist.listID)

            documentReference.delete() { error in

                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(true))
                }
            }
        }
    }
}
