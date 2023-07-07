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

    static var defaultModel: PlaylistViewModel { get }

    func createPlaylist(title: String, category: String, description: String, listType: PlaylistType, lectures: [Lecture], completion: @escaping (Swift.Result<Playlist, Error>) -> Void)
    func update(playlist: Playlist, title: String, category: String, description: String, completion: @escaping (Swift.Result<Playlist, Error>) -> Void)

    func getPrivatePlaylist(searchText: String?, sortType: PlaylistSortType, completion: @escaping (Swift.Result<[Playlist], Error>) -> Void)
    func getPublicPlaylist(searchText: String?, sortType: PlaylistSortType, userEmail: String?, completion: @escaping (Swift.Result<[Playlist], Error>) -> Void)

    func add(lectures: [Lecture], to playlist: Playlist, completion: @escaping (Swift.Result<Playlist, Error>) -> Void)
    func remove(lectures: [Lecture], from playlist: Playlist, completion: @escaping (Swift.Result<Playlist, Error>) -> Void)
    func delete(playlist: Playlist, completion: @escaping (Swift.Result<Bool, Error>) -> Void)
}

class DefaultPlaylistViewModel: NSObject, PlaylistViewModel {

    static var defaultModel: PlaylistViewModel = DefaultPlaylistViewModel()

    func createPlaylist(title: String, category: String, description: String, listType: PlaylistType, lectures: [Lecture], completion: @escaping (Swift.Result<Playlist, Error>) -> Void) {

        guard FirestoreManager.shared.currentUser != nil,
              let uid = FirestoreManager.shared.currentUserUID,
              let email = FirestoreManager.shared.currentUserEmail else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            mainThreadSafe {
                completion(.failure(error))
            }
            return
        }

        let currentTimestamp = Int(Date().timeIntervalSince1970*1000)
        var newLectureIds: [Int] = lectures.map { $0.id }
        let uniqueIds: Set<Int> = Set(newLectureIds)
        newLectureIds = Array(uniqueIds)

        var data: [String: Any] = [:]
        data["authorEmail"] = email
        data["creationTime"] = currentTimestamp
        data["description"] = description
        data["lastUpdate"] = currentTimestamp
        data["lecturesCategory"] = category
        data["listType"] = listType.rawValue
        data["thumbnail"] = ""
        data["title"] = title
        data["lectureCount"] = newLectureIds.count
        data["lectureIds"] = newLectureIds

        switch listType {
        case .private:
            let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.privatePlaylists.path).document(uid).collection(email)

            let newDocument = collectionReference.document()

            data["docPath"] = newDocument.path
            data["listID"] = newDocument.documentID

            newDocument.updateDocument(documentData: data, completion: completion)

        case .public:
            let publicPlaylistsPath = FirestoreCollection.publicPlaylists.path

            let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(publicPlaylistsPath)

            let newDocument = collectionReference.document()

            data["docPath"] = newDocument.path
            data["listID"] = newDocument.documentID

            newDocument.updateDocument(documentData: data, completion: completion)
        case .unknown:
            break
        }
    }

    func update(playlist: Playlist, title: String, category: String, description: String, completion: @escaping (Swift.Result<Playlist, Error>) -> Void) {

        guard FirestoreManager.shared.currentUser != nil,
              let uid = FirestoreManager.shared.currentUserUID,
              let email = FirestoreManager.shared.currentUserEmail else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            mainThreadSafe {
                completion(.failure(error))
            }
            return
        }

        let currentTimestamp = Int(Date().timeIntervalSince1970*1000)

        var data: [String: Any] = [:]
        data["description"] = description
        data["lastUpdate"] = currentTimestamp
        data["lecturesCategory"] = category
        data["title"] = title

        switch playlist.listType {
        case .private:
            let privatePlaylistsPath = FirestoreCollection.privatePlaylists.path
            let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(privatePlaylistsPath).document(uid).collection(email)
            let existingDocument = collectionReference.document(playlist.listID)

            existingDocument.updateDocument(documentData: data, completion: completion)

        case .public:
            let publicPlaylistsPath = FirestoreCollection.publicPlaylists.path
            let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(publicPlaylistsPath)
            let existingDocument = collectionReference.document(playlist.listID)

            existingDocument.updateDocument(documentData: data, completion: completion)
        case .unknown:
            break
       }
    }

    func getPrivatePlaylist(searchText: String?, sortType: PlaylistSortType, completion: @escaping (Swift.Result<[Playlist], Error>) -> Void) {

        guard FirestoreManager.shared.currentUser != nil,
              let uid = FirestoreManager.shared.currentUserUID,
              let email = FirestoreManager.shared.currentUserEmail else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            mainThreadSafe {
                completion(.failure(error))
            }
            return
        }

        let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.privatePlaylists.path).document(uid).collection(email)

        FirestoreManager.shared.getDocuments(query: collectionReference, source: .default, completion: { (result: Swift.Result<[Playlist], Error>) in
            switch result {
            case .success(var success):

                if let searchText = searchText, !searchText.isEmpty {
                    let selectedSubtypes: [String] = searchText.split(separator: " ").map { String($0) }
                    success = success.filter { playlist in
                        selectedSubtypes.first(where: { playlist.title.localizedStandardContains($0) }) != nil
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
                        selectedSubtypes.first(where: { playlist.title.localizedStandardContains($0) }) != nil
                    }
                }

                success = sortType.sort(success)
                completion(.success(success))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func add(lectures: [Lecture], to playlist: Playlist, completion: @escaping (Swift.Result<Playlist, Error>) -> Void) {
        switch playlist.listType {
        case .private:
            guard FirestoreManager.shared.currentUser != nil,
                  let uid = FirestoreManager.shared.currentUserUID,
                  let email = FirestoreManager.shared.currentUserEmail else {
                let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
                mainThreadSafe {
                    completion(.failure(error))
                }
                return
            }

            let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.privatePlaylists.path).document(uid).collection(email)

            let documentReference = collectionReference.document(playlist.listID)

            FirestoreManager.shared.getRawDocument(documentReference: documentReference, source: .server, completion: { result in
                switch result {

                case .success(let document):

                    var lectureIds: [Int] = (document["lectureIds"] as? [Int]) ?? []
                    var newLectureIds: [Int] = lectures.map { $0.id }
                    let uniqueIds: Set<Int> = Set(newLectureIds)
                    newLectureIds = Array(uniqueIds)

                    let currentTimestamp = Int(Date().timeIntervalSince1970*1000)

                    lectureIds.append(contentsOf: newLectureIds)
                    lectureIds = Array(Set(lectureIds))
                    var data: [String: Any] = [:]
                    data["lectureIds"] = lectureIds
                    data["lectureCount"] = lectureIds.count
                    data["lastUpdate"] = currentTimestamp

                    document.reference.updateDocument(documentData: data, completion: completion)
                case .failure(let error):
                    mainThreadSafe {
                        completion(.failure(error))
                    }
                }
            })

        case .public:
            let publicPlaylistsPath = FirestoreCollection.publicPlaylists.path

            let documentReference: DocumentReference = FirestoreManager.shared.firestore.collection(publicPlaylistsPath).document(playlist.listID)

            FirestoreManager.shared.getDocument(documentReference: documentReference, source: .server, completion: { (result: Swift.Result<Playlist, Error>) in
                switch result {
                case .success(let document):

                    var lectureIds = document.lectureIds
                    var newLectureIds: [Int] = lectures.map { $0.id }
                    let uniqueIds: Set<Int> = Set(newLectureIds)
                    newLectureIds = Array(uniqueIds)

                    let currentTimestamp = Int(Date().timeIntervalSince1970*1000)

                    lectureIds.append(contentsOf: newLectureIds)
                    lectureIds = Array(Set(lectureIds))
                    var data: [String: Any] = [:]
                    data["lectureIds"] = lectureIds
                    data["lectureCount"] = lectureIds.count
                    data["lastUpdate"] = currentTimestamp

                    documentReference.updateDocument(documentData: data, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        case .unknown:
            break
        }
    }

    func remove(lectures: [Lecture], from playlist: Playlist, completion: @escaping (Swift.Result<Playlist, Error>) -> Void) {
        switch playlist.listType {
        case .private:
            guard FirestoreManager.shared.currentUser != nil,
                  let uid = FirestoreManager.shared.currentUserUID,
                  let email = FirestoreManager.shared.currentUserEmail else {
                let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
                mainThreadSafe {
                    completion(.failure(error))
                }
                return
            }

            let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.privatePlaylists.path).document(uid).collection(email)

            let documentReference = collectionReference.document(playlist.listID)

            FirestoreManager.shared.getRawDocument(documentReference: documentReference, source: .server, completion: { result in
                switch result {

                case .success(let document):

                    var lectureIds: [Int] = (document["lectureIds"] as? [Int]) ?? []
                    let oldLectureIds: [Int] = lectures.map { $0.id }

                    let currentTimestamp = Int(Date().timeIntervalSince1970*1000)

                    lectureIds.removeAll { oldLectureIds.contains($0) }
                    lectureIds = Array(Set(lectureIds))
                    var data: [String: Any] = [:]
                    data["lectureIds"] = lectureIds
                    data["lectureCount"] = lectureIds.count
                    data["lastUpdate"] = currentTimestamp

                    document.reference.updateDocument(documentData: data, completion: completion)
                case .failure(let error):
                    mainThreadSafe {
                        completion(.failure(error))
                    }
                }
            })

        case .public:
            let publicPlaylistsPath = FirestoreCollection.publicPlaylists.path

            let documentReference: DocumentReference = FirestoreManager.shared.firestore.collection(publicPlaylistsPath).document(playlist.listID)

            FirestoreManager.shared.getDocument(documentReference: documentReference, source: .server, completion: { (result: Swift.Result<Playlist, Error>) in
                switch result {
                case .success(let document):

                    var lectureIds = document.lectureIds
                    let oldLectureIds: [Int] = lectures.map { $0.id }

                    let currentTimestamp = Int(Date().timeIntervalSince1970*1000)

                    lectureIds.removeAll { oldLectureIds.contains($0) }
                    lectureIds = Array(Set(lectureIds))
                    var data: [String: Any] = [:]
                    data["lectureIds"] = lectureIds
                    data["lectureCount"] = lectureIds.count
                    data["lastUpdate"] = currentTimestamp

                    documentReference.updateDocument(documentData: data, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        case .unknown:
            break
        }
    }

    func delete(playlist: Playlist, completion: @escaping (Swift.Result<Bool, Error>) -> Void) {
        switch playlist.listType {
        case .private:
            guard FirestoreManager.shared.currentUser != nil,
                  let uid = FirestoreManager.shared.currentUserUID,
                  let email = FirestoreManager.shared.currentUserEmail else {
                let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
                mainThreadSafe {
                    completion(.failure(error))
                }
                return
            }

            let collectionReference: FirebaseFirestore.CollectionReference = FirestoreManager.shared.firestore.collection(FirestoreCollection.privatePlaylists.path).document(uid).collection(email)
            let documentReference = collectionReference.document(playlist.listID)
            documentReference.delete(completion: { error in
                mainThreadSafe {
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(true))
                    }
                }
            })
        case .public:
            let publicPlaylistsPath = FirestoreCollection.publicPlaylists.path
            let documentReference: DocumentReference = FirestoreManager.shared.firestore.collection(publicPlaylistsPath).document(playlist.listID)

            documentReference.delete(completion: { error in
                mainThreadSafe {
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(true))
                    }
                }
            })
        case .unknown:
            break
        }
    }
}
